-- TQR Açaí · cancelamento de pedido com motivo. O estorno do caixa/pontos/estoque continua vindo dos gatilhos de status.
alter table public.pedidos
  add column motivo_cancelamento text,
  add column detalhe_cancelamento text,
  add column cancelado_em timestamptz,
  add column cancelado_por uuid;

-- o gatilho de proteção trata os campos de cancelamento como parte do status (quem pode cancelar, pode gravar o motivo)
create or replace function app_private.guarda_pedido() returns trigger
language plpgsql security invoker set search_path = '' as $$
declare r public.pedidos;
begin
  if (select auth.uid()) is null then return new; end if;
  r := new; r.status := old.status; r.atualizado_em := old.atualizado_em; r.observacao := old.observacao;
  r.motivo_cancelamento := old.motivo_cancelamento; r.detalhe_cancelamento := old.detalhe_cancelamento;
  r.cancelado_em := old.cancelado_em; r.cancelado_por := old.cancelado_por;
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

create function public.admin_cancelar_pedido(p_pedido uuid, p_motivo text, p_detalhe text default null) returns void
language plpgsql security definer set search_path = '' as $$
declare s public.pedido_status; d text := nullif(btrim(coalesce(p_detalhe, '')), '');
begin
  if not public.tem_permissao('pedidos.cancelar') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if p_motivo is null or p_motivo not in ('cliente_desistiu','pagamento_nao_confirmado','sem_estoque','fora_da_area','pedido_duplicado','erro_no_pedido','outro') then
    raise exception 'motivo_invalido' using errcode = '22023'; end if;
  if p_motivo = 'outro' and d is null then raise exception 'detalhe_obrigatorio' using errcode = '22023'; end if;
  if d is not null and char_length(d) > 300 then raise exception 'detalhe_muito_longo' using errcode = '22023'; end if;
  select status into s from public.pedidos where id = p_pedido for update;
  if not found then raise exception 'pedido_inexistente' using errcode = '22023'; end if;
  if s = 'cancelado' then raise exception 'ja_cancelado' using errcode = '22023'; end if;
  update public.pedidos
     set status = 'cancelado', motivo_cancelamento = p_motivo, detalhe_cancelamento = d,
         cancelado_em = now(), cancelado_por = (select auth.uid())
   where id = p_pedido;
end $$;
revoke all on function public.admin_cancelar_pedido(uuid, text, text) from public, anon;
grant execute on function public.admin_cancelar_pedido(uuid, text, text) to authenticated;
