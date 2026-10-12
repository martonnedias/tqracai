-- TQR Açaí · CRM: segmentos automáticos, funil, etiquetas, tarefas, anotações/contatos e mensagens prontas de WhatsApp
-- O envio é sempre manual (o painel só abre o WhatsApp com a mensagem pronta e registra o contato).

alter table public.clientes add column etiquetas text[] not null default '{}',
                            add column funil_manual text check (funil_manual in ('novo','recorrente','vip','em_risco','inativo')),
                            add column ultimo_contato timestamptz;

insert into public.configuracoes (chave, valor, descricao) values
 ('crm_vip_pedidos','5','Pedidos (não cancelados) para o cliente ser VIP'),
 ('crm_risco_dias','30','Dias sem pedir para o cliente ficar "em risco"'),
 ('crm_inativo_dias','60','Dias sem pedir para o cliente ficar "inativo"')
on conflict (chave) do nothing;

create table public.tarefas_crm (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.clientes(id) on delete cascade,
  titulo text not null check (length(trim(titulo)) >= 2 and length(titulo) <= 160),
  vence_em date not null default ((now() at time zone 'America/Fortaleza')::date),
  feita boolean not null default false,
  feita_em timestamptz,
  criado_em timestamptz not null default now(),
  criado_por uuid
);
create index tarefas_crm_idx on public.tarefas_crm (feita, vence_em);
create table public.interacoes_crm (
  id bigint generated always as identity primary key,
  cliente_id uuid not null references public.clientes(id) on delete cascade,
  tipo text not null check (tipo in ('nota','whatsapp','ligacao')),
  texto text check (length(texto) <= 500),
  criado_em timestamptz not null default now(),
  criado_por uuid
);
create index interacoes_crm_idx on public.interacoes_crm (cliente_id, criado_em desc);
create table public.mensagens_crm (
  id uuid primary key default gen_random_uuid(),
  nome text not null unique check (length(trim(nome)) >= 2 and length(nome) <= 60),
  texto text not null check (length(trim(texto)) >= 5 and length(texto) <= 600),
  ativo boolean not null default true,
  ordem int not null default 0
);
insert into public.mensagens_crm (nome, texto, ordem) values
 ('Sumiu? (sem pedir há um tempo)', 'Oi, {nome}! Aqui é da TQR Açaí 💜 Faz um tempinho que você não pede. Quer garantir suas garrafas geladas hoje?', 1),
 ('Parabéns pelo aniversário', 'Parabéns, {nome}! 🎂 A TQR Açaí tem um presente pra você neste mês: fala com a gente pra pegar o seu brinde de aniversário!', 2),
 ('Você tem pontos para resgatar', 'Oi, {nome}! Você já tem {pontos} pontos e pode trocar por {garrafas} garrafa(s) grátis. Quer resgatar? 💜', 3),
 ('Obrigado pelo pedido', 'Oi, {nome}! Obrigado por pedir na TQR Açaí 💜 Deu tudo certo com o seu pedido?', 4),
 ('Promoção da semana', 'Oi, {nome}! Tem promoção rolando na TQR Açaí. Posso te mandar os detalhes? 💜', 5);

alter table public.tarefas_crm enable row level security;
alter table public.interacoes_crm enable row level security;
alter table public.mensagens_crm enable row level security;
revoke all on public.tarefas_crm, public.interacoes_crm, public.mensagens_crm from anon, authenticated;
grant select, insert, update on public.tarefas_crm, public.mensagens_crm to authenticated;
grant select on public.interacoes_crm to authenticated;
create policy tcrm_sel on public.tarefas_crm for select to authenticated using ((select public.tem_permissao('clientes.ver')));
create policy tcrm_ins on public.tarefas_crm for insert to authenticated with check ((select public.tem_permissao('clientes.editar')));
create policy tcrm_upd on public.tarefas_crm for update to authenticated using ((select public.tem_permissao('clientes.editar'))) with check ((select public.tem_permissao('clientes.editar')));
create policy icrm_sel on public.interacoes_crm for select to authenticated using ((select public.tem_permissao('clientes.ver')));
create policy mcrm_sel on public.mensagens_crm for select to authenticated using ((select public.tem_permissao('clientes.ver')));
create policy mcrm_ins on public.mensagens_crm for insert to authenticated with check ((select public.tem_permissao('config.gerir')));
create policy mcrm_upd on public.mensagens_crm for update to authenticated using ((select public.tem_permissao('config.gerir'))) with check ((select public.tem_permissao('config.gerir')));

-- registra uma anotação ou contato (e marca o último contato do cliente)
create function public.crm_registrar(p_cliente uuid, p_tipo text, p_texto text default null) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.tem_permissao('clientes.editar') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if p_tipo not in ('nota','whatsapp','ligacao') then raise exception 'tipo_invalido' using errcode = '22023'; end if;
  perform 1 from public.clientes where id = p_cliente;
  if not found then raise exception 'cliente_inexistente' using errcode = '22023'; end if;
  insert into public.interacoes_crm (cliente_id, tipo, texto, criado_por) values (p_cliente, p_tipo, left(nullif(trim(p_texto), ''), 500), (select auth.uid()));
  if p_tipo <> 'nota' then update public.clientes set ultimo_contato = now() where id = p_cliente; end if;
