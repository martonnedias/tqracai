-- TQR Açaí · Fase 2 · programa de pontos e financeiro
-- Rodar depois da 06. Regras (HANDOFF 5.3):
--  * 1 ponto por R$ 1 pago (config pontos_por_real); 170 pontos = 1 garrafa grátis (pontos_por_brinde).
--  * Pontos e entrada no caixa nascem quando o pedido chega a "pago" (ou além), UMA vez por pedido (índices únicos).
--  * Cancelar um pedido pago gera estorno (lançamento negativo e pontos negativos) sem apagar as linhas originais.
--  * Saldo = soma das linhas do livro_pontos; nunca um número editado à mão. Resgate nunca deixa o saldo negativo.
--  * Brinde de aniversário: premissa adotada = pontos equivalentes a 1 garrafa (config aniversario_pontos), uma vez por ano, no mês do aniversário.

-- ===== permissão nova =====
update public.perfis set permissoes = permissoes || '{financeiro.gerir}'
 where id = 'gerente' and not ('financeiro.gerir' = any (permissoes));

-- ===== configurações novas =====
insert into public.configuracoes (chave, valor, descricao) values
 ('aniversario_pontos','170','Pontos do brinde de aniversário (1 garrafa por padrão)')
on conflict (chave) do nothing;

create or replace function app_private.validar_config() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.chave in ('preco_unitario','preco_combo3','preco_5mais','pontos_por_real','pontos_por_brinde','aniversario_pontos',
                   'contador_base','contador_ajuste','pedido_min','pedido_max')
     and new.valor !~ '^-?[0-9]+(\.[0-9]+)?$' then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave in ('preco_unitario','preco_combo3','preco_5mais','pedido_min','pedido_max','pontos_por_real','pontos_por_brinde','aniversario_pontos')
     and new.valor::numeric < 0 then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave in ('pontos_por_brinde') and new.valor::numeric < 1 then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave in ('horario_abre','horario_fecha') and new.valor !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave = 'aviso_ativo' and new.valor not in ('true','false') then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave in ('whatsapp_pedidos','whatsapp_loja') and new.valor !~ '^55[0-9]{10,11}$' then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  return new;
end $$;

-- ===== categorias financeiras =====
create table public.categorias_financeiras (
  id text primary key check (id ~ '^[a-z][a-z0-9_]{1,30}$'),
  nome text not null,
  tipo text not null check (tipo in ('entrada','saida')),
  fixa boolean not null default false,       -- despesa fixa (entra no ponto de equilíbrio)
  ativo boolean not null default true,
  ordem int not null default 0
);
insert into public.categorias_financeiras (id, nome, tipo, fixa, ordem) values
 ('vendas','Vendas','entrada',false,1),
 ('outras_entradas','Outras entradas','entrada',false,2),
 ('insumos','Insumos (açaí, polpas, complementos)','saida',false,10),
 ('embalagem','Embalagem (garrafas, tampas, rótulos)','saida',false,11),
 ('entrega','Entrega e combustível','saida',false,12),
 ('marketing','Marketing e anúncios','saida',false,13),
 ('impostos','Impostos e taxas','saida',false,14),
 ('pessoal','Pessoal','saida',true,20),
 ('aluguel','Aluguel','saida',true,21),
 ('energia_agua','Energia, água e internet','saida',true,22),
 ('outros','Outras despesas','saida',false,30);

-- ===== lançamentos =====
create table public.lancamentos (
  id uuid primary key default gen_random_uuid(),
  tipo text not null check (tipo in ('entrada','saida')),
  categoria_id text not null references public.categorias_financeiras(id),
  descricao text check (length(descricao) <= 200),
  valor numeric(12,2) not null,
  data date not null default ((now() at time zone 'America/Fortaleza')::date),
  vencimento date,
  pago boolean not null default true,
  pago_em date,
  forma_pagamento text references public.formas_pagamento(id),
  taxa numeric(12,2) not null default 0,           -- taxa da forma de pagamento sobre esta entrada
  origem text not null default 'manual' check (origem in ('manual','pedido','estorno_pedido')),
  pedido_id uuid references public.pedidos(id) on delete cascade,
  criado_em timestamptz not null default now(),
  criado_por uuid,
  check (valor <> 0),
  check (origem = 'estorno_pedido' or valor > 0)
);
create unique index lancamentos_entrada_pedido_uk on public.lancamentos (pedido_id) where origem = 'pedido';
create unique index lancamentos_estorno_pedido_uk on public.lancamentos (pedido_id) where origem = 'estorno_pedido';
create index lancamentos_data_idx on public.lancamentos (data desc);
create index lancamentos_pendentes_idx on public.lancamentos (vencimento) where not pago;

