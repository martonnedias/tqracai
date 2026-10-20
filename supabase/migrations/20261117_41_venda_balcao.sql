-- Venda de balcão: lança a venda já paga e entregue (retirada), sem exigir WhatsApp.
-- Sem WhatsApp, a venda vai para o cliente reservado "Cliente balcão" (whatsapp 55 0000 0000 00), que não acumula pontos.
-- Com WhatsApp, é um cliente normal (acumula pontos). Usa as mesmas regras do pedido do site: promoções, sabor e estoque pronto.

-- pontos: o cliente balcão não ganha
create or replace function app_private.lancar_pedido_pago(ped public.pedidos) returns void
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
  if pts > 0 and not exists (select 1 from public.clientes c where c.id = ped.cliente_id and c.whatsapp = '550000000000') then
    insert into public.livro_pontos (cliente_id, pedido_id, tipo, pontos, motivo)
    values (ped.cliente_id, ped.id, 'ganho', pts, 'Pedido ' || ped.codigo) on conflict do nothing;
  end if;
end $$;

create function public.admin_venda_balcao(
  p_itens jsonb, p_forma text, p_whatsapp text default null, p_nome text default null,
  p_montagens jsonb default null, p_cupom text default null, p_observacao text default null)
returns table (pedido_codigo text, pedido_total numeric)
language plpgsql security definer set search_path = '' as $$
declare w text; r record;
begin
  if not (public.tem_permissao('pedidos.criar') and public.tem_permissao('pedidos.status')) then
    raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if nullif(trim(coalesce(p_forma, '')), '') is null then raise exception 'pagamento_obrigatorio' using errcode = '22023'; end if;
  w := nullif(trim(coalesce(p_whatsapp, '')), '');
  select * into r from app_private.criar_pedido_core(
    coalesce(w, '550000000000'), p_itens,
    case when w is null then 'Cliente balcão' else nullif(trim(coalesce(p_nome, '')), '') end,
    null, null, false, p_forma, null, null, null, 'retirada', p_cupom,
    coalesce(nullif(trim(coalesce(p_observacao, '')), ''), 'Venda de balcão'), 'manual', p_montagens);
  update public.pedidos set status = 'pago' where codigo = r.pedido_codigo;
  update public.pedidos set status = 'entregue' where codigo = r.pedido_codigo;
  return query select r.pedido_codigo, r.pedido_total;
end $$;

revoke all on function public.admin_venda_balcao(jsonb, text, text, text, jsonb, text, text) from public, anon;
grant execute on function public.admin_venda_balcao(jsonb, text, text, text, jsonb, text, text) to authenticated;
