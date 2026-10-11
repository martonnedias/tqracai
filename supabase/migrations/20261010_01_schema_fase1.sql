-- TQR Açaí · Fase 1 · estrutura (tabelas, RLS, auditoria de status)
create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;

create type public.pedido_status as enum
  ('pendente','confirmado','pago','saiu_entrega','entregue','cancelado');
create type public.forma_pagamento as enum ('pix','cartao');

create table public.configuracoes (
  chave text primary key,
  valor text not null,
  descricao text
);
insert into public.configuracoes (chave, valor, descricao) values
  ('preco_unitario','16.99','Preço de 1 unidade (R$)'),
  ('preco_combo3','42.00','Preço do combo de 3 (R$)'),
  ('preco_5mais','14.00','Preço por unidade a partir de 5 (R$)'),
  ('pontos_por_real','1','Pontos por R$ 1 pago (fase 2)'),
  ('pontos_por_brinde','170','Pontos para uma garrafa grátis (fase 2)'),
  ('whatsapp_loja','5586995884770','WhatsApp da loja, só dígitos com DDI');

create table public.produtos (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  volume_ml int,
  ativo boolean not null default true,
  criado_em timestamptz not null default now()
);
insert into public.produtos (nome, volume_ml) values ('Açaí tradicional 300 ml', 300);

create table public.clientes (
  id uuid primary key default gen_random_uuid(),
  whatsapp text not null unique check (whatsapp ~ '^55[0-9]{10,11}$'),
  nome text not null check (length(trim(nome)) >= 3),
  data_nascimento date check (data_nascimento >= date '1900-01-01'),
  email text check (email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
  aceite_lgpd_em timestamptz,
  observacoes text,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

create sequence public.pedido_codigo_seq start 1;

create table public.pedidos (
  id uuid primary key default gen_random_uuid(),
  codigo text not null unique,
  cliente_id uuid not null references public.clientes(id) on delete restrict,
  status public.pedido_status not null default 'pendente',
  total numeric(10,2) not null check (total >= 0),
  forma_pagamento public.forma_pagamento,
  endereco text,
  bairro text,
  observacao text,
  origem text not null default 'site' check (origem in ('site','manual')),
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);
create index pedidos_status_idx on public.pedidos (status, criado_em desc);
create index pedidos_cliente_idx on public.pedidos (cliente_id, criado_em desc);

create table public.itens_pedido (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references public.pedidos(id) on delete cascade,
  produto_id uuid not null references public.produtos(id),
  quantidade int not null check (quantidade > 0),
  subtotal numeric(10,2) not null check (subtotal >= 0),
  custo_unitario numeric(10,4)
);
create index itens_pedido_pedido_idx on public.itens_pedido (pedido_id);
create index itens_pedido_produto_idx on public.itens_pedido (produto_id);

create table public.pedido_eventos (
  id bigint generated always as identity primary key,
  pedido_id uuid not null references public.pedidos(id) on delete cascade,
  status public.pedido_status not null,
  em timestamptz not null default now()
);
create index pedido_eventos_pedido_idx on public.pedido_eventos (pedido_id, em);

create table public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- atualizado_em e histórico de status
create function app_private.touch() returns trigger
language plpgsql set search_path = '' as $$
begin new.atualizado_em := now(); return new; end $$;

create trigger clientes_touch before update on public.clientes
  for each row execute function app_private.touch();
create trigger pedidos_touch before update on public.pedidos
  for each row execute function app_private.touch();

create function app_private.registrar_evento() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' or new.status is distinct from old.status then
    insert into public.pedido_eventos (pedido_id, status) values (new.id, new.status);
  end if;
  return new;
end $$;

create trigger pedidos_evento after insert or update of status on public.pedidos
  for each row execute function app_private.registrar_evento();

-- quem é admin
create function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.admins where user_id = (select auth.uid()))
$$;
revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- RLS: tudo fechado; só admin autenticado lê e escreve
alter table public.configuracoes  enable row level security;
alter table public.produtos       enable row level security;
alter table public.clientes       enable row level security;
alter table public.pedidos        enable row level security;
alter table public.itens_pedido   enable row level security;
alter table public.pedido_eventos enable row level security;
alter table public.admins         enable row level security;

revoke all on all tables in schema public from anon;

create policy admin_all on public.configuracoes  for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_all on public.produtos       for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_all on public.clientes       for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_all on public.pedidos        for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_all on public.itens_pedido   for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_leitura on public.pedido_eventos for select to authenticated using ((select public.is_admin()));
create policy admin_proprio on public.admins for select to authenticated using (user_id = (select auth.uid()));
