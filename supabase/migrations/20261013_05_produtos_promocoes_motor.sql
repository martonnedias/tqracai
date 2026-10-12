-- TQR Açaí · Etapa 5 · produtos, promoções e motor de preço no servidor
-- Rodar depois da 04. O total do pedido passa a ser calculado só aqui (função app_private.motor_pedido).
-- As regras antigas (combo 3 e 5 ou mais) viram promoções cadastradas; o painel passa a editá-las.

-- ===== Colunas novas em pedidos e itens =====
alter table public.pedidos
  add column modalidade text not null default 'entrega_app' check (modalidade in ('retirada','entrega_bairro','entrega_app')),
  add column bairro_id uuid references public.bairros_entrega(id) on delete set null,
  add column subtotal numeric(10,2),
  add column desconto numeric(10,2) not null default 0 check (desconto >= 0),
  add column taxa_entrega numeric(10,2) not null default 0 check (taxa_entrega >= 0),
  add column promocao_id uuid,
  add column cupom text;
update public.pedidos set subtotal = total where subtotal is null;
alter table public.itens_pedido
  add column preco_unitario numeric(10,2),
  add column nome_produto text,
  add column brinde boolean not null default false;
update public.itens_pedido i set nome_produto = p.nome, preco_unitario = round(i.subtotal / i.quantidade, 2)
  from public.produtos p where p.id = i.produto_id and i.nome_produto is null;

-- ===== Promoções =====
create table public.promocoes (
  id uuid primary key default gen_random_uuid(),
  nome text not null check (length(trim(nome)) >= 2),
  tipo text not null check (tipo in ('combo','faixa_quantidade','leve_pague','casadinha','desconto_percentual','desconto_valor','frete_gratis','brinde')),
  regra jsonb not null default '{}'::jsonb,
  ativo boolean not null default true,
  -- condições comuns a todos os tipos
  min_qtd int check (min_qtd >= 1),
  min_valor numeric(10,2) check (min_valor >= 0),
  primeira_compra boolean not null default false,
  formas_pagamento text[],
  codigo text check (codigo ~ '^[A-Za-z0-9_-]{3,30}$'),   -- preenchido = cupom (só vale se o cliente digitar)
  inicio timestamptz,
  fim timestamptz,
  dias_semana int[] check (dias_semana <@ array[0,1,2,3,4,5,6]),  -- 0 = domingo
  hora_ini time,
  hora_fim time,
  limite_usos int check (limite_usos >= 1),
  usos int not null default 0,
  prioridade int not null default 0,
  frete_gratis boolean not null default false,   -- além do desconto do tipo, zera a taxa de entrega
  acumula boolean not null default false,        -- reservado: nesta versão vale só uma promoção por pedido
  -- vitrine do site
  publica boolean not null default false,
  titulo text,
  qtd_label text,
  rotulo text,
  notas text[] not null default '{}',
  imagem_url text,
  cta text,
  qtd_sugerida int check (qtd_sugerida >= 1),
  destaque boolean not null default false,
  ordem_site int not null default 0,
  criado_em timestamptz not null default now(),
  check (fim is null or inicio is null or fim > inicio)
);
create unique index promocoes_codigo_uk on public.promocoes (lower(codigo)) where codigo is not null;
alter table public.pedidos add constraint pedidos_promocao_fk foreign key (promocao_id) references public.promocoes(id) on delete set null;

