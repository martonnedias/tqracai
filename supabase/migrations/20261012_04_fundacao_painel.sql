-- TQR Açaí · Etapa 2 · fundação: perfis e permissões, formas de pagamento, bairros, configurações, contador
-- Rodar depois das migrações 01 a 03. O administrador atual vira "dono" (mantém acesso total).

-- ===== Perfis e permissões =====
create table public.perfis (
  id text primary key check (id ~ '^[a-z][a-z0-9_]{1,30}$'),
  nome text not null,
  descricao text,
  permissoes text[] not null default '{}',
  sistema boolean not null default false
);
-- Permissões: pedidos.ver, pedidos.criar, pedidos.status (confirmar/pago/saiu/entregue), pedidos.status_entrega (só saiu/entregue),
--   pedidos.cancelar, pedidos.editar, clientes.ver, clientes.editar, produtos.gerir, promocoes.gerir, config.gerir, financeiro.ver.
-- '*' = tudo (e é o que identifica o dono). Usuários e perfis só o dono gerencia.
insert into public.perfis (id, nome, descricao, permissoes, sistema) values
 ('dono','Dono','Acesso total, inclusive usuários e perfis','{*}',true),
 ('gerente','Gerente','Tudo, menos usuários e perfis',
   '{pedidos.ver,pedidos.criar,pedidos.status,pedidos.cancelar,pedidos.editar,clientes.ver,clientes.editar,produtos.gerir,promocoes.gerir,config.gerir,financeiro.ver}',true),
 ('atendente','Atendente','Pedidos e clientes, sem financeiro nem preços',
   '{pedidos.ver,pedidos.criar,pedidos.status,clientes.ver,clientes.editar}',true),
 ('entregador','Entregador','Vê pedidos e marca saiu para entrega e entregue',
   '{pedidos.ver,pedidos.status_entrega}',true);

alter table public.admins
  add column perfil_id text not null default 'dono' references public.perfis(id),
  add column nome text,
  add column ativo boolean not null default true,
  add column criado_em timestamptz not null default now();
create index admins_perfil_idx on public.admins (perfil_id);

-- usuário ativo do painel (qualquer perfil)
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.admins where user_id = (select auth.uid()) and ativo)
$$;

create function public.tem_permissao(p text) returns boolean
language sql stable security definer set search_path = '' as $$
  select public.is_admin() and exists (
    select 1 from public.admins a join public.perfis f on f.id = a.perfil_id
    where a.user_id = (select auth.uid()) and a.ativo and ('*' = any(f.permissoes) or p = any(f.permissoes)))
$$;

create function public.eh_dono() returns boolean
language sql stable security definer set search_path = '' as $$
  select public.is_admin() and exists (
    select 1 from public.admins a where a.user_id = (select auth.uid()) and a.perfil_id = 'dono')
$$;

create function public.minhas_permissoes() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce((select jsonb_build_object('perfil', a.perfil_id, 'nome', coalesce(a.nome, ''),
                    'permissoes', to_jsonb(f.permissoes))
                   from public.admins a join public.perfis f on f.id = a.perfil_id
                   where a.user_id = (select auth.uid()) and a.ativo), 'null'::jsonb)
$$;

revoke all on function public.is_admin(), public.tem_permissao(text), public.eh_dono(), public.minhas_permissoes() from public, anon;
grant execute on function public.is_admin(), public.tem_permissao(text), public.eh_dono(), public.minhas_permissoes() to authenticated;

-- ===== Formas de pagamento =====
create table public.formas_pagamento (
  id text primary key check (id ~ '^[a-z][a-z0-9_]{1,30}$'),
  nome text not null,
  ativo boolean not null default true,
  ordem int not null default 0,
  taxa_percentual numeric(5,2) not null default 0 check (taxa_percentual between 0 and 100),
  taxa_fixa numeric(10,2) not null default 0 check (taxa_fixa >= 0),
  instrucoes text
);
insert into public.formas_pagamento (id, nome, ordem, instrucoes) values
 ('pix','Pix',1,'Os dados do Pix são enviados no WhatsApp.'),
 ('cartao','Cartão',2,'Pagamento na entrega ou link enviado no WhatsApp.');

-- pedido passa a aceitar qualquer forma cadastrada (antes era enum fixo)
alter table public.pedidos alter column forma_pagamento type text using forma_pagamento::text;
alter table public.pedidos add constraint pedidos_forma_fk foreign key (forma_pagamento) references public.formas_pagamento(id);

-- ===== Bairros de entrega =====
create table public.bairros_entrega (
  id uuid primary key default gen_random_uuid(),
  nome text not null unique check (length(trim(nome)) >= 2),
  taxa numeric(10,2) not null default 0 check (taxa >= 0),
  ativo boolean not null default true,
  ordem int not null default 0
);

