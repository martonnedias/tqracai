-- TQR Açaí · "Monte o seu açaí": grupos de opções (complementos, caldas, extras), preço e custo por opção, montagem no pedido
-- O cliente escolhe as opções de cada garrafa; o servidor valida (mínimo/máximo/grátis), soma o adicional e guarda um instantâneo.
-- As promoções continuam valendo sobre o produto-base; o adicional das opções entra depois, sem desconto.

-- ===== tabelas =====
create table public.grupos_opcao (
  id uuid primary key default gen_random_uuid(),
  nome text not null check (length(trim(nome)) >= 2 and length(nome) <= 60),
  minimo int not null default 0 check (minimo >= 0),
  maximo int not null default 1 check (maximo >= 1),
  gratis_ate int not null default 0 check (gratis_ate >= 0),     -- quantas escolhas do grupo não cobram adicional
  produtos uuid[],                                                -- nulo = vale para todos os produtos
  ativo boolean not null default true,
  ordem int not null default 0,
  criado_em timestamptz not null default now(),
  check (maximo >= minimo)
);
create table public.opcoes (
  id uuid primary key default gen_random_uuid(),
  grupo_id uuid not null references public.grupos_opcao(id) on delete restrict,
  nome text not null check (length(trim(nome)) >= 1 and length(nome) <= 60),
  preco_adicional numeric(10,2) not null default 0 check (preco_adicional >= 0),
  esgotado boolean not null default false,                        -- "acabou hoje": continua cadastrada, some das escolhas
  ativo boolean not null default true,
  ordem int not null default 0,
  criado_em timestamptz not null default now(),
  unique (grupo_id, nome)
);
create table public.opcao_receitas (
  id uuid primary key default gen_random_uuid(),
  opcao_id uuid not null references public.opcoes(id) on delete cascade,
  insumo_id uuid not null references public.insumos(id) on delete restrict,
  quantidade numeric(14,4) not null check (quantidade > 0),
  perda_pct numeric(5,2) not null default 0 check (perda_pct >= 0 and perda_pct <= 90),
  ativo boolean not null default true,
  unique (opcao_id, insumo_id)
);
alter table public.pedidos add column extras numeric(10,2) not null default 0 check (extras >= 0),
                           add column montagens jsonb not null default '[]'::jsonb;

alter table public.grupos_opcao enable row level security;
alter table public.opcoes enable row level security;
alter table public.opcao_receitas enable row level security;
revoke all on public.grupos_opcao, public.opcoes, public.opcao_receitas from anon, authenticated;
grant select, insert, update on public.grupos_opcao, public.opcoes to authenticated;
grant select on public.opcao_receitas to authenticated;
create policy grp_sel on public.grupos_opcao for select to authenticated using ((select public.tem_permissao('produtos.gerir')));
create policy grp_ins on public.grupos_opcao for insert to authenticated with check ((select public.tem_permissao('produtos.gerir')));
create policy grp_upd on public.grupos_opcao for update to authenticated using ((select public.tem_permissao('produtos.gerir'))) with check ((select public.tem_permissao('produtos.gerir')));
create policy opc_sel on public.opcoes for select to authenticated using ((select public.tem_permissao('produtos.gerir')));
create policy opc_ins on public.opcoes for insert to authenticated with check ((select public.tem_permissao('produtos.gerir')));
create policy opc_upd on public.opcoes for update to authenticated using ((select public.tem_permissao('produtos.gerir'))) with check ((select public.tem_permissao('produtos.gerir')));
create policy orc_sel on public.opcao_receitas for select to authenticated using ((select public.tem_permissao('custos.ver')));

-- ===== custo e ficha técnica da opção =====
create function app_private.custo_opcao(p_opcao uuid) returns numeric
language sql stable security definer set search_path = '' as $$
  select round(coalesce(sum(r.quantidade * (1 + r.perda_pct / 100) * i.custo_atual), 0), 4)
  from public.opcao_receitas r join public.insumos i on i.id = r.insumo_id where r.opcao_id = p_opcao and r.ativo
$$;