end $$;

-- etiquetas e etapa manual do funil
create function public.crm_atualizar(p_cliente uuid, p_etiquetas text[] default null, p_funil text default null, p_limpar_funil boolean default false) returns void
language plpgsql security definer set search_path = '' as $$
declare et text[];
begin
  if not public.tem_permissao('clientes.editar') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if p_funil is not null and p_funil not in ('novo','recorrente','vip','em_risco','inativo') then raise exception 'funil_invalido' using errcode = '22023'; end if;
  if p_etiquetas is not null then
    select coalesce(array_agg(distinct left(lower(trim(x)), 24)), '{}') into et from unnest(p_etiquetas) x where length(trim(x)) > 0;
    if array_length(et, 1) > 10 then raise exception 'etiquetas_demais' using errcode = '22023'; end if;
  end if;
  update public.clientes set
    etiquetas = coalesce(et, etiquetas),
    funil_manual = case when p_limpar_funil then null when p_funil is not null then p_funil else funil_manual end
  where id = p_cliente;
  if not found then raise exception 'cliente_inexistente' using errcode = '22023'; end if;
end $$;

-- visão do CRM: um cliente por linha, com segmento automático
create function public.crm_clientes() returns table (
  id uuid, nome text, whatsapp text, data_nascimento date, etiquetas text[], funil_manual text, ultimo_contato timestamptz, criado_em timestamptz,
  total_pedidos bigint, ultimo_pedido timestamptz, primeiro_pedido timestamptz, pedidos_90d bigint, gasto_total numeric, ticket_medio numeric,
  saldo_pontos int, aniversario_mes boolean, segmento text, funil text)
language plpgsql stable security definer set search_path = '' as $$
declare vip int; risco int; inativo int; ver_fin boolean;
begin
  if not public.tem_permissao('clientes.ver') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  ver_fin := public.tem_permissao('financeiro.ver');
  select coalesce((select valor::int from public.configuracoes where chave = 'crm_vip_pedidos'), 5),
         coalesce((select valor::int from public.configuracoes where chave = 'crm_risco_dias'), 30),
         coalesce((select valor::int from public.configuracoes where chave = 'crm_inativo_dias'), 60) into vip, risco, inativo;
  return query
  with pe as (
    select p.cliente_id as cid, count(*) filter (where p.status <> 'cancelado') as n,
      max(p.criado_em) filter (where p.status <> 'cancelado') as ult, min(p.criado_em) filter (where p.status <> 'cancelado') as prim,
      count(*) filter (where p.status <> 'cancelado' and p.criado_em > now() - interval '90 days') as n90,
      coalesce(sum(p.total) filter (where p.status in ('pago','saiu_entrega','entregue')), 0) as gasto
    from public.pedidos p group by p.cliente_id),
  sp as (select l.cliente_id as cid, sum(l.pontos)::int as saldo from public.livro_pontos l group by l.cliente_id),
  base as (
    select c.*, coalesce(pe.n, 0) as n, pe.ult, pe.prim, coalesce(pe.n90, 0) as n90, coalesce(pe.gasto, 0) as gasto, coalesce(sp.saldo, 0) as saldo,
      case when coalesce(pe.n, 0) = 0 then 'sem_pedido'
           when pe.ult < now() - make_interval(days => inativo) then 'inativo'
           when pe.ult < now() - make_interval(days => risco) then 'em_risco'
           when pe.n >= vip then 'vip'
           when pe.n >= 2 then 'recorrente'
           else 'novo' end as seg
    from public.clientes c left join pe on pe.cid = c.id left join sp on sp.cid = c.id)
  select b.id, b.nome, b.whatsapp, b.data_nascimento, b.etiquetas, b.funil_manual, b.ultimo_contato, b.criado_em,
    b.n, b.ult, b.prim, b.n90, case when ver_fin then b.gasto end, case when ver_fin and b.n > 0 then round(b.gasto / b.n, 2) end,
    b.saldo, (b.data_nascimento is not null and extract(month from b.data_nascimento) = extract(month from (now() at time zone 'America/Fortaleza'))),
    b.seg, coalesce(b.funil_manual, case when b.seg = 'sem_pedido' then 'novo' else b.seg end)
  from base b order by b.ult desc nulls last, b.criado_em desc;
end $$;

revoke all on function public.crm_registrar(uuid,text,text), public.crm_atualizar(uuid,text[],text,boolean), public.crm_clientes() from public, anon, authenticated;
grant execute on function public.crm_registrar(uuid,text,text), public.crm_atualizar(uuid,text[],text,boolean), public.crm_clientes() to authenticated;