-- ===== livro de pontos =====
create table public.livro_pontos (
  id bigint generated always as identity primary key,
  cliente_id uuid not null references public.clientes(id) on delete cascade,
  pedido_id uuid references public.pedidos(id) on delete cascade,
  tipo text not null check (tipo in ('ganho','resgate','estorno','ajuste','aniversario')),
  pontos int not null check (pontos <> 0),
  motivo text check (length(motivo) <= 200),
  ano_ref int,                                      -- só para aniversario: uma vez por ano
  criado_em timestamptz not null default now(),
  criado_por uuid,
  check ((tipo in ('ganho','aniversario') and pontos > 0) or (tipo in ('resgate','estorno') and pontos < 0) or tipo = 'ajuste')
);
create unique index livro_ganho_pedido_uk on public.livro_pontos (pedido_id) where tipo = 'ganho';
create unique index livro_estorno_pedido_uk on public.livro_pontos (pedido_id) where tipo = 'estorno';
create unique index livro_aniversario_uk on public.livro_pontos (cliente_id, ano_ref) where tipo = 'aniversario';
create index livro_cliente_idx on public.livro_pontos (cliente_id, criado_em desc);

-- ===== o que acontece quando o status do pedido muda =====
create function app_private.lancar_pedido_pago(ped public.pedidos) returns void
language plpgsql security definer set search_path = '' as $$
declare f public.formas_pagamento; tx numeric := 0; pts int; ppr numeric; hoje date := (now() at time zone 'America/Fortaleza')::date;
begin
  if exists (select 1 from public.lancamentos where pedido_id = ped.id and origem = 'pedido') then return; end if;
  if ped.forma_pagamento is not null then
    select * into f from public.formas_pagamento where id = ped.forma_pagamento;
    if found then tx := round(ped.total * f.taxa_percentual / 100 + f.taxa_fixa, 2); end if;
  end if;
  insert into public.lancamentos (tipo, categoria_id, descricao, valor, data, pago, pago_em, forma_pagamento, taxa, origem, pedido_id)
  values ('entrada', 'vendas', 'Pedido ' || ped.codigo, ped.total, hoje, true, hoje, ped.forma_pagamento, tx, 'pedido', ped.id)
  on conflict do nothing;
  select valor::numeric into ppr from public.configuracoes where chave = 'pontos_por_real';
  pts := floor(ped.total * coalesce(ppr, 0))::int;
  if pts > 0 then
    insert into public.livro_pontos (cliente_id, pedido_id, tipo, pontos, motivo)
    values (ped.cliente_id, ped.id, 'ganho', pts, 'Pedido ' || ped.codigo) on conflict do nothing;
  end if;
end $$;

create function app_private.estornar_pedido(ped public.pedidos) returns void
language plpgsql security definer set search_path = '' as $$
declare e public.lancamentos; g public.livro_pontos; hoje date := (now() at time zone 'America/Fortaleza')::date;
begin
  select * into e from public.lancamentos where pedido_id = ped.id and origem = 'pedido';
  if not found then return; end if;
  insert into public.lancamentos (tipo, categoria_id, descricao, valor, data, pago, pago_em, forma_pagamento, taxa, origem, pedido_id)
  values ('entrada', 'vendas', 'Estorno do pedido ' || ped.codigo, -e.valor, hoje, true, hoje, e.forma_pagamento, -e.taxa, 'estorno_pedido', ped.id)
  on conflict do nothing;
  select * into g from public.livro_pontos where pedido_id = ped.id and tipo = 'ganho';
  if found then
    insert into public.livro_pontos (cliente_id, pedido_id, tipo, pontos, motivo)
    values (ped.cliente_id, ped.id, 'estorno', -g.pontos, 'Estorno do pedido ' || ped.codigo) on conflict do nothing;
  end if;
end $$;

create function app_private.pedido_financeiro() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.status is not distinct from old.status then return new; end if;
  if old.status = 'cancelado' then
    raise exception 'pedido_cancelado' using errcode = '22023';
  end if;
  if new.status in ('pago','saiu_entrega','entregue') then
    perform app_private.lancar_pedido_pago(new);
  elsif new.status = 'cancelado' then
    perform app_private.estornar_pedido(new);
  end if;
  return new;
end $$;
create trigger pedidos_financeiro after update of status on public.pedidos
  for each row execute function app_private.pedido_financeiro();

-- pedidos que já estavam pagos antes desta migração entram no caixa e nos pontos (idempotente)
select app_private.lancar_pedido_pago(p) from public.pedidos p where p.status in ('pago','saiu_entrega','entregue');

-- ===== saldo e funções do painel =====
create view public.v_saldo_pontos with (security_invoker = true) as
select c.id as cliente_id, coalesce(sum(l.pontos), 0)::int as saldo
from public.clientes c left join public.livro_pontos l on l.cliente_id = c.id
group by c.id;

