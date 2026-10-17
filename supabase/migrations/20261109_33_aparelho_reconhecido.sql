-- TQR Açaí · acesso sem código manual: aparelho reconhecido + código de acesso do pedido.
-- 1) Ao fazer um pedido pelo site, o aparelho recebe uma chave secreta (180 dias) que abre pontos e endereços salvos sem pedir nada.
-- 2) Em outro aparelho, o cliente informa o WhatsApp + o código de acesso de um pedido dele (ex.: TQR-0027-K7F2), com limite de tentativas.
-- O envio manual de código (solicitar_codigo/verificar_codigo) deixa de ser usado pelo site e perde a permissão pública.

create function app_private.gera_chave() returns text
language sql volatile set search_path = '' as $$
  select string_agg(substr('23456789ABCDEFGHJKLMNPQRSTUVWXYZ', 1 + floor(random() * 32)::int, 1), '') from generate_series(1, 4) $$;

alter table public.pedidos
  add column chave_acesso text not null default app_private.gera_chave(),
  add column acesso_entregue boolean not null default false;
update public.pedidos set acesso_entregue = true;      -- pedidos antigos nunca viram acesso (o cliente não chegou a ver a chave)

create table public.tentativas_acesso (
  id bigint generated always as identity primary key,
  chave text not null,
  criado_em timestamptz not null default now()
);
create index tentativas_acesso_idx on public.tentativas_acesso (chave, criado_em);
alter table public.tentativas_acesso enable row level security;
revoke all on public.tentativas_acesso from anon, authenticated;

-- logo depois do pedido: entrega UMA vez a chave do aparelho e o código de acesso (só dentro de 5 minutos, só a quem fez o pedido)
create function public.registrar_aparelho(p_codigo text, p_whatsapp text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare ped public.pedidos; w text := public.normalizar_whatsapp(p_whatsapp); k text := 'r:' || public.normalizar_whatsapp(p_whatsapp); tok text;
begin
  if (select count(*) from public.tentativas_acesso where chave = k and criado_em > now() - interval '10 minutes') >= 20 then
    return jsonb_build_object('ok', false);
  end if;
  select p.* into ped from public.pedidos p join public.clientes c on c.id = p.cliente_id
   where p.codigo = upper(trim(coalesce(p_codigo, ''))) and c.whatsapp = w and p.origem = 'site'
     and not p.acesso_entregue and p.criado_em > now() - interval '5 minutes'
   for update of p;
  if not found then
    insert into public.tentativas_acesso (chave) values (k);
    return jsonb_build_object('ok', false);
  end if;
  update public.pedidos set acesso_entregue = true where id = ped.id;
  tok := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
  insert into public.sessoes_cliente (token_hash, cliente_id, expira_em)
  values (encode(sha256(convert_to(tok, 'UTF8')), 'hex'), ped.cliente_id, now() + interval '180 days');
  return jsonb_build_object('ok', true, 'token', tok, 'acesso', ped.codigo || '-' || ped.chave_acesso);
end $$;

-- aparelho novo: WhatsApp + código de acesso de um pedido do cliente. Devolve o token (90 dias) ou NULL se não confere.
create function public.entrar_com_codigo(p_whatsapp text, p_acesso text) returns text
language plpgsql security definer set search_path = '' as $$
declare w text := public.normalizar_whatsapp(p_whatsapp); k text := 'e:' || public.normalizar_whatsapp(p_whatsapp);
        a text := upper(regexp_replace(coalesce(p_acesso, ''), '[^A-Za-z0-9]', '', 'g')); cid uuid; tok text;
begin
  if (select count(*) from public.tentativas_acesso where chave = k and criado_em > now() - interval '30 minutes') >= 5
     or (select count(*) from public.tentativas_acesso where criado_em > now() - interval '10 minutes') >= 300 then
    raise exception 'muitas_tentativas' using errcode = 'P0001';
  end if;
  select c.id into cid from public.pedidos p join public.clientes c on c.id = p.cliente_id
   where c.whatsapp = w and p.origem = 'site' and replace(p.codigo, '-', '') || p.chave_acesso = a limit 1;
  if cid is null then
    insert into public.tentativas_acesso (chave) values (k);     -- sem exceção: ela desfaria a contagem
    return null;
  end if;
  tok := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
  insert into public.sessoes_cliente (token_hash, cliente_id, expira_em)
  values (encode(sha256(convert_to(tok, 'UTF8')), 'hex'), cid, now() + interval '90 days');
  return tok;
end $$;

revoke all on function public.registrar_aparelho(text, text), public.entrar_com_codigo(text, text), app_private.gera_chave() from public, anon, authenticated;
grant execute on function public.registrar_aparelho(text, text), public.entrar_com_codigo(text, text) to anon, authenticated;
-- o envio manual de código sai de cena
revoke execute on function public.solicitar_codigo(text), public.verificar_codigo(text, text) from anon, authenticated;