create function public.salvar_ficha_opcao(p_opcao uuid, p_itens jsonb) returns numeric
language plpgsql security definer set search_path = '' as $$
declare it jsonb; ids uuid[] := '{}'; iid uuid; q numeric; perda numeric;
begin
  if not public.tem_permissao('custos.gerir') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  perform 1 from public.opcoes where id = p_opcao;
  if not found then raise exception 'opcao_inexistente' using errcode = '22023'; end if;
  if jsonb_typeof(p_itens) <> 'array' then raise exception 'itens_invalidos' using errcode = '22023'; end if;
  for it in select * from jsonb_array_elements(p_itens) loop
    iid := (it->>'insumo_id')::uuid; q := (it->>'quantidade')::numeric; perda := coalesce((it->>'perda_pct')::numeric, 0);
    if q is null or q <= 0 or perda < 0 or perda > 90 then raise exception 'itens_invalidos' using errcode = '22023'; end if;
    perform 1 from public.insumos where id = iid;
    if not found then raise exception 'insumo_inexistente' using errcode = '22023'; end if;
    insert into public.opcao_receitas (opcao_id, insumo_id, quantidade, perda_pct, ativo) values (p_opcao, iid, q, perda, true)
    on conflict (opcao_id, insumo_id) do update set quantidade = excluded.quantidade, perda_pct = excluded.perda_pct, ativo = true;
    ids := ids || iid;
  end loop;
  update public.opcao_receitas set ativo = false where opcao_id = p_opcao and ativo and not (insumo_id = any(ids));
  return app_private.custo_opcao(p_opcao);
end $$;

create view public.v_custo_opcao with (security_invoker = true) as
select o.id as opcao_id, o.nome, o.grupo_id, g.nome as grupo, o.preco_adicional, o.ativo, o.esgotado,
  (select round(coalesce(sum(r.quantidade * (1 + r.perda_pct / 100) * i.custo_atual), 0), 4)
     from public.opcao_receitas r join public.insumos i on i.id = r.insumo_id where r.opcao_id = o.id and r.ativo) as custo,
  exists (select 1 from public.opcao_receitas r where r.opcao_id = o.id and r.ativo) as tem_ficha
from public.opcoes o join public.grupos_opcao g on g.id = o.grupo_id
where public.tem_permissao('custos.ver');
revoke all on public.v_custo_opcao from public, anon;
grant select on public.v_custo_opcao to authenticated;
revoke all on function public.salvar_ficha_opcao(uuid,jsonb) from public, anon, authenticated;
grant execute on function public.salvar_ficha_opcao(uuid,jsonb) to authenticated;