create function app_private.validar_promocao() returns trigger
language plpgsql set search_path = '' as $$
declare r jsonb := new.regra; it jsonb;
begin
  if jsonb_typeof(r) <> 'object' then raise exception 'regra_invalida' using errcode = '22023'; end if;
  case new.tipo
    when 'combo' then
      if jsonb_typeof(r->'itens') <> 'array' or jsonb_array_length(r->'itens') = 0
         or (r->>'preco') is null or (r->>'preco')::numeric < 0 then
        raise exception 'regra_invalida:combo' using errcode = '22023'; end if;
      for it in select * from jsonb_array_elements(r->'itens') loop
        if (it->>'qtd') is null or (it->>'qtd')::int < 1
           or not exists (select 1 from public.produtos where id = (it->>'produto_id')::uuid) then
          raise exception 'regra_invalida:combo' using errcode = '22023'; end if;
      end loop;
    when 'faixa_quantidade' then
      if (r->>'min') is null or (r->>'min')::int < 2 or (r->>'preco_unit') is null or (r->>'preco_unit')::numeric < 0
         or not exists (select 1 from public.produtos where id = (r->>'produto_id')::uuid) then
        raise exception 'regra_invalida:faixa_quantidade' using errcode = '22023'; end if;
    when 'leve_pague' then
      if (r->>'leve') is null or (r->>'pague') is null or (r->>'leve')::int < 2 or (r->>'pague')::int < 1
         or (r->>'pague')::int >= (r->>'leve')::int
         or (r ? 'produto_id' and not exists (select 1 from public.produtos where id = (r->>'produto_id')::uuid)) then
        raise exception 'regra_invalida:leve_pague' using errcode = '22023'; end if;
    when 'casadinha' then
      if (r->>'se_qtd') is null or (r->>'entao_qtd') is null or (r->>'se_qtd')::int < 1 or (r->>'entao_qtd')::int < 1
         or (r->>'desconto_percentual') is null or (r->>'desconto_percentual')::numeric not between 1 and 100
         or not exists (select 1 from public.produtos where id = (r->>'se_produto_id')::uuid)
         or not exists (select 1 from public.produtos where id = (r->>'entao_produto_id')::uuid) then
        raise exception 'regra_invalida:casadinha' using errcode = '22023'; end if;
    when 'desconto_percentual' then
      if (r->>'percentual') is null or (r->>'percentual')::numeric not between 1 and 100
         or (r ? 'produto_id' and not exists (select 1 from public.produtos where id = (r->>'produto_id')::uuid)) then
        raise exception 'regra_invalida:desconto_percentual' using errcode = '22023'; end if;
    when 'desconto_valor' then
      if (r->>'valor') is null or (r->>'valor')::numeric <= 0 then
        raise exception 'regra_invalida:desconto_valor' using errcode = '22023'; end if;
    when 'frete_gratis' then
      null;
    when 'brinde' then
      if (r->>'qtd') is null or (r->>'qtd')::int < 1
         or not exists (select 1 from public.produtos where id = (r->>'produto_id')::uuid)
         or (new.min_qtd is null and new.min_valor is null) then
        raise exception 'regra_invalida:brinde' using errcode = '22023'; end if;
  end case;
  if new.codigo is not null and new.publica then
    raise exception 'cupom_nao_pode_ser_publico' using errcode = '22023';
  end if;
  return new;
exception when invalid_text_representation or numeric_value_out_of_range or datatype_mismatch then
  raise exception 'regra_invalida:%', new.tipo using errcode = '22023';
end $$;
create trigger promocoes_valida before insert or update on public.promocoes
  for each row execute function app_private.validar_promocao();

-- ===== Auxiliares do motor =====
create function app_private.qtd_produto(linhas jsonb, pid uuid) returns int
language sql immutable set search_path = '' as $$
  select coalesce(sum((l->>'quantidade')::int), 0)::int from jsonb_array_elements(linhas) l where l->>'produto_id' = pid::text
$$;
create function app_private.preco_produto(linhas jsonb, pid uuid) returns numeric
language sql immutable set search_path = '' as $$
  select (l->>'preco')::numeric from jsonb_array_elements(linhas) l where l->>'produto_id' = pid::text limit 1
$$;