-- ===== Configurações novas =====
-- ATENÇÃO: 'whatsapp_pedidos' nasce igual ao número que o site usa hoje (window.TQR_FONE, número de teste).
-- Para voltar ao número original da loja, troque no painel (Configurações).
insert into public.configuracoes (chave, valor, descricao) values
 ('whatsapp_pedidos','5586994144709','WhatsApp que recebe os pedidos do site (só dígitos, com 55)'),
 ('contador_base','1000','Garrafas já vendidas antes do sistema (base do contador do site)'),
 ('contador_ajuste','0','Ajuste manual somado ao contador do site (pode ser negativo)'),
 ('horario_abre','08:00','Início do atendimento (HH:MM)'),
 ('horario_fecha','02:00','Fim do atendimento (HH:MM, pode passar da meia-noite)'),
 ('aviso_ativo','false','Mostrar o aviso no topo do site (true/false)'),
 ('aviso_site','','Texto do aviso no topo do site'),
 ('pedido_min','1','Mínimo de garrafas por pedido'),
 ('pedido_max','99','Máximo de garrafas por pedido')
on conflict (chave) do nothing;

create function app_private.validar_config() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.chave in ('preco_unitario','preco_combo3','preco_5mais','pontos_por_real','pontos_por_brinde',
                   'contador_base','contador_ajuste','pedido_min','pedido_max')
     and new.valor !~ '^-?[0-9]+(\.[0-9]+)?$' then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave in ('preco_unitario','preco_combo3','preco_5mais','pedido_min','pedido_max')
     and new.valor::numeric < 0 then
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
create trigger configuracoes_valida before insert or update on public.configuracoes
  for each row execute function app_private.validar_config();

-- ===== Produtos: colunas para a vitrine =====
alter table public.produtos
  add column descricao text,
  add column preco numeric(10,2) check (preco >= 0),
  add column foto_url text,
  add column ordem int not null default 0,
  add column categoria text;
update public.produtos set preco = (select valor::numeric from public.configuracoes where chave = 'preco_unitario')
 where preco is null;

-- ===== Leitura pública para o site =====
create function public.obter_contador() returns int
language sql stable security definer set search_path = '' as $$
  select greatest(0,
    (select valor::numeric from public.configuracoes where chave = 'contador_base')::int
    + (select valor::numeric from public.configuracoes where chave = 'contador_ajuste')::int
    + coalesce((select sum(i.quantidade) from public.itens_pedido i
                join public.pedidos p on p.id = i.pedido_id
                where p.status in ('pago','saiu_entrega','entregue')), 0)::int)
$$;

create function public.obter_config_publica() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'whatsapp',  (select valor from public.configuracoes where chave = 'whatsapp_pedidos'),
    'horario_abre',  (select valor from public.configuracoes where chave = 'horario_abre'),
    'horario_fecha', (select valor from public.configuracoes where chave = 'horario_fecha'),
    'aviso', case when (select valor from public.configuracoes where chave = 'aviso_ativo') = 'true'
                  then nullif(trim((select valor from public.configuracoes where chave = 'aviso_site')), '') end,
    'pedido_min', (select valor::int from public.configuracoes where chave = 'pedido_min'),
    'pedido_max', (select valor::int from public.configuracoes where chave = 'pedido_max'),
    'contador', public.obter_contador(),
    'formas_pagamento', coalesce((select jsonb_agg(jsonb_build_object('id', f.id, 'nome', f.nome, 'instrucoes', f.instrucoes) order by f.ordem, f.nome)
                                  from public.formas_pagamento f where f.ativo), '[]'::jsonb),
    'bairros', coalesce((select jsonb_agg(jsonb_build_object('id', b.id, 'nome', b.nome, 'taxa', b.taxa) order by b.ordem, b.nome)
                         from public.bairros_entrega b where b.ativo), '[]'::jsonb))
$$;

revoke all on function public.obter_contador(), public.obter_config_publica() from public, anon, authenticated;
grant execute on function public.obter_contador(), public.obter_config_publica() to anon, authenticated;

-- ===== RLS por permissão (substitui as políticas "admin_all") =====
drop policy admin_all on public.configuracoes;
drop policy admin_all on public.produtos;
drop policy admin_all on public.clientes;
drop policy admin_all on public.pedidos;
drop policy admin_all on public.itens_pedido;
drop policy admin_leitura on public.pedido_eventos;
drop policy admin_proprio on public.admins;

alter table public.perfis enable row level security;
alter table public.formas_pagamento enable row level security;
alter table public.bairros_entrega enable row level security;
revoke all on public.perfis, public.formas_pagamento, public.bairros_entrega from anon;

