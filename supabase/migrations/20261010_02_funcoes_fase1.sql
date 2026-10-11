-- TQR Açaí · Fase 1 · funções, views e permissões
-- (igual ao que foi aplicado no Supabase pela migração "funcoes_fase1")

create function public.normalizar_whatsapp(p text) returns text
language plpgsql immutable set search_path = '' as $$
declare d text := regexp_replace(coalesce(p, ''), '[^0-9]', '', 'g');
begin
  if d ~ '^55[0-9]{10,11}$' and length(d) in (12, 13) then return d; end if;
  if length(d) in (10, 11) then return '55' || d; end if;
  raise exception 'whatsapp_invalido' using errcode = '22023';
end $$;

create function public.calcular_total(p_qtd int) returns numeric
language plpgsql stable security definer set search_path = '' as $$
declare un numeric; c3 numeric; m5 numeric;
begin
  if p_qtd is null or p_qtd < 1 then
    raise exception 'quantidade_invalida' using errcode = '22023';
  end if;
  select valor::numeric into un from public.configuracoes where chave = 'preco_unitario';
  select valor::numeric into c3 from public.configuracoes where chave = 'preco_combo3';
  select valor::numeric into m5 from public.configuracoes where chave = 'preco_5mais';
  if p_qtd >= 5 then return round(p_qtd * m5, 2);
  elsif p_qtd >= 3 then return round(c3 + (p_qtd - 3) * un, 2);
  else return round(p_qtd * un, 2);
  end if;
end $$;

create function app_private.criar_pedido_interno(
  p_whatsapp text, p_qtd int, p_nome text, p_nasc date, p_email text, p_aceite boolean,
  p_forma text, p_endereco text, p_bairro text, p_obs text, p_origem text)
returns table (pedido_codigo text, pedido_total numeric)
language plpgsql security definer set search_path = '' as $$
declare
  w text; cid uuid; ped_id uuid; cod text; tot numeric; prod uuid;
  forma public.forma_pagamento;
begin
  w := public.normalizar_whatsapp(p_whatsapp);
  if p_qtd is null or p_qtd < 1 or p_qtd > 100 then
    raise exception 'quantidade_invalida' using errcode = '22023';
  end if;
  if p_forma is not null and p_forma not in ('pix', 'cartao') then
    raise exception 'pagamento_invalido' using errcode = '22023';
  end if;
  forma := p_forma::public.forma_pagamento;
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
  select id into prod from public.produtos where ativo order by criado_em limit 1;

  insert into public.pedidos (codigo, cliente_id, total, forma_pagamento, endereco, bairro, observacao, origem)
  values (cod, cid, tot, forma, nullif(trim(p_endereco), ''), nullif(trim(p_bairro), ''),
          nullif(trim(p_obs), ''), p_origem)
  returning id into ped_id;

  insert into public.itens_pedido (pedido_id, produto_id, quantidade, subtotal)
  values (ped_id, prod, p_qtd, tot);

  return query select cod, tot;
end $$;

create function public.criar_pedido(
  p_whatsapp text, p_quantidade int, p_nome text default null,
  p_data_nascimento date default null, p_email text default null,
  p_aceite_lgpd boolean default false, p_forma_pagamento text default null,
  p_endereco text default null, p_bairro text default null, p_observacao text default null)
returns table (pedido_codigo text, pedido_total numeric)
language sql security definer set search_path = '' as $$
  select * from app_private.criar_pedido_interno(
    p_whatsapp, p_quantidade, p_nome, p_data_nascimento, p_email, p_aceite_lgpd,
    p_forma_pagamento, p_endereco, p_bairro, p_observacao, 'site')
$$;

create function public.admin_criar_pedido(
  p_whatsapp text, p_quantidade int, p_nome text default null,
  p_forma_pagamento text default null, p_endereco text default null,
  p_bairro text default null, p_observacao text default null)
returns table (pedido_codigo text, pedido_total numeric)
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'nao_autorizado' using errcode = '42501';
  end if;
  return query select * from app_private.criar_pedido_interno(
    p_whatsapp, p_quantidade, p_nome, null, null, false,
    p_forma_pagamento, p_endereco, p_bairro, p_observacao, 'manual');
end $$;