-- desconto (em R$) de uma promoção sobre as linhas do carrinho; brinde e frete grátis não geram desconto aqui
create function app_private.desconto_promocao(pr public.promocoes, linhas jsonb, subtotal numeric) returns numeric
language plpgsql stable security definer set search_path = '' as $$
declare r jsonb := pr.regra; d numeric := 0; sets int; q int; q2 int; it jsonb; preco numeric; l jsonb; unid int;
begin
  case pr.tipo
    when 'combo' then
      sets := null;
      for it in select * from jsonb_array_elements(r->'itens') loop
        q := app_private.qtd_produto(linhas, (it->>'produto_id')::uuid) / (it->>'qtd')::int;
        sets := least(coalesce(sets, q), q);
      end loop;
      if coalesce(sets, 0) > 0 then
        select coalesce(sum((it2->>'qtd')::int * (select p.preco from public.produtos p where p.id = (it2->>'produto_id')::uuid)), 0)
          into d from jsonb_array_elements(r->'itens') it2;
        d := sets * (d - (r->>'preco')::numeric);
      end if;
    when 'faixa_quantidade' then
      q := app_private.qtd_produto(linhas, (r->>'produto_id')::uuid);
      preco := app_private.preco_produto(linhas, (r->>'produto_id')::uuid);
      if q >= (r->>'min')::int and preco is not null then d := q * (preco - (r->>'preco_unit')::numeric); end if;
    when 'leve_pague' then
      for l in select * from jsonb_array_elements(linhas) loop
        if not (r ? 'produto_id') or l->>'produto_id' = r->>'produto_id' then
          unid := ((l->>'quantidade')::int / (r->>'leve')::int) * ((r->>'leve')::int - (r->>'pague')::int);
          d := d + unid * (l->>'preco')::numeric;
        end if;
      end loop;
    when 'casadinha' then
      q := app_private.qtd_produto(linhas, (r->>'se_produto_id')::uuid);
      q2 := app_private.qtd_produto(linhas, (r->>'entao_produto_id')::uuid);
      preco := app_private.preco_produto(linhas, (r->>'entao_produto_id')::uuid);
      if preco is not null and q > 0 and q2 > 0 then
        if r->>'se_produto_id' = r->>'entao_produto_id' then
          sets := q / ((r->>'se_qtd')::int + (r->>'entao_qtd')::int);
        else
          sets := q / (r->>'se_qtd')::int;
        end if;
        unid := least(q2, sets * (r->>'entao_qtd')::int);
        d := unid * preco * (r->>'desconto_percentual')::numeric / 100;
      end if;
    when 'desconto_percentual' then
      if r ? 'produto_id' then
        d := coalesce(app_private.qtd_produto(linhas, (r->>'produto_id')::uuid) * app_private.preco_produto(linhas, (r->>'produto_id')::uuid), 0);
      else d := subtotal; end if;
      d := d * (r->>'percentual')::numeric / 100;
    when 'desconto_valor' then
      d := (r->>'valor')::numeric;
    else
      d := 0;   -- frete_gratis e brinde
  end case;
  return round(greatest(0, least(d, subtotal)), 2);
end $$;

-- ===== Motor do pedido =====
-- p_itens: [{"produto_id": uuid, "quantidade": int}]; p_modalidade: retirada | entrega_bairro | entrega_app
-- p_reservar = true só na criação do pedido (conta o uso da promoção, com trava).
create function app_private.motor_pedido(
  p_itens jsonb, p_cupom text, p_modalidade text, p_bairro_id uuid, p_forma text, p_cliente_id uuid, p_reservar boolean)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  linhas jsonb; n_in int; n_ok int; qtd_total int; subtotal numeric; fee numeric := 0;
  pmin int; pmax int; agora timestamp := (now() at time zone 'America/Fortaleza');
  pr public.promocoes; d numeric; benef numeric; best_ben numeric := 0; best public.promocoes; best_d numeric := 0;
  brindes jsonb := '[]'::jsonb; cupom text := nullif(trim(p_cupom), ''); cupom_status text;
  desc_aplicado numeric := 0; frete_zerado boolean := false; fee_final numeric; gift_prod public.produtos;