create function app_private.saldo_cliente(p_cliente uuid) returns int
language sql stable security definer set search_path = '' as $$
  select coalesce(sum(pontos), 0)::int from public.livro_pontos where cliente_id = p_cliente
$$;

create function public.admin_resgatar_pontos(p_cliente uuid, p_garrafas int default 1) returns int
language plpgsql security definer set search_path = '' as $$
declare por_brinde int; custo int; saldo int;
begin
  if not public.tem_permissao('clientes.editar') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if p_garrafas is null or p_garrafas not between 1 and 20 then raise exception 'quantidade_invalida' using errcode = '22023'; end if;
  perform 1 from public.clientes where id = p_cliente for update;
  if not found then raise exception 'cliente_inexistente' using errcode = '22023'; end if;
  select valor::numeric::int into por_brinde from public.configuracoes where chave = 'pontos_por_brinde';
  custo := p_garrafas * coalesce(por_brinde, 170);
  saldo := app_private.saldo_cliente(p_cliente);
  if saldo < custo then raise exception 'saldo_insuficiente' using errcode = 'P0001'; end if;
  insert into public.livro_pontos (cliente_id, tipo, pontos, motivo, criado_por)
  values (p_cliente, 'resgate', -custo, 'Resgate de ' || p_garrafas || ' garrafa(s) grátis', (select auth.uid()));
  return saldo - custo;
end $$;

create function public.admin_ajustar_pontos(p_cliente uuid, p_pontos int, p_motivo text) returns int
language plpgsql security definer set search_path = '' as $$
declare saldo int;
begin
  if not public.tem_permissao('clientes.editar') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if p_pontos is null or p_pontos = 0 or abs(p_pontos) > 100000 then raise exception 'pontos_invalidos' using errcode = '22023'; end if;
  if p_motivo is null or length(trim(p_motivo)) < 3 then raise exception 'motivo_obrigatorio' using errcode = '22023'; end if;
  perform 1 from public.clientes where id = p_cliente for update;
  if not found then raise exception 'cliente_inexistente' using errcode = '22023'; end if;
  saldo := app_private.saldo_cliente(p_cliente);
  if saldo + p_pontos < 0 then raise exception 'saldo_insuficiente' using errcode = 'P0001'; end if;
  insert into public.livro_pontos (cliente_id, tipo, pontos, motivo, criado_por)
  values (p_cliente, 'ajuste', p_pontos, left(trim(p_motivo), 200), (select auth.uid()));
  return saldo + p_pontos;
end $$;

create function public.admin_conceder_aniversario(p_cliente uuid) returns int
language plpgsql security definer set search_path = '' as $$
declare nasc date; pts int; hoje date := (now() at time zone 'America/Fortaleza')::date;
begin
  if not public.tem_permissao('clientes.editar') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  perform 1 from public.clientes where id = p_cliente for update;
  select data_nascimento into nasc from public.clientes where id = p_cliente;
  if nasc is null then raise exception 'sem_data_nascimento' using errcode = '22023'; end if;
  if extract(month from nasc) <> extract(month from hoje) then raise exception 'fora_do_mes' using errcode = '22023'; end if;
  select valor::numeric::int into pts from public.configuracoes where chave = 'aniversario_pontos';
  if coalesce(pts, 0) <= 0 then raise exception 'brinde_desligado' using errcode = '22023'; end if;
  begin
    insert into public.livro_pontos (cliente_id, tipo, pontos, motivo, ano_ref, criado_por)
    values (p_cliente, 'aniversario', pts, 'Brinde de aniversário ' || extract(year from hoje)::int, extract(year from hoje)::int, (select auth.uid()));
  exception when unique_violation then
    raise exception 'ja_concedido' using errcode = '22023';
  end;
  return app_private.saldo_cliente(p_cliente);
end $$;

