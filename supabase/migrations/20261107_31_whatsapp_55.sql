-- TQR Açaí · corrige a busca do pedido pelo WhatsApp: o cliente digita sem o 55 e o banco guarda com 55.
create or replace function public.pagamento_publico(p_codigo text, p_whatsapp text, p_criar boolean default true) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare ped public.pedidos; pg public.pagamentos; gw text := app_private.gateway_ativo();
begin
  select p.* into ped from public.pedidos p join public.clientes c on c.id = p.cliente_id
    where p.codigo = upper(trim(coalesce(p_codigo, ''))) and c.whatsapp = (case when length(regexp_replace(coalesce(p_whatsapp, ''), '\D', '', 'g')) <= 11 then '55' else '' end) || regexp_replace(coalesce(p_whatsapp, ''), '\D', '', 'g');
  if not found then return jsonb_build_object('disponivel', false); end if;
  if gw = 'nenhum' then return jsonb_build_object('disponivel', false, 'gateway', gw); end if;
  if gw = 'teste' and p_criar and ped.status = 'pendente' and ped.forma_pagamento = 'pix' then
    perform app_private.pagamento_teste_criar(ped.id, 'pix');
  end if;
  select * into pg from public.pagamentos where pedido_id = ped.id order by criado_em desc limit 1;
  if not found then return jsonb_build_object('disponivel', gw <> 'teste', 'gateway', gw, 'pedido_status', ped.status); end if;
  if pg.status = 'pendente' and pg.expira_em < now() then
    update public.pagamentos set status = 'expirado', atualizado_em = now() where id = pg.id;
    pg.status := 'expirado';
  end if;
  return jsonb_build_object('disponivel', true, 'gateway', gw, 'status', pg.status, 'pedido_status', ped.status,
    'valor', pg.valor, 'pix_copia_cola', pg.pix_copia_cola, 'pix_qr', pg.pix_qr, 'link', pg.link_pagamento,
    'expira_em', pg.expira_em, 'teste', pg.gateway = 'teste');
end $$;

create or replace function public.acompanhar_pedido(p_codigo text, p_whatsapp text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare ped public.pedidos;
begin
  select p.* into ped from public.pedidos p join public.clientes c on c.id = p.cliente_id
    where p.codigo = upper(trim(coalesce(p_codigo, ''))) and c.whatsapp = (case when length(regexp_replace(coalesce(p_whatsapp, ''), '\D', '', 'g')) <= 11 then '55' else '' end) || regexp_replace(coalesce(p_whatsapp, ''), '\D', '', 'g');
  if not found then return jsonb_build_object('encontrado', false); end if;
  return jsonb_build_object(
    'encontrado', true, 'codigo', ped.codigo, 'status', ped.status,
    'retirada', nullif(btrim(coalesce(ped.endereco, '')), '') is null,
    'forma_pagamento', ped.forma_pagamento, 'total', ped.total, 'criado_em', ped.criado_em,
    'codigo_entrega', case when ped.status = 'saiu_entrega' then ped.codigo_entrega end,
    'codigo_conferido', ped.entrega_codigo_ok,
    'eventos', coalesce((select jsonb_agg(jsonb_build_object('status', e.status, 'em', e.em) order by e.em)
                           from public.pedido_eventos e where e.pedido_id = ped.id), '[]'::jsonb));
end $$;