begin
  if p_modalidade not in ('retirada','entrega_bairro','entrega_app') then
    raise exception 'modalidade_invalida' using errcode = '22023'; end if;
  begin
    if jsonb_typeof(p_itens) <> 'array' or jsonb_array_length(p_itens) not between 1 and 20 then
      raise exception 'itens_invalidos' using errcode = '22023'; end if;
    select count(distinct (e->>'produto_id')::uuid) into n_in from jsonb_array_elements(p_itens) e;
    if exists (select 1 from jsonb_array_elements(p_itens) e where (e->>'quantidade')::int not between 1 and 100) then
      raise exception 'quantidade_invalida' using errcode = '22023'; end if;
    select jsonb_agg(jsonb_build_object('produto_id', pr2.id, 'nome', pr2.nome, 'quantidade', x.q, 'preco', pr2.preco,
                                        'subtotal', round(x.q * pr2.preco, 2)) order by pr2.ordem, pr2.criado_em),
           count(*)
      into linhas, n_ok
    from (select (e->>'produto_id')::uuid as pid, sum((e->>'quantidade')::int) as q from jsonb_array_elements(p_itens) e group by 1) x
    join public.produtos pr2 on pr2.id = x.pid and pr2.ativo and pr2.preco is not null;
  exception when invalid_text_representation or null_value_not_allowed or numeric_value_out_of_range then
    raise exception 'itens_invalidos' using errcode = '22023';
  end;
  if n_ok is distinct from n_in or linhas is null then raise exception 'produto_invalido' using errcode = '22023'; end if;

  select sum((l->>'quantidade')::int), sum((l->>'subtotal')::numeric) into qtd_total, subtotal from jsonb_array_elements(linhas) l;
  select valor::int into pmin from public.configuracoes where chave = 'pedido_min';
  select valor::int into pmax from public.configuracoes where chave = 'pedido_max';
  if qtd_total < coalesce(pmin, 1) or qtd_total > coalesce(pmax, 100) then
    raise exception 'quantidade_invalida' using errcode = '22023'; end if;

  if p_modalidade = 'entrega_bairro' then
    select taxa into fee from public.bairros_entrega where id = p_bairro_id and ativo;
    if not found then raise exception 'bairro_invalido' using errcode = '22023'; end if;
  end if;

  if p_reservar then perform id from public.promocoes where ativo order by id for update; end if;

  for pr in
    select * from public.promocoes p
    where p.ativo
      and (p.inicio is null or now() >= p.inicio) and (p.fim is null or now() < p.fim)
      and (p.dias_semana is null or extract(dow from agora)::int = any (p.dias_semana))
      and (p.hora_ini is null or p.hora_fim is null
           or (p.hora_ini <= p.hora_fim and agora::time >= p.hora_ini and agora::time < p.hora_fim)
           or (p.hora_ini > p.hora_fim and (agora::time >= p.hora_ini or agora::time < p.hora_fim)))
      and (p.limite_usos is null or p.usos < p.limite_usos)
      and (p.codigo is null or (cupom is not null and lower(p.codigo) = lower(cupom)))
      and (p.formas_pagamento is null or p_forma = any (p.formas_pagamento))
      and (not p.primeira_compra or p_cliente_id is null
           or not exists (select 1 from public.pedidos o where o.cliente_id = p_cliente_id and o.status <> 'cancelado'))
      and (p.min_qtd is null or qtd_total >= p.min_qtd)
      and (p.min_valor is null or subtotal >= p.min_valor)
  loop
    d := app_private.desconto_promocao(pr, linhas, subtotal);
    benef := 0;
    if pr.tipo = 'brinde' then
      select * into gift_prod from public.produtos where id = (pr.regra->>'produto_id')::uuid and ativo and preco is not null;
      if found then benef := (pr.regra->>'qtd')::int * gift_prod.preco; end if;
    end if;
    -- o frete grátis de uma promoção só vale quando a regra dela se aplica ao carrinho (desconto > 0, brinde ou promoção só de frete)
    if d > 0 or benef > 0 or pr.tipo = 'frete_gratis' then
      benef := benef + d + case when pr.frete_gratis or pr.tipo = 'frete_gratis' then fee else 0 end;
    end if;
    if benef > 0 and (best.id is null or benef > best_ben or (benef = best_ben and pr.prioridade > best.prioridade)) then
      best := pr; best_ben := benef; best_d := d;
    end if;
  end loop;

  if best.id is not null then
    desc_aplicado := best_d;
    frete_zerado := (best.frete_gratis or best.tipo = 'frete_gratis') and fee > 0;
    if best.tipo = 'brinde' then
      select * into gift_prod from public.produtos where id = (best.regra->>'produto_id')::uuid and ativo and preco is not null;
      if found then
        brindes := jsonb_build_array(jsonb_build_object('produto_id', gift_prod.id, 'nome', gift_prod.nome, 'quantidade', (best.regra->>'qtd')::int));
      end if;
    end if;
    if p_reservar then update public.promocoes set usos = usos + 1 where id = best.id; end if;
  end if;
  fee_final := case when frete_zerado then 0 else fee end;

  if cupom is null then cupom_status := null;
  elsif not exists (select 1 from public.promocoes where ativo and codigo is not null and lower(codigo) = lower(cupom)) then cupom_status := 'invalido';
  elsif best.id is not null and best.codigo is not null and lower(best.codigo) = lower(cupom) then cupom_status := 'aplicado';
  else cupom_status := 'nao_aplicavel';
  end if;

  return jsonb_build_object(
    'itens', linhas, 'brindes', brindes, 'quantidade', qtd_total, 'subtotal', subtotal,
    'desconto', desc_aplicado, 'taxa_entrega', fee_final, 'taxa_original', fee,
    'total', round(subtotal - desc_aplicado + fee_final, 2),
    'frete_gratis', frete_zerado, 'modalidade', p_modalidade,
    'promocao', case when best.id is null then null else jsonb_build_object('id', best.id, 'nome', best.nome, 'codigo', best.codigo) end,
    'cupom_status', cupom_status);