-- configurações: leitura para quem gere config ou produtos; escrita só config
create policy cfg_sel on public.configuracoes for select to authenticated
  using ((select public.tem_permissao('config.gerir')) or (select public.tem_permissao('produtos.gerir')) or (select public.tem_permissao('promocoes.gerir')));
create policy cfg_ins on public.configuracoes for insert to authenticated with check ((select public.tem_permissao('config.gerir')));
create policy cfg_upd on public.configuracoes for update to authenticated
  using ((select public.tem_permissao('config.gerir'))) with check ((select public.tem_permissao('config.gerir')));

create policy prod_sel on public.produtos for select to authenticated using ((select public.is_admin()));
create policy prod_ins on public.produtos for insert to authenticated with check ((select public.tem_permissao('produtos.gerir')));
create policy prod_upd on public.produtos for update to authenticated
  using ((select public.tem_permissao('produtos.gerir'))) with check ((select public.tem_permissao('produtos.gerir')));
create policy prod_del on public.produtos for delete to authenticated using ((select public.tem_permissao('produtos.gerir')));

create policy fp_sel on public.formas_pagamento for select to authenticated using ((select public.is_admin()));
create policy fp_ins on public.formas_pagamento for insert to authenticated with check ((select public.tem_permissao('config.gerir')));
create policy fp_upd on public.formas_pagamento for update to authenticated
  using ((select public.tem_permissao('config.gerir'))) with check ((select public.tem_permissao('config.gerir')));
create policy fp_del on public.formas_pagamento for delete to authenticated using ((select public.tem_permissao('config.gerir')));

create policy bairro_sel on public.bairros_entrega for select to authenticated using ((select public.is_admin()));
create policy bairro_ins on public.bairros_entrega for insert to authenticated with check ((select public.tem_permissao('config.gerir')));
create policy bairro_upd on public.bairros_entrega for update to authenticated
  using ((select public.tem_permissao('config.gerir'))) with check ((select public.tem_permissao('config.gerir')));
create policy bairro_del on public.bairros_entrega for delete to authenticated using ((select public.tem_permissao('config.gerir')));

-- clientes: quem vê pedidos precisa ver o cliente do pedido
create policy cli_sel on public.clientes for select to authenticated
  using ((select public.tem_permissao('clientes.ver')) or (select public.tem_permissao('pedidos.ver')));
create policy cli_ins on public.clientes for insert to authenticated with check ((select public.tem_permissao('clientes.editar')));
create policy cli_upd on public.clientes for update to authenticated
  using ((select public.tem_permissao('clientes.editar'))) with check ((select public.tem_permissao('clientes.editar')));

-- pedidos: nunca apagados pelo painel; mudanças de status são conferidas no gatilho abaixo
create policy ped_sel on public.pedidos for select to authenticated using ((select public.tem_permissao('pedidos.ver')));
create policy ped_upd on public.pedidos for update to authenticated
  using ((select public.tem_permissao('pedidos.status')) or (select public.tem_permissao('pedidos.status_entrega'))
         or (select public.tem_permissao('pedidos.cancelar')) or (select public.tem_permissao('pedidos.editar')))
  with check (true);
create policy item_sel on public.itens_pedido for select to authenticated using ((select public.tem_permissao('pedidos.ver')));
create policy item_upd on public.itens_pedido for update to authenticated
  using ((select public.tem_permissao('pedidos.editar'))) with check ((select public.tem_permissao('pedidos.editar')));
create policy ev_sel on public.pedido_eventos for select to authenticated using ((select public.tem_permissao('pedidos.ver')));

-- usuários e perfis: leitura do próprio registro (ou tudo para o dono); escrita só pela função de borda (chave de serviço)
create policy adm_sel on public.admins for select to authenticated
  using (user_id = (select auth.uid()) or (select public.eh_dono()));
create policy perfil_sel on public.perfis for select to authenticated using ((select public.is_admin()));

-- gatilho: quem pode mudar o quê num pedido (ignorado para SQL Editor/funções internas, onde não há usuário logado)
create function app_private.guarda_pedido() returns trigger
language plpgsql security invoker set search_path = '' as $$
declare r public.pedidos;
begin
  if (select auth.uid()) is null then return new; end if;
  r := new; r.status := old.status; r.atualizado_em := old.atualizado_em; r.observacao := old.observacao;
  if r is distinct from old and not public.tem_permissao('pedidos.editar') then
    raise exception 'sem_permissao:editar' using errcode = '42501';
  end if;
  if new.status is distinct from old.status then
    if new.status = 'cancelado' then
      if not public.tem_permissao('pedidos.cancelar') then raise exception 'sem_permissao:cancelar' using errcode = '42501'; end if;
    elsif new.status in ('saiu_entrega','entregue') then
      if not (public.tem_permissao('pedidos.status') or public.tem_permissao('pedidos.status_entrega')) then
        raise exception 'sem_permissao:status' using errcode = '42501'; end if;
    else
      if not public.tem_permissao('pedidos.status') then raise exception 'sem_permissao:status' using errcode = '42501'; end if;
    end if;
  end if;
  if new.observacao is distinct from old.observacao and not public.tem_permissao('pedidos.editar') then
    raise exception 'sem_permissao:editar' using errcode = '42501';
  end if;
  return new;