-- ===== validação e preço das montagens =====
-- p_montagens: [{"produto_id": "...", "quantidade": 2, "opcoes": ["id", ...]}]  (cada entrada = N garrafas iguais)
create function app_private.calcular_montagens(p_itens jsonb, p_montagens jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  m jsonb; pid uuid; q int; ids uuid[]; pnome text; g public.grupos_opcao; n int; usados int; cobradas numeric; extra_unit numeric; custo_unit numeric;
  snap jsonb := '[]'::jsonb; opsnap jsonb; extras_total numeric := 0; o record; k int; dif int;
begin
  if p_montagens is null or jsonb_typeof(p_montagens) = 'null' then return jsonb_build_object('extras', 0, 'montagens', '[]'::jsonb); end if;
  if jsonb_typeof(p_montagens) <> 'array' or jsonb_array_length(p_montagens) > 20 then raise exception 'montagem_invalida' using errcode = '22023'; end if;
  begin
    for m in select * from jsonb_array_elements(p_montagens) loop
      pid := (m->>'produto_id')::uuid; q := (m->>'quantidade')::int;
      if q is null or q not between 1 and 100 then raise exception 'montagem_invalida' using errcode = '22023'; end if;
      select nome into pnome from public.produtos where id = pid and ativo;
      if pnome is null then raise exception 'montagem_invalida' using errcode = '22023'; end if;
      select coalesce(array_agg(distinct x::uuid), '{}') into ids from jsonb_array_elements_text(coalesce(m->'opcoes', '[]'::jsonb)) x;
      if array_length(ids, 1) is not null and array_length(ids, 1) <> jsonb_array_length(coalesce(m->'opcoes', '[]'::jsonb)) then
        raise exception 'opcao_invalida' using errcode = '22023'; end if;
      usados := 0; extra_unit := 0; custo_unit := 0; opsnap := '[]'::jsonb;
      for g in select * from public.grupos_opcao x where x.ativo and (x.produtos is null or pid = any (x.produtos)) order by x.ordem, x.criado_em loop
        select count(*) into n from public.opcoes o2 where o2.grupo_id = g.id and o2.id = any (ids);
        if n < g.minimo or n > g.maximo then raise exception 'escolha_invalida:%', g.nome using errcode = '22023'; end if;
        usados := usados + n; k := 0;
        for o in select o2.* from public.opcoes o2 where o2.grupo_id = g.id and o2.id = any (ids) order by o2.preco_adicional desc, o2.ordem loop
          if not o.ativo or o.esgotado then raise exception 'opcao_indisponivel:%', o.nome using errcode = '22023'; end if;
          k := k + 1;
          cobradas := case when k > g.gratis_ate then o.preco_adicional else 0 end;
          extra_unit := extra_unit + cobradas;
          custo_unit := custo_unit + app_private.custo_opcao(o.id);
          opsnap := opsnap || jsonb_build_object('id', o.id, 'grupo', g.nome, 'nome', o.nome, 'preco', cobradas);
        end loop;
      end loop;
      if usados <> coalesce(array_length(ids, 1), 0) then raise exception 'opcao_invalida' using errcode = '22023'; end if;
      snap := snap || jsonb_build_object('produto_id', pid, 'nome_produto', pnome, 'quantidade', q, 'opcoes', opsnap,
                                         'extra_unit', round(extra_unit, 2), 'custo_unit', round(custo_unit, 4));
      extras_total := extras_total + round(extra_unit, 2) * q;
    end loop;
  exception when invalid_text_representation or null_value_not_allowed then
    raise exception 'montagem_invalida' using errcode = '22023';
  end;
  -- não pode haver mais garrafas montadas do que garrafas do produto no carrinho
  select count(*) into dif from (
    select (s->>'produto_id')::uuid pid, sum((s->>'quantidade')::int) qm from jsonb_array_elements(snap) s group by 1) a
    where a.qm > coalesce((select sum((e->>'quantidade')::int) from jsonb_array_elements(p_itens) e where (e->>'produto_id')::uuid = a.pid), 0);
  if dif > 0 then raise exception 'montagem_invalida' using errcode = '22023'; end if;
  return jsonb_build_object('extras', round(extras_total, 2), 'montagens', snap);
end $$;

-- ===== simulação e criação do pedido com montagens =====
create function public.simular_pedido_v3(
  p_itens jsonb, p_cupom text default null, p_modalidade text default 'entrega_app',
  p_bairro_id uuid default null, p_forma text default null, p_whatsapp text default null, p_montagens jsonb default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r jsonb; c jsonb;
begin
  r := public.simular_pedido(p_itens, p_cupom, p_modalidade, p_bairro_id, p_forma, p_whatsapp);
  c := app_private.calcular_montagens(p_itens, p_montagens);
  return r || jsonb_build_object('extras', c->'extras', 'montagens', c->'montagens',
                                 'total', round((r->>'total')::numeric + (c->>'extras')::numeric, 2));
end $$;

create function app_private.criar_pedido_core(
  p_whatsapp text, p_itens jsonb, p_nome text, p_nasc date, p_email text, p_aceite boolean,
  p_forma text, p_endereco text, p_bairro text, p_bairro_id uuid, p_modalidade text, p_cupom text,
  p_obs text, p_origem text, p_montagens jsonb)
returns table (pedido_codigo text, pedido_total numeric, pedido_desconto numeric, pedido_taxa numeric, pedido_promocao text)
language plpgsql security definer set search_path = '' as $$
declare
  w text; cid uuid; ped_id uuid; cod text; forma text; m jsonb; l jsonb; bnome text; c jsonb; extras numeric;
begin
  w := public.normalizar_whatsapp(p_whatsapp);
  forma := nullif(trim(p_forma), '');
  if forma is not null and not exists (select 1 from public.formas_pagamento where id = forma and ativo) then
    raise exception 'pagamento_invalido' using errcode = '22023';
  end if;
  if p_nasc is not null and (p_nasc > current_date or p_nasc < date '1900-01-01') then
    raise exception 'nascimento_invalido' using errcode = '22023';
  end if;
  perform app_private.motor_pedido(p_itens, p_cupom, p_modalidade, p_bairro_id, forma, null, false);
  c := app_private.calcular_montagens(p_itens, p_montagens);
  extras := (c->>'extras')::numeric;

  select id into cid from public.clientes where whatsapp = w;
  if cid is null then
    if p_nome is null or length(trim(p_nome)) < 3 then raise exception 'nome_obrigatorio' using errcode = '22023'; end if;
    if p_origem = 'site' and not coalesce(p_aceite, false) then raise exception 'aceite_obrigatorio' using errcode = '22023'; end if;
    insert into public.clientes (whatsapp, nome, data_nascimento, email, aceite_lgpd_em)
    values (w, trim(p_nome), p_nasc, nullif(trim(p_email), ''), case when coalesce(p_aceite, false) then now() end)
    returning id into cid;
  else
    update public.clientes set
      data_nascimento = coalesce(data_nascimento, p_nasc),
      email = coalesce(email, nullif(trim(p_email), '')),
      aceite_lgpd_em = coalesce(aceite_lgpd_em, case when coalesce(p_aceite, false) then now() end)
    where id = cid;
  end if;

  if p_origem = 'site' and (
    select count(*) from public.pedidos where cliente_id = cid and origem = 'site' and criado_em > now() - interval '1 hour'
  ) >= 5 then raise exception 'muitos_pedidos' using errcode = 'P0001'; end if;

  m := app_private.motor_pedido(p_itens, p_cupom, p_modalidade, p_bairro_id, forma, cid, true);
  cod := 'TQR-' || lpad(nextval('public.pedido_codigo_seq')::text, 4, '0');
  select nome into bnome from public.bairros_entrega where id = p_bairro_id;

  insert into public.pedidos (codigo, cliente_id, total, subtotal, desconto, taxa_entrega, forma_pagamento, endereco, bairro,
                              observacao, origem, modalidade, bairro_id, promocao_id, cupom, extras, montagens)
  values (cod, cid, round((m->>'total')::numeric + extras, 2), (m->>'subtotal')::numeric, (m->>'desconto')::numeric, (m->>'taxa_entrega')::numeric,
          forma, nullif(trim(p_endereco), ''), coalesce(bnome, nullif(trim(p_bairro), '')),
          nullif(trim(p_obs), ''), p_origem, p_modalidade,
          case when p_modalidade = 'entrega_bairro' then p_bairro_id end,
          (m->'promocao'->>'id')::uuid,
          case when m->>'cupom_status' = 'aplicado' then m->'promocao'->>'codigo' end,
          extras, c->'montagens')
  returning id into ped_id;

  for l in select * from jsonb_array_elements(m->'itens') loop
    insert into public.itens_pedido (pedido_id, produto_id, quantidade, subtotal, preco_unitario, nome_produto)
    values (ped_id, (l->>'produto_id')::uuid, (l->>'quantidade')::int, (l->>'subtotal')::numeric, (l->>'preco')::numeric, l->>'nome');
  end loop;
  for l in select * from jsonb_array_elements(m->'brindes') loop
    insert into public.itens_pedido (pedido_id, produto_id, quantidade, subtotal, preco_unitario, nome_produto, brinde)
    values (ped_id, (l->>'produto_id')::uuid, (l->>'quantidade')::int, 0, 0, l->>'nome', true);
  end loop;
  -- o custo das opções escolhidas entra no custo da linha do produto
  update public.itens_pedido i set custo_unitario = coalesce(i.custo_unitario, 0) + round(x.custo / i.quantidade, 4)
  from (select (s->>'produto_id')::uuid pid, sum((s->>'custo_unit')::numeric * (s->>'quantidade')::int) custo
        from jsonb_array_elements(c->'montagens') s group by 1) x
  where i.pedido_id = ped_id and i.produto_id = x.pid and not i.brinde and x.custo > 0;

  return query select cod, round((m->>'total')::numeric + extras, 2), (m->>'desconto')::numeric, (m->>'taxa_entrega')::numeric, m->'promocao'->>'nome';
end $$;

create function public.criar_pedido_v3(
  p_whatsapp text, p_itens jsonb, p_nome text default null, p_data_nascimento date default null,
  p_email text default null, p_aceite_lgpd boolean default false, p_forma_pagamento text default null,
  p_endereco text default null, p_bairro text default null, p_bairro_id uuid default null,
  p_modalidade text default 'entrega_app', p_cupom text default null, p_observacao text default null, p_montagens jsonb default null)
returns table (pedido_codigo text, pedido_total numeric, pedido_desconto numeric, pedido_taxa numeric, pedido_promocao text)
language sql security definer set search_path = '' as $$
  select * from app_private.criar_pedido_core(p_whatsapp, p_itens, p_nome, p_data_nascimento, p_email, p_aceite_lgpd,
    p_forma_pagamento, p_endereco, p_bairro, p_bairro_id, p_modalidade, p_cupom, p_observacao, 'site', p_montagens)
$$;

create function public.admin_criar_pedido_v3(
  p_whatsapp text, p_itens jsonb, p_nome text default null, p_forma_pagamento text default null,
  p_endereco text default null, p_bairro text default null, p_bairro_id uuid default null,
  p_modalidade text default 'entrega_app', p_cupom text default null, p_observacao text default null, p_montagens jsonb default null)
returns table (pedido_codigo text, pedido_total numeric, pedido_desconto numeric, pedido_taxa numeric, pedido_promocao text)
language plpgsql security definer set search_path = '' as $$
begin
  if not public.tem_permissao('pedidos.criar') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  return query select * from app_private.criar_pedido_core(p_whatsapp, p_itens, p_nome, null, null, false,
    p_forma_pagamento, p_endereco, p_bairro, p_bairro_id, p_modalidade, p_cupom, p_observacao, 'manual', p_montagens);
end $$;

revoke all on function public.simular_pedido_v3(jsonb,text,text,uuid,text,text,jsonb),
  public.criar_pedido_v3(text,jsonb,text,date,text,boolean,text,text,text,uuid,text,text,text,jsonb),
  public.admin_criar_pedido_v3(text,jsonb,text,text,text,text,uuid,text,text,text,jsonb) from public, anon, authenticated;
grant execute on function public.simular_pedido_v3(jsonb,text,text,uuid,text,text,jsonb),
  public.criar_pedido_v3(text,jsonb,text,date,text,boolean,text,text,text,uuid,text,text,text,jsonb) to anon, authenticated;
grant execute on function public.admin_criar_pedido_v3(text,jsonb,text,text,text,text,uuid,text,text,text,jsonb) to authenticated;

-- ===== vitrine pública com as opções (sem custo nenhum) =====
create or replace function public.obter_vitrine() returns jsonb
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
                   and (x.limite_usos is null or x.usos < x.limite_usos)), '[]'::jsonb),
    'personalizacao', coalesce((select jsonb_agg(jsonb_build_object('id', g.id, 'nome', g.nome, 'minimo', g.minimo, 'maximo', g.maximo,
                   'gratis_ate', g.gratis_ate, 'produtos', to_jsonb(g.produtos),
                   'opcoes', coalesce((select jsonb_agg(jsonb_build_object('id', o.id, 'nome', o.nome, 'preco', o.preco_adicional, 'esgotado', o.esgotado)
                                       order by o.ordem, o.criado_em) from public.opcoes o where o.grupo_id = g.id and o.ativo), '[]'::jsonb))
                   order by g.ordem, g.criado_em)
                 from public.grupos_opcao g where g.ativo
                   and exists (select 1 from public.opcoes o2 where o2.grupo_id = g.id and o2.ativo)), '[]'::jsonb))