end $$;

-- ===== Funções públicas =====
create function public.simular_pedido(
  p_itens jsonb, p_cupom text default null, p_modalidade text default 'entrega_app',
  p_bairro_id uuid default null, p_forma text default null, p_whatsapp text default null)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare cid uuid;
begin
  if p_whatsapp is not null then
    begin
      select id into cid from public.clientes where whatsapp = public.normalizar_whatsapp(p_whatsapp);
    exception when others then cid := null;
    end;
  end if;
  return app_private.motor_pedido(p_itens, p_cupom, p_modalidade, p_bairro_id, nullif(trim(p_forma), ''), cid, false);
end $$;

create function public.obter_vitrine() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'produtos', coalesce((select jsonb_agg(jsonb_build_object('id', p.id, 'nome', p.nome, 'descricao', p.descricao, 'preco', p.preco,
                   'foto_url', p.foto_url, 'volume_ml', p.volume_ml, 'categoria', p.categoria) order by p.ordem, p.criado_em)
                 from public.produtos p where p.ativo and p.preco is not null), '[]'::jsonb),
    'promocoes', coalesce((select jsonb_agg(jsonb_build_object('id', x.id, 'tipo', x.tipo, 'nome', x.nome, 'regra', x.regra, 'titulo', x.titulo,
                   'qtd_label', x.qtd_label, 'rotulo', x.rotulo, 'notas', x.notas, 'imagem_url', x.imagem_url, 'cta', x.cta,
                   'qtd_sugerida', x.qtd_sugerida, 'destaque', x.destaque, 'frete_gratis', x.frete_gratis or x.tipo = 'frete_gratis',
                   'min_qtd', x.min_qtd, 'min_valor', x.min_valor) order by x.ordem_site, x.criado_em)
                 from public.promocoes x
                 where x.ativo and x.publica and x.codigo is null
                   and (x.inicio is null or now() >= x.inicio) and (x.fim is null or now() < x.fim)
                   and (x.limite_usos is null or x.usos < x.limite_usos)), '[]'::jsonb))
$$;

-- criação do pedido (nova): vários produtos, entrega por bairro, cupom
create function app_private.criar_pedido_core(
  p_whatsapp text, p_itens jsonb, p_nome text, p_nasc date, p_email text, p_aceite boolean,
  p_forma text, p_endereco text, p_bairro text, p_bairro_id uuid, p_modalidade text, p_cupom text,
  p_obs text, p_origem text)
returns table (pedido_codigo text, pedido_total numeric, pedido_desconto numeric, pedido_taxa numeric, pedido_promocao text)
language plpgsql security definer set search_path = '' as $$
declare
  w text; cid uuid; ped_id uuid; cod text; forma text; m jsonb; l jsonb; bnome text;
