-- TQR Açaí · o pedido só vira "pago" depois do pagamento confirmado na tela Pagamentos (ou pelo gateway).
create or replace function app_private.guarda_pedido() returns trigger
language plpgsql security invoker set search_path = '' as $$
declare r public.pedidos;
begin
  if (select auth.uid()) is null then return new; end if;
  r := new; r.status := old.status; r.atualizado_em := old.atualizado_em; r.observacao := old.observacao;
  r.motivo_cancelamento := old.motivo_cancelamento; r.detalhe_cancelamento := old.detalhe_cancelamento;
  r.cancelado_em := old.cancelado_em; r.cancelado_por := old.cancelado_por;
  if current_setting('app.entrega_ok', true) = new.id::text then r.entrega_codigo_ok := old.entrega_codigo_ok; end if;
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
    -- pedido não pago só chega a "pago" (e além) por quem confirma o pagamento (função) ou pelo gateway; edição direta pelo painel é bloqueada
    if old.status in ('pendente','confirmado') and new.status in ('pago','saiu_entrega','entregue') and current_user = 'authenticated' then
      raise exception 'pagamento_nao_confirmado' using errcode = '22023';
    end if;
    -- com a exigência ligada, "entregue" só passa pela função que confere o código
    if new.status = 'entregue'
       and coalesce((select valor from public.configuracoes where chave = 'exigir_codigo_entrega'), 'false') = 'true'
       and current_setting('app.entrega_ok', true) is distinct from new.id::text then
      raise exception 'codigo_obrigatorio' using errcode = '22023';
    end if;
  elsif (new.motivo_cancelamento is distinct from old.motivo_cancelamento or new.detalhe_cancelamento is distinct from old.detalhe_cancelamento
         or new.cancelado_em is distinct from old.cancelado_em or new.cancelado_por is distinct from old.cancelado_por)
        and not public.tem_permissao('pedidos.cancelar') then
    raise exception 'sem_permissao:cancelar' using errcode = '42501';
  end if;
  if new.observacao is distinct from old.observacao and not public.tem_permissao('pedidos.editar') then
    raise exception 'sem_permissao:editar' using errcode = '42501';
  end if;
  return new;
end $$;

create function public.admin_confirmar_pagamento(p_pedido uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare s public.pedido_status;
begin
  if not public.tem_permissao('pedidos.status') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  select status into s from public.pedidos where id = p_pedido for update;
  if not found then raise exception 'pedido_inexistente' using errcode = '22023'; end if;
  if s not in ('pendente', 'confirmado') then raise exception 'status_invalido' using errcode = '22023'; end if;
  update public.pedidos set status = 'pago' where id = p_pedido;
end $$;
revoke all on function public.admin_confirmar_pagamento(uuid) from public, anon;
grant execute on function public.admin_confirmar_pagamento(uuid) to authenticated;
