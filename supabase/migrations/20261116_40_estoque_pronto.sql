-- Estoque de garrafas prontas para vender (produto acabado), por produto e, quando houver, por sabor.
-- * produtos.controla_pronto liga o controle. Com ele ligado, o site só vende o que existe no estoque.
-- * movimentos_pronto é o livro-razão: producao (+), perda (-), inventario (acerto), venda (-) e estorno_venda (+).
-- * A reserva é feita na criação do pedido (dentro da mesma transação, com trava) e devolvida se o pedido for cancelado.
-- * O estoque de insumos (ficha técnica) continua separado e não muda.
alter table public.produtos add column controla_pronto boolean not null default false;

create table public.movimentos_pronto (
  id uuid primary key default gen_random_uuid(),
  produto_id uuid not null references public.produtos(id),
  opcao_id uuid references public.opcoes(id) on delete set null,
  tipo text not null check (tipo in ('producao', 'perda', 'inventario', 'venda', 'estorno_venda')),
  quantidade int not null check (quantidade <> 0),
  pedido_id uuid references public.pedidos(id),
  motivo text,
  criado_por uuid default auth.uid(),
  criado_em timestamptz not null default now()
);
create index mov_pronto_idx on public.movimentos_pronto (produto_id, opcao_id, criado_em desc);
create index mov_pronto_pedido_idx on public.movimentos_pronto (pedido_id) where pedido_id is not null;
alter table public.movimentos_pronto enable row level security;
revoke all on public.movimentos_pronto from anon, authenticated;

-- lista de saldos (produto x sabor) dos produtos controlados
create function app_private.pronto_saldo_lista()
returns table (pid uuid, oid uuid, pnome text, onome text, saldo int)
language sql stable security definer set search_path = '' as $$
  select p.id, o.id, p.nome, o.nome,
         coalesce((select sum(m.quantidade) from public.movimentos_pronto m where m.produto_id = p.id and m.opcao_id is not distinct from o.id), 0)::int
  from public.produtos p
  left join lateral (
    select op.id, op.nome, op.ordem from public.grupos_opcao g join public.opcoes op on op.grupo_id = g.id
    where g.ativo and g.sabor and op.ativo and (g.produtos is null or p.id = any (g.produtos))
  ) o on true
  where p.controla_pronto and p.ativo
  order by p.ordem, p.nome, o.ordem
$$;
revoke all on function app_private.pronto_saldo_lista() from public, anon, authenticated;

-- quanto cada produto/sabor do pedido vai consumir
create function app_private.pronto_demanda(p_itens jsonb, p_snap jsonb)
returns table (pid uuid, oid uuid, qtd int)
language plpgsql stable security definer set search_path = '' as $$
declare r record; cob int;
begin
  for r in select (e->>'produto_id')::uuid as pid, sum((e->>'quantidade')::int)::int as q from jsonb_array_elements(p_itens) e group by 1 loop
    if not exists (select 1 from public.produtos where id = r.pid and controla_pronto) then continue; end if;
    if exists (select 1 from public.grupos_opcao g where g.ativo and g.sabor and (g.produtos is null or r.pid = any (g.produtos))) then
      select coalesce(sum((s->>'quantidade')::int), 0) into cob from jsonb_array_elements(coalesce(p_snap, '[]'::jsonb)) s where (s->>'produto_id')::uuid = r.pid;
      if cob < r.q then raise exception 'sabor_obrigatorio' using errcode = '22023'; end if;
      return query
        select r.pid, (op->>'id')::uuid, sum((s->>'quantidade')::int)::int
        from jsonb_array_elements(coalesce(p_snap, '[]'::jsonb)) s, jsonb_array_elements(s->'opcoes') op
        where (s->>'produto_id')::uuid = r.pid
          and exists (select 1 from public.opcoes o2 join public.grupos_opcao g2 on g2.id = o2.grupo_id where o2.id = (op->>'id')::uuid and g2.sabor)
        group by (op->>'id')::uuid;
    else
      return query select r.pid, null::uuid, r.q;
    end if;
  end loop;
end $$;
revoke all on function app_private.pronto_demanda(jsonb, jsonb) from public, anon, authenticated;