begin
  w := public.normalizar_whatsapp(p_whatsapp);
  forma := nullif(trim(p_forma), '');
  if forma is not null and not exists (select 1 from public.formas_pagamento where id = forma and ativo) then
    raise exception 'pagamento_invalido' using errcode = '22023';
  end if;
  if p_nasc is not null and (p_nasc > current_date or p_nasc < date '1900-01-01') then
    raise exception 'nascimento_invalido' using errcode = '22023';
  end if;
  -- valida o carrinho antes de criar cliente (nada é gravado se o pedido for inválido)
  perform app_private.motor_pedido(p_itens, p_cupom, p_modalidade, p_bairro_id, forma, null, false);

  select id into cid from public.clientes where whatsapp = w;
  if cid is null then
    if p_nome is null or length(trim(p_nome)) < 3 then
      raise exception 'nome_obrigatorio' using errcode = '22023';
    end if;
    if p_origem = 'site' and not coalesce(p_aceite, false) then
      raise exception 'aceite_obrigatorio' using errcode = '22023';
    end if;
    insert into public.clientes (whatsapp, nome, data_nascimento, email, aceite_lgpd_em)
    values (w, trim(p_nome), p_nasc, nullif(trim(p_email), ''),
            case when coalesce(p_aceite, false) then now() end)
    returning id into cid;
  else
    update public.clientes set
      data_nascimento = coalesce(data_nascimento, p_nasc),
      email = coalesce(email, nullif(trim(p_email), '')),
      aceite_lgpd_em = coalesce(aceite_lgpd_em, case when coalesce(p_aceite, false) then now() end)
    where id = cid;
  end if;

  if p_origem = 'site' and (
    select count(*) from public.pedidos
    where cliente_id = cid and origem = 'site' and criado_em > now() - interval '1 hour'
  ) >= 5 then
    raise exception 'muitos_pedidos' using errcode = 'P0001';
  end if;

  m := app_private.motor_pedido(p_itens, p_cupom, p_modalidade, p_bairro_id, forma, cid, true);
  cod := 'TQR-' || lpad(nextval('public.pedido_codigo_seq')::text, 4, '0');
  select nome into bnome from public.bairros_entrega where id = p_bairro_id;

  insert into public.pedidos (codigo, cliente_id, total, subtotal, desconto, taxa_entrega, forma_pagamento, endereco, bairro,
                              observacao, origem, modalidade, bairro_id, promocao_id, cupom)
  values (cod, cid, (m->>'total')::numeric, (m->>'subtotal')::numeric, (m->>'desconto')::numeric, (m->>'taxa_entrega')::numeric,
          forma, nullif(trim(p_endereco), ''), coalesce(bnome, nullif(trim(p_bairro), '')),
          nullif(trim(p_obs), ''), p_origem, p_modalidade,
          case when p_modalidade = 'entrega_bairro' then p_bairro_id end,
          (m->'promocao'->>'id')::uuid,
          case when m->>'cupom_status' = 'aplicado' then m->'promocao'->>'codigo' end)
  returning id into ped_id;

  for l in select * from jsonb_array_elements(m->'itens') loop
    insert into public.itens_pedido (pedido_id, produto_id, quantidade, subtotal, preco_unitario, nome_produto)
    values (ped_id, (l->>'produto_id')::uuid, (l->>'quantidade')::int, (l->>'subtotal')::numeric, (l->>'preco')::numeric, l->>'nome');
  end loop;
  for l in select * from jsonb_array_elements(m->'brindes') loop
    insert into public.itens_pedido (pedido_id, produto_id, quantidade, subtotal, preco_unitario, nome_produto, brinde)
    values (ped_id, (l->>'produto_id')::uuid, (l->>'quantidade')::int, 0, 0, l->>'nome', true);
  end loop;

  return query select cod, (m->>'total')::numeric, (m->>'desconto')::numeric, (m->>'taxa_entrega')::numeric, m->'promocao'->>'nome';
end $$;

create function public.criar_pedido_v2(
  p_whatsapp text, p_itens jsonb, p_nome text default null, p_data_nascimento date default null,
  p_email text default null, p_aceite_lgpd boolean default false, p_forma_pagamento text default null,
  p_endereco text default null, p_bairro text default null, p_bairro_id uuid default null,
  p_modalidade text default 'entrega_app', p_cupom text default null, p_observacao text default null)
