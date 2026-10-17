-- Acompanhamento do pedido pelo cliente (site). Exige código + WhatsApp do pedido (como pagamento_publico).
-- Devolve só o necessário: situação, modalidade, forma de pagamento, total e horários de cada etapa.
create function public.acompanhar_pedido(p_codigo text, p_whatsapp text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare ped public.pedidos;
begin
  select p.* into ped from public.pedidos p join public.clientes c on c.id = p.cliente_id
    where p.codigo = upper(trim(coalesce(p_codigo, ''))) and c.whatsapp = regexp_replace(coalesce(p_whatsapp, ''), '\D', '', 'g');
  if not found then return jsonb_build_object('encontrado', false); end if;
  return jsonb_build_object(
    'encontrado', true, 'codigo', ped.codigo, 'status', ped.status,
    'retirada', nullif(btrim(coalesce(ped.endereco, '')), '') is null,
    'forma_pagamento', ped.forma_pagamento, 'total', ped.total, 'criado_em', ped.criado_em,
    'eventos', coalesce((select jsonb_agg(jsonb_build_object('status', e.status, 'em', e.em) order by e.em)
                           from public.pedido_eventos e where e.pedido_id = ped.id), '[]'::jsonb));
end $$;
revoke all on function public.acompanhar_pedido(text, text) from public;
grant execute on function public.acompanhar_pedido(text, text) to anon, authenticated;