$$;

-- ===== baixa de estoque: produto-base + opções escolhidas =====
create or replace function app_private.pedido_estoque() returns trigger
language plpgsql security definer set search_path = '' as $$
declare pagos text[] := array['pago','saiu_entrega','entregue'];
begin
  if new.status is not distinct from old.status then return new; end if;
  if new.status::text = any(pagos) and not (old.status::text = any(pagos)) then
    insert into public.movimentos_estoque (insumo_id, tipo, quantidade, pedido_id, motivo)
    select t.insumo_id, 'consumo', -round(sum(t.q), 3), new.id, 'Pedido ' || new.codigo
    from (
      select r.insumo_id, i.quantidade * r.quantidade * (1 + r.perda_pct / 100) as q
        from public.itens_pedido i join public.produto_receitas r on r.produto_id = i.produto_id and r.ativo
        where i.pedido_id = new.id
      union all
      select r.insumo_id, (m->>'quantidade')::numeric * r.quantidade * (1 + r.perda_pct / 100)
        from jsonb_array_elements(new.montagens) m
        cross join lateral jsonb_array_elements(m->'opcoes') o
        join public.opcao_receitas r on r.opcao_id = (o->>'id')::uuid and r.ativo
    ) t
    group by t.insumo_id
    having round(sum(t.q), 3) > 0
    on conflict do nothing;
  elsif new.status = 'cancelado' and old.status::text = any(pagos) then
    insert into public.movimentos_estoque (insumo_id, tipo, quantidade, pedido_id, motivo)
    select m.insumo_id, 'estorno_consumo', -m.quantidade, new.id, 'Estorno do pedido ' || new.codigo
    from public.movimentos_estoque m where m.pedido_id = new.id and m.tipo = 'consumo'
    on conflict do nothing;
  end if;
  return new;
end $$;