returns table (pedido_codigo text, pedido_total numeric, pedido_desconto numeric, pedido_taxa numeric, pedido_promocao text)
language sql security definer set search_path = '' as $$
  select * from app_private.criar_pedido_core(p_whatsapp, p_itens, p_nome, p_data_nascimento, p_email, p_aceite_lgpd,
    p_forma_pagamento, p_endereco, p_bairro, p_bairro_id, p_modalidade, p_cupom, p_observacao, 'site')
$$;

create function public.admin_criar_pedido_v2(
  p_whatsapp text, p_itens jsonb, p_nome text default null, p_forma_pagamento text default null,
  p_endereco text default null, p_bairro text default null, p_bairro_id uuid default null,
  p_modalidade text default 'entrega_app', p_cupom text default null, p_observacao text default null)
returns table (pedido_codigo text, pedido_total numeric, pedido_desconto numeric, pedido_taxa numeric, pedido_promocao text)
language plpgsql security definer set search_path = '' as $$
begin
  if not public.tem_permissao('pedidos.criar') then
    raise exception 'nao_autorizado' using errcode = '42501';
  end if;
  return query select * from app_private.criar_pedido_core(p_whatsapp, p_itens, p_nome, null, null, false,
    p_forma_pagamento, p_endereco, p_bairro, p_bairro_id, p_modalidade, p_cupom, p_observacao, 'manual');
end $$;

-- compatibilidade: telas antigas (em cache) e o pedido manual antigo continuam funcionando, agora pelo motor
create or replace function app_private.criar_pedido_interno(
  p_whatsapp text, p_qtd int, p_nome text, p_nasc date, p_email text, p_aceite boolean,
  p_forma text, p_endereco text, p_bairro text, p_obs text, p_origem text)
returns table (pedido_codigo text, pedido_total numeric)
language plpgsql security definer set search_path = '' as $$
declare prod uuid;
begin
  select id into prod from public.produtos where ativo and preco is not null order by ordem, criado_em limit 1;
  return query
    select c.pedido_codigo, c.pedido_total from app_private.criar_pedido_core(
      p_whatsapp, jsonb_build_array(jsonb_build_object('produto_id', prod, 'quantidade', p_qtd)), p_nome, p_nasc, p_email, p_aceite,
      p_forma, p_endereco, p_bairro, null, case when nullif(trim(p_endereco), '') is null then 'retirada' else 'entrega_app' end,
      null, p_obs, p_origem) c;
end $$;

create or replace function public.calcular_total(p_qtd int) returns numeric
language plpgsql stable security definer set search_path = '' as $$
declare prod uuid;
begin
  select id into prod from public.produtos where ativo and preco is not null order by ordem, criado_em limit 1;
  return (app_private.motor_pedido(jsonb_build_array(jsonb_build_object('produto_id', prod, 'quantidade', p_qtd)),
          null, 'retirada', null, null, null, false)->>'total')::numeric;
end $$;

-- contador: brindes não contam como vendidos
create or replace function public.obter_contador() returns int
language sql stable security definer set search_path = '' as $$
  select greatest(0,
    (select valor::numeric from public.configuracoes where chave = 'contador_base')::int
    + (select valor::numeric from public.configuracoes where chave = 'contador_ajuste')::int
    + coalesce((select sum(i.quantidade) from public.itens_pedido i
                join public.pedidos p on p.id = i.pedido_id
                where p.status in ('pago','saiu_entrega','entregue') and not i.brinde), 0)::int)
$$;