end $$;
create trigger pedidos_guarda before update on public.pedidos
  for each row execute function app_private.guarda_pedido();

-- pedido manual passa a exigir a permissão pedidos.criar
create or replace function public.admin_criar_pedido(
  p_whatsapp text, p_quantidade int, p_nome text default null,
  p_forma_pagamento text default null, p_endereco text default null,
  p_bairro text default null, p_observacao text default null)
returns table (pedido_codigo text, pedido_total numeric)
language plpgsql security definer set search_path = '' as $$
begin
  if not public.tem_permissao('pedidos.criar') then
    raise exception 'nao_autorizado' using errcode = '42501';
  end if;
  return query select * from app_private.criar_pedido_interno(
    p_whatsapp, p_quantidade, p_nome, null, null, false,
    p_forma_pagamento, p_endereco, p_bairro, p_observacao, 'manual');
end $$;

-- criar_pedido_interno usava o enum antigo: agora a forma vem de formas_pagamento
create or replace function app_private.criar_pedido_interno(
  p_whatsapp text, p_qtd int, p_nome text, p_nasc date, p_email text, p_aceite boolean,
  p_forma text, p_endereco text, p_bairro text, p_obs text, p_origem text)
returns table (pedido_codigo text, pedido_total numeric)
language plpgsql security definer set search_path = '' as $$
declare
  w text; cid uuid; ped_id uuid; cod text; tot numeric; prod uuid; forma text;
begin
  w := public.normalizar_whatsapp(p_whatsapp);
  if p_qtd is null or p_qtd < 1 or p_qtd > 100 then
    raise exception 'quantidade_invalida' using errcode = '22023';
  end if;
  forma := nullif(trim(p_forma), '');
  if forma is not null and not exists (select 1 from public.formas_pagamento where id = forma and ativo) then
    raise exception 'pagamento_invalido' using errcode = '22023';
  end if;
  if p_nasc is not null and (p_nasc > current_date or p_nasc < date '1900-01-01') then
    raise exception 'nascimento_invalido' using errcode = '22023';
  end if;

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

  tot := public.calcular_total(p_qtd);
  cod := 'TQR-' || lpad(nextval('public.pedido_codigo_seq')::text, 4, '0');
  select id into prod from public.produtos where ativo order by ordem, criado_em limit 1;

  insert into public.pedidos (codigo, cliente_id, total, forma_pagamento, endereco, bairro, observacao, origem)
  values (cod, cid, tot, forma, nullif(trim(p_endereco), ''), nullif(trim(p_bairro), ''),
          nullif(trim(p_obs), ''), p_origem)
  returning id into ped_id;

  insert into public.itens_pedido (pedido_id, produto_id, quantidade, subtotal)
  values (ped_id, prod, p_qtd, tot);

  return query select cod, tot;
end $$;

-- visões: valores só para quem tem financeiro.ver
create or replace view public.v_resumo_dia with (security_invoker = true) as
select (p.criado_em at time zone 'America/Fortaleza')::date as dia,
  count(*) filter (where p.status <> 'cancelado') as pedidos,
  coalesce(sum(g.garrafas) filter (where p.status <> 'cancelado'), 0)::int as garrafas,
  case when public.tem_permissao('financeiro.ver') then
    coalesce(sum(p.total) filter (where p.status in ('pago', 'saiu_entrega', 'entregue')), 0) end as faturamento,
  case when public.tem_permissao('financeiro.ver') then
    coalesce(sum(p.total) filter (where p.status in ('pendente', 'confirmado')), 0) end as a_receber
from public.pedidos p
left join (select pedido_id, sum(quantidade) as garrafas from public.itens_pedido group by pedido_id) g
  on g.pedido_id = p.id
group by 1;

create or replace view public.v_clientes_resumo with (security_invoker = true) as
select c.id, c.nome, c.whatsapp, c.data_nascimento, c.criado_em,
  count(p.id) filter (where p.status <> 'cancelado') as total_pedidos,
  max(p.criado_em) filter (where p.status <> 'cancelado') as ultimo_pedido,
  case when public.tem_permissao('financeiro.ver') then
    coalesce(sum(p.total) filter (where p.status in ('pago', 'saiu_entrega', 'entregue')), 0) end as gasto_total
from public.clientes c
left join public.pedidos p on p.cliente_id = c.id
group by c.id;