create function public.cadastrar_cliente(
  p_whatsapp text, p_nome text, p_data_nascimento date, p_email text, p_aceite_lgpd boolean)
returns void
language plpgsql security definer set search_path = '' as $$
declare w text := public.normalizar_whatsapp(p_whatsapp);
begin
  if p_nome is null or length(trim(p_nome)) < 3 then
    raise exception 'nome_obrigatorio' using errcode = '22023';
  end if;
  if p_data_nascimento is null or p_data_nascimento > current_date or p_data_nascimento < date '1900-01-01' then
    raise exception 'nascimento_invalido' using errcode = '22023';
  end if;
  if p_email is null or length(trim(p_email)) = 0 then
    raise exception 'email_obrigatorio' using errcode = '22023';
  end if;
  if not coalesce(p_aceite_lgpd, false) then
    raise exception 'aceite_obrigatorio' using errcode = '22023';
  end if;
  insert into public.clientes (whatsapp, nome, data_nascimento, email, aceite_lgpd_em)
  values (w, trim(p_nome), p_data_nascimento, trim(p_email), now())
  on conflict (whatsapp) do update set
    data_nascimento = coalesce(public.clientes.data_nascimento, excluded.data_nascimento),
    email = coalesce(public.clientes.email, excluded.email),
    aceite_lgpd_em = coalesce(public.clientes.aceite_lgpd_em, excluded.aceite_lgpd_em);
end $$;

create function public.cliente_cadastrado(p_whatsapp text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.clientes where whatsapp = public.normalizar_whatsapp(p_whatsapp))
$$;

create view public.v_resumo_dia with (security_invoker = true) as
select (p.criado_em at time zone 'America/Fortaleza')::date as dia,
  count(*) filter (where p.status <> 'cancelado') as pedidos,
  coalesce(sum(g.garrafas) filter (where p.status <> 'cancelado'), 0)::int as garrafas,
  coalesce(sum(p.total) filter (where p.status in ('pago', 'saiu_entrega', 'entregue')), 0) as faturamento,
  coalesce(sum(p.total) filter (where p.status in ('pendente', 'confirmado')), 0) as a_receber
from public.pedidos p
left join (select pedido_id, sum(quantidade) as garrafas from public.itens_pedido group by pedido_id) g
  on g.pedido_id = p.id
group by 1;

create view public.v_clientes_resumo with (security_invoker = true) as
select c.id, c.nome, c.whatsapp, c.data_nascimento, c.criado_em,
  count(p.id) filter (where p.status <> 'cancelado') as total_pedidos,
  max(p.criado_em) filter (where p.status <> 'cancelado') as ultimo_pedido,
  coalesce(sum(p.total) filter (where p.status in ('pago', 'saiu_entrega', 'entregue')), 0) as gasto_total
from public.clientes c
left join public.pedidos p on p.cliente_id = c.id
group by c.id;

revoke all on function public.normalizar_whatsapp(text) from public, anon, authenticated;
revoke all on function public.calcular_total(int) from public, anon, authenticated;
revoke all on function app_private.criar_pedido_interno(text,int,text,date,text,boolean,text,text,text,text,text) from public, anon, authenticated;
revoke all on function public.criar_pedido(text,int,text,date,text,boolean,text,text,text,text) from public, anon, authenticated;
revoke all on function public.admin_criar_pedido(text,int,text,text,text,text,text) from public, anon, authenticated;
revoke all on function public.cadastrar_cliente(text,text,date,text,boolean) from public, anon, authenticated;
revoke all on function public.cliente_cadastrado(text) from public, anon, authenticated;
revoke all on public.v_resumo_dia, public.v_clientes_resumo from public, anon;

grant execute on function public.calcular_total(int) to anon, authenticated;
grant execute on function public.criar_pedido(text,int,text,date,text,boolean,text,text,text,text) to anon, authenticated;
grant execute on function public.cadastrar_cliente(text,text,date,text,boolean) to anon, authenticated;
grant execute on function public.cliente_cadastrado(text) to anon, authenticated;
grant execute on function public.admin_criar_pedido(text,int,text,text,text,text,text) to authenticated;
grant select on public.v_resumo_dia, public.v_clientes_resumo to authenticated;
