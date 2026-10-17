-- TQR Açaí · código de entrega/retirada (PIN de 4 dígitos). O cliente vê quando o pedido sai (ou fica pronto);
-- quem entrega/entrega no balcão digita o código ao marcar "Entregue". Exigir o código é opcional (Configurações).
alter table public.pedidos
  add column codigo_entrega text not null default lpad(floor(random() * 10000)::int::text, 4, '0'),
  add column entrega_codigo_ok boolean not null default false;

insert into public.configuracoes (chave, valor, descricao) values
 ('exigir_codigo_entrega','false','Exigir o código do cliente para marcar o pedido como entregue (true/false)')
on conflict (chave) do nothing;

create or replace function app_private.validar_config() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.chave in ('preco_unitario','preco_combo3','preco_5mais','pontos_por_real','pontos_por_brinde',
                   'contador_base','contador_ajuste','pedido_min','pedido_max','novidades_dias')
     and new.valor !~ '^-?[0-9]+(\.[0-9]+)?$' then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave in ('preco_unitario','preco_combo3','preco_5mais','pedido_min','pedido_max')
     and new.valor::numeric < 0 then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave = 'novidades_dias' and (new.valor::numeric < 1 or new.valor::numeric > 90) then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave in ('horario_abre','horario_fecha') and new.valor !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave in ('aviso_ativo','novidades_ativo','exigir_codigo_entrega') and new.valor not in ('true','false') then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave = 'novidades_ocultas' and new.valor !~ '^[a-z0-9:,_-]{0,500}$' then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave in ('whatsapp_pedidos','whatsapp_loja') and new.valor !~ '^55[0-9]{10,11}$' then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  return new;
end $$;

-- gatilho de proteção: "entrega_codigo_ok" só muda pela função admin_concluir_entrega (marcada em app.entrega_ok)
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

-- marca "entregue" conferindo o código (opcional, a menos que a exigência esteja ligada). Devolve true se o código bateu.
create function public.admin_concluir_entrega(p_pedido uuid, p_codigo text default null) returns boolean
language plpgsql security definer set search_path = '' as $$
declare ped public.pedidos; c text := nullif(btrim(coalesce(p_codigo, '')), ''); ok boolean;
begin
  if not (public.tem_permissao('pedidos.status') or public.tem_permissao('pedidos.status_entrega')) then
    raise exception 'nao_autorizado' using errcode = '42501'; end if;
  select * into ped from public.pedidos where id = p_pedido for update;
  if not found then raise exception 'pedido_inexistente' using errcode = '22023'; end if;
  if ped.status in ('entregue', 'cancelado') then raise exception 'status_invalido' using errcode = '22023'; end if;
  ok := c is not null and c = ped.codigo_entrega;
  if c is not null and not ok then raise exception 'codigo_incorreto' using errcode = '22023'; end if;
  if not ok and coalesce((select valor from public.configuracoes where chave = 'exigir_codigo_entrega'), 'false') = 'true' then
    raise exception 'codigo_obrigatorio' using errcode = '22023'; end if;
  perform set_config('app.entrega_ok', p_pedido::text, true);
  update public.pedidos set status = 'entregue', entrega_codigo_ok = ok where id = p_pedido;
  return ok;
end $$;
revoke all on function public.admin_concluir_entrega(uuid, text) from public, anon;
grant execute on function public.admin_concluir_entrega(uuid, text) to authenticated;

-- o cliente vê o código enquanto o pedido está a caminho / pronto para retirar
create or replace function public.acompanhar_pedido(p_codigo text, p_whatsapp text) returns jsonb
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
    'codigo_entrega', case when ped.status = 'saiu_entrega' then ped.codigo_entrega end,
    'codigo_conferido', ped.entrega_codigo_ok,
    'eventos', coalesce((select jsonb_agg(jsonb_build_object('status', e.status, 'em', e.em) order by e.em)
                           from public.pedido_eventos e where e.pedido_id = ped.id), '[]'::jsonb));
end $$;