-- ===== Promoções antigas viram cadastro =====
do $$
declare prod uuid; un numeric; c3 numeric; m5 numeric;
begin
  select id into prod from public.produtos where ativo order by criado_em limit 1;
  select valor::numeric into c3 from public.configuracoes where chave = 'preco_combo3';
  select valor::numeric into m5 from public.configuracoes where chave = 'preco_5mais';
  insert into public.promocoes (nome, tipo, regra, publica, titulo, qtd_label, rotulo, notas, imagem_url, cta, qtd_sugerida, destaque, ordem_site)
  values ('Combo 3', 'combo', jsonb_build_object('itens', jsonb_build_array(jsonb_build_object('produto_id', prod, 'qtd', 3)), 'preco', c3),
          true, 'Combo 3', '3 garrafas de 300 ml', 'Mais pedido',
          array['Uma pra hoje e duas pro freezer','Delivery ou retirada'], 'img/hf-combo.webp', 'Quero o combo', 3, true, 20);
  insert into public.promocoes (nome, tipo, regra, publica, frete_gratis, titulo, qtd_label, notas, imagem_url, cta, qtd_sugerida, ordem_site)
  values ('5 ou mais', 'faixa_quantidade', jsonb_build_object('produto_id', prod, 'min', 5, 'preco_unit', m5),
          true, true, '5 ou mais', 'a partir de 5 garrafas',
          array['Estoque da semana para a família','Frete por nossa conta'], 'img/kit5.webp', 'Pedir 5 ou mais', 5, 30);
end $$;

-- ===== Permissões (RLS) =====
alter table public.promocoes enable row level security;
revoke all on public.promocoes from anon;
create policy promo_sel on public.promocoes for select to authenticated using ((select public.tem_permissao('promocoes.gerir')));
create policy promo_ins on public.promocoes for insert to authenticated with check ((select public.tem_permissao('promocoes.gerir')));
create policy promo_upd on public.promocoes for update to authenticated
  using ((select public.tem_permissao('promocoes.gerir'))) with check ((select public.tem_permissao('promocoes.gerir')));
create policy promo_del on public.promocoes for delete to authenticated using ((select public.tem_permissao('promocoes.gerir')));

revoke all on function app_private.motor_pedido(jsonb,text,text,uuid,text,uuid,boolean) from public, anon, authenticated;
revoke all on function app_private.desconto_promocao(public.promocoes,jsonb,numeric) from public, anon, authenticated;
revoke all on function app_private.qtd_produto(jsonb,uuid), app_private.preco_produto(jsonb,uuid) from public, anon, authenticated;
revoke all on function app_private.criar_pedido_core(text,jsonb,text,date,text,boolean,text,text,text,uuid,text,text,text,text) from public, anon, authenticated;
revoke all on function public.simular_pedido(jsonb,text,text,uuid,text,text) from public, anon, authenticated;
revoke all on function public.obter_vitrine() from public, anon, authenticated;
revoke all on function public.criar_pedido_v2(text,jsonb,text,date,text,boolean,text,text,text,uuid,text,text,text) from public, anon, authenticated;
revoke all on function public.admin_criar_pedido_v2(text,jsonb,text,text,text,text,uuid,text,text,text) from public, anon, authenticated;
grant execute on function public.simular_pedido(jsonb,text,text,uuid,text,text) to anon, authenticated;
grant execute on function public.obter_vitrine() to anon, authenticated;
grant execute on function public.criar_pedido_v2(text,jsonb,text,date,text,boolean,text,text,text,uuid,text,text,text) to anon, authenticated;
grant execute on function public.admin_criar_pedido_v2(text,jsonb,text,text,text,text,uuid,text,text,text) to authenticated;

-- ===== Fotos de produtos e promoções (Storage) =====
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('produtos', 'produtos', true, 2097152, array['image/webp','image/jpeg','image/png'])
on conflict (id) do nothing;
create policy produtos_fotos_sel on storage.objects for select to authenticated
  using (bucket_id = 'produtos' and ((select public.tem_permissao('produtos.gerir')) or (select public.tem_permissao('promocoes.gerir'))));
create policy produtos_fotos_ins on storage.objects for insert to authenticated
  with check (bucket_id = 'produtos' and ((select public.tem_permissao('produtos.gerir')) or (select public.tem_permissao('promocoes.gerir'))));
create policy produtos_fotos_upd on storage.objects for update to authenticated
  using (bucket_id = 'produtos' and ((select public.tem_permissao('produtos.gerir')) or (select public.tem_permissao('promocoes.gerir'))));
create policy produtos_fotos_del on storage.objects for delete to authenticated
  using (bucket_id = 'produtos' and ((select public.tem_permissao('produtos.gerir')) or (select public.tem_permissao('promocoes.gerir'))));