create function app_private.pronto_verificar(p_itens jsonb, p_snap jsonb) returns void
language plpgsql security definer set search_path = '' as $$
declare d record; saldo int; nome text;
begin
  for d in select * from app_private.pronto_demanda(p_itens, p_snap) loop
    perform pg_advisory_xact_lock(hashtextextended(d.pid::text || coalesce(d.oid::text, ''), 0));
    select coalesce(sum(quantidade), 0)::int into saldo from public.movimentos_pronto where produto_id = d.pid and opcao_id is not distinct from d.oid;
    if saldo < d.qtd then
      select p.nome || coalesce(' ' || o.nome, '') into nome from public.produtos p left join public.opcoes o on o.id = d.oid where p.id = d.pid;
      raise exception 'estoque_insuficiente:%:%', replace(nome, ':', ' '), greatest(saldo, 0) using errcode = '22023';
    end if;
  end loop;
end $$;
revoke all on function app_private.pronto_verificar(jsonb, jsonb) from public, anon, authenticated;

create function app_private.pronto_reservar(p_pedido uuid, p_itens jsonb, p_snap jsonb) returns void
language plpgsql security definer set search_path = '' as $$
declare d record;
begin
  for d in select * from app_private.pronto_demanda(p_itens, p_snap) loop
    insert into public.movimentos_pronto (produto_id, opcao_id, tipo, quantidade, pedido_id, motivo, criado_por)
    values (d.pid, d.oid, 'venda', -d.qtd, p_pedido, 'Pedido', null);
  end loop;
end $$;
revoke all on function app_private.pronto_reservar(uuid, jsonb, jsonb) from public, anon, authenticated;

-- pedido cancelado devolve as garrafas
create function app_private.pedido_pronto() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.status = 'cancelado' and old.status is distinct from 'cancelado' then
    insert into public.movimentos_pronto (produto_id, opcao_id, tipo, quantidade, pedido_id, motivo, criado_por)
    select produto_id, opcao_id, 'estorno_venda', -sum(quantidade), new.id, 'Pedido cancelado', null
    from public.movimentos_pronto where pedido_id = new.id and tipo in ('venda', 'estorno_venda')
    group by produto_id, opcao_id having sum(quantidade) < 0;
  end if;
  return new;
end $$;
create trigger pedidos_pronto after update of status on public.pedidos
  for each row execute function app_private.pedido_pronto();

-- o pedido (site ou painel) confere e reserva o estoque pronto
create or replace function app_private.criar_pedido_core(
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
  perform app_private.pronto_verificar(p_itens, c->'montagens');

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
  update public.itens_pedido i set custo_unitario = coalesce(i.custo_unitario, 0) + round(x.custo / i.quantidade, 4)
  from (select (s->>'produto_id')::uuid pid, sum((s->>'custo_unit')::numeric * (s->>'quantidade')::int) custo
        from jsonb_array_elements(c->'montagens') s group by 1) x
  where i.pedido_id = ped_id and i.produto_id = x.pid and not i.brinde and x.custo > 0;
  perform app_private.pronto_reservar(ped_id, p_itens, c->'montagens');

  return query select cod, round((m->>'total')::numeric + extras, 2), (m->>'desconto')::numeric, (m->>'taxa_entrega')::numeric, m->'promocao'->>'nome';
end $$;

-- ===== painel: ver saldos, registrar produção/perda/contagem, histórico =====
create function public.pronto_saldos() returns table (produto_id uuid, produto_nome text, opcao_id uuid, opcao_nome text, saldo int, vendido_hoje int)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.tem_permissao('estoque.ver') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  return query select s.pid, s.pnome, s.oid, s.onome, s.saldo,
    coalesce((select -sum(m.quantidade) from public.movimentos_pronto m
              where m.produto_id = s.pid and m.opcao_id is not distinct from s.oid and m.tipo = 'venda'
                and m.criado_em >= date_trunc('day', now() at time zone 'America/Fortaleza') at time zone 'America/Fortaleza'), 0)::int
  from app_private.pronto_saldo_lista() s;
end $$;

create function public.registrar_movimento_pronto(p_produto uuid, p_opcao uuid, p_tipo text, p_quantidade int, p_motivo text default null) returns int
language plpgsql security definer set search_path = '' as $$
declare saldo int; delta int;
begin
  if not public.tem_permissao('estoque.gerir') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if p_tipo not in ('producao', 'perda', 'inventario') or p_quantidade is null or p_quantidade < 0 or p_quantidade > 100000 then
    raise exception 'movimento_invalido' using errcode = '22023'; end if;
  if not exists (select 1 from public.produtos where id = p_produto and controla_pronto) then raise exception 'produto_sem_controle' using errcode = '22023'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_produto::text || coalesce(p_opcao::text, ''), 0));
  select coalesce(sum(quantidade), 0)::int into saldo from public.movimentos_pronto where produto_id = p_produto and opcao_id is not distinct from p_opcao;
  delta := case p_tipo when 'producao' then p_quantidade when 'perda' then -p_quantidade else p_quantidade - saldo end;
  if delta = 0 then return saldo; end if;
  if p_tipo = 'perda' and p_quantidade > saldo then raise exception 'saldo_insuficiente' using errcode = '22023'; end if;
  insert into public.movimentos_pronto (produto_id, opcao_id, tipo, quantidade, motivo)
  values (p_produto, p_opcao, p_tipo, delta, left(coalesce(nullif(trim(p_motivo), ''), case p_tipo when 'perda' then 'Perda' when 'inventario' then 'Contagem de estoque' else 'Produção' end), 120));
  return saldo + delta;