-- consulta do cliente no site (exige o número confirmado por código; mesma sessão dos endereços)
create function public.consultar_saldo(p_whatsapp text, p_token text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare cid uuid := app_private.cliente_da_sessao(p_whatsapp, p_token); saldo int; por_brinde int; nasc date;
begin
  if cid is null then raise exception 'sessao_invalida' using errcode = '42501'; end if;
  saldo := app_private.saldo_cliente(cid);
  select valor::numeric::int into por_brinde from public.configuracoes where chave = 'pontos_por_brinde';
  por_brinde := coalesce(por_brinde, 170);
  select data_nascimento into nasc from public.clientes where id = cid;
  return jsonb_build_object(
    'saldo', saldo, 'por_brinde', por_brinde, 'garrafas_gratis', greatest(saldo, 0) / por_brinde,
    'faltam', case when saldo >= por_brinde then 0 else por_brinde - greatest(saldo, 0) % por_brinde end,
    'mes_aniversario', nasc is not null and extract(month from nasc) = extract(month from (now() at time zone 'America/Fortaleza')),
    'historico', coalesce((select jsonb_agg(jsonb_build_object('em', h.criado_em, 'tipo', h.tipo, 'pontos', h.pontos, 'motivo', h.motivo) order by h.criado_em desc)
                           from (select * from public.livro_pontos where cliente_id = cid order by criado_em desc limit 15) h), '[]'::jsonb));
end $$;

-- ===== visões do financeiro =====
create view public.v_fluxo_mensal with (security_invoker = true) as
select date_trunc('month', l.data)::date as mes,
  coalesce(sum(l.valor) filter (where l.tipo = 'entrada' and l.pago), 0) as entradas,
  coalesce(sum(l.taxa) filter (where l.tipo = 'entrada' and l.pago), 0) as taxas,
  coalesce(sum(l.valor) filter (where l.tipo = 'saida' and l.pago), 0) as saidas,
  coalesce(sum(l.valor) filter (where l.tipo = 'entrada' and not l.pago), 0) as a_receber,
  coalesce(sum(l.valor) filter (where l.tipo = 'saida' and not l.pago), 0) as a_pagar,
  coalesce(sum(l.valor) filter (where l.tipo = 'entrada' and l.pago), 0)
    - coalesce(sum(l.taxa) filter (where l.tipo = 'entrada' and l.pago), 0)
    - coalesce(sum(l.valor) filter (where l.tipo = 'saida' and l.pago), 0) as resultado,
  coalesce(sum(l.valor) filter (where l.tipo = 'saida' and l.pago and c.fixa), 0) as despesas_fixas
from public.lancamentos l join public.categorias_financeiras c on c.id = l.categoria_id
group by 1;

-- garrafas vendidas por mês (pedidos com entrada no caixa e sem estorno), para margem e ponto de equilíbrio
create view public.v_garrafas_mes with (security_invoker = true) as
select date_trunc('month', l.data)::date as mes, coalesce(sum(i.quantidade) filter (where not i.brinde), 0)::int as garrafas
from public.lancamentos l
join public.itens_pedido i on i.pedido_id = l.pedido_id
where l.origem = 'pedido'
  and not exists (select 1 from public.lancamentos e where e.pedido_id = l.pedido_id and e.origem = 'estorno_pedido')
group by 1;

-- ===== permissões (RLS) =====
alter table public.categorias_financeiras enable row level security;
alter table public.lancamentos enable row level security;
alter table public.livro_pontos enable row level security;
revoke all on public.categorias_financeiras, public.lancamentos, public.livro_pontos from anon;
revoke insert, update, delete on public.livro_pontos from authenticated;      -- só pelas funções acima

create policy catfin_sel on public.categorias_financeiras for select to authenticated using ((select public.tem_permissao('financeiro.ver')));
create policy catfin_ins on public.categorias_financeiras for insert to authenticated with check ((select public.tem_permissao('financeiro.gerir')));
create policy catfin_upd on public.categorias_financeiras for update to authenticated
  using ((select public.tem_permissao('financeiro.gerir'))) with check ((select public.tem_permissao('financeiro.gerir')));

create policy lanc_sel on public.lancamentos for select to authenticated using ((select public.tem_permissao('financeiro.ver')));
create policy lanc_ins on public.lancamentos for insert to authenticated
  with check ((select public.tem_permissao('financeiro.gerir')) and origem = 'manual');
create policy lanc_upd on public.lancamentos for update to authenticated
  using ((select public.tem_permissao('financeiro.gerir')) and origem = 'manual')
  with check ((select public.tem_permissao('financeiro.gerir')) and origem = 'manual');
create policy lanc_del on public.lancamentos for delete to authenticated
  using ((select public.tem_permissao('financeiro.gerir')) and origem = 'manual');

create policy livro_sel on public.livro_pontos for select to authenticated using ((select public.tem_permissao('clientes.ver')));

revoke all on function app_private.lancar_pedido_pago(public.pedidos), app_private.estornar_pedido(public.pedidos),
  app_private.saldo_cliente(uuid) from public, anon, authenticated;
revoke all on function public.admin_resgatar_pontos(uuid,int), public.admin_ajustar_pontos(uuid,int,text),
  public.admin_conceder_aniversario(uuid), public.consultar_saldo(text,text) from public, anon, authenticated;
grant execute on function public.admin_resgatar_pontos(uuid,int), public.admin_ajustar_pontos(uuid,int,text),
  public.admin_conceder_aniversario(uuid) to authenticated;
grant execute on function public.consultar_saldo(text,text) to anon, authenticated;
revoke all on public.v_saldo_pontos, public.v_fluxo_mensal, public.v_garrafas_mes from public, anon;
grant select on public.v_saldo_pontos, public.v_fluxo_mensal, public.v_garrafas_mes to authenticated;