end $$;

create function public.pronto_historico(p_limite int default 30) returns table (criado_em timestamptz, produto_nome text, opcao_nome text, tipo text, quantidade int, motivo text)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.tem_permissao('estoque.ver') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  return query select m.criado_em, p.nome, o.nome, m.tipo, m.quantidade, m.motivo
  from public.movimentos_pronto m join public.produtos p on p.id = m.produto_id left join public.opcoes o on o.id = m.opcao_id
  order by m.criado_em desc limit least(greatest(coalesce(p_limite, 30), 1), 200);
end $$;

revoke all on function public.pronto_saldos(), public.registrar_movimento_pronto(uuid, uuid, text, int, text), public.pronto_historico(int) from public, anon;
grant execute on function public.pronto_saldos(), public.registrar_movimento_pronto(uuid, uuid, text, int, text), public.pronto_historico(int) to authenticated;

-- vitrine pública: acrescenta "estoque" (saldo por produto/sabor dos produtos controlados)
create or replace function public.obter_vitrine() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'estoque', coalesce((select jsonb_agg(jsonb_build_object('produto_id', x.pid, 'opcao_id', x.oid, 'qtd', greatest(x.saldo, 0))) from app_private.pronto_saldo_lista() x), '[]'::jsonb),
    'categorias', coalesce((select jsonb_agg(jsonb_build_object('id', c.id, 'nome', c.nome) order by c.ordem, c.criado_em)
                 from public.categorias_produto c where c.ativo), '[]'::jsonb),
    'produtos', coalesce((select jsonb_agg(jsonb_build_object('id', p.id, 'nome', p.nome, 'descricao', p.descricao, 'preco', p.preco,
                   'foto_url', p.foto_url, 'volume_ml', p.volume_ml, 'categoria', p.categoria, 'categoria_id', p.categoria_id, 'sugerir', p.sugerir_venda) order by p.ordem, p.criado_em)
                 from public.produtos p where p.ativo and p.preco is not null), '[]'::jsonb),
    'promocoes', coalesce((select jsonb_agg(jsonb_build_object('id', x.id, 'tipo', x.tipo, 'nome', x.nome, 'regra', x.regra, 'titulo', x.titulo,
                   'qtd_label', x.qtd_label, 'rotulo', x.rotulo, 'notas', x.notas, 'imagem_url', x.imagem_url, 'cta', x.cta,
                   'qtd_sugerida', x.qtd_sugerida, 'destaque', x.destaque, 'frete_gratis', x.frete_gratis or x.tipo = 'frete_gratis',
                   'min_qtd', x.min_qtd, 'min_valor', x.min_valor) order by x.ordem_site, x.criado_em)
                 from public.promocoes x
                 where x.ativo and x.publica and x.codigo is null
                   and (x.inicio is null or now() >= x.inicio) and (x.fim is null or now() < x.fim)
                   and (x.limite_usos is null or x.usos < x.limite_usos)), '[]'::jsonb),
    'personalizacao', coalesce((select jsonb_agg(jsonb_build_object('id', g.id, 'nome', g.nome, 'tipo', g.tipo, 'sabor', g.sabor, 'minimo', g.minimo, 'maximo', g.maximo,
                   'gratis_ate', g.gratis_ate, 'produtos', to_jsonb(g.produtos),
                   'opcoes', coalesce((select jsonb_agg(jsonb_build_object('id', o.id, 'nome', o.nome, 'preco', o.preco_adicional, 'esgotado', o.esgotado, 'foto_url', o.foto_url, 'descricao', o.descricao)
                                       order by o.ordem, o.criado_em) from public.opcoes o where o.grupo_id = g.id and o.ativo), '[]'::jsonb))
                   order by g.ordem, g.criado_em)
                 from public.grupos_opcao g where g.ativo
                   and exists (select 1 from public.opcoes o2 where o2.grupo_id = g.id and o2.ativo)), '[]'::jsonb))
$$;
grant execute on function public.obter_vitrine() to anon, authenticated;
