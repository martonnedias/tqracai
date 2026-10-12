-- TQR Açaí · pagamentos online (Pix/cartão por gateway), webhook, modo teste e conciliação
-- Nenhum dado real: o gateway começa DESLIGADO ('nenhum'). 'teste' simula cobranças sem dinheiro de verdade.
-- As chaves do gateway (API key, token do webhook) ficam só nos segredos da função de borda `pagamentos`, nunca no banco.
insert into public.configuracoes (chave, valor, descricao) values
 ('gateway_ativo','nenhum','Gateway de pagamento: nenhum, teste ou asaas'),
 ('pix_expira_min','30','Minutos de validade do Pix online')
on conflict (chave) do nothing;

create table public.pagamentos (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references public.pedidos(id) on delete cascade,
  gateway text not null check (gateway in ('teste','asaas')),
  provider_id text,                                   -- id da cobrança no gateway
  metodo text not null default 'pix' references public.formas_pagamento(id),
  status text not null default 'pendente'
    check (status in ('pendente','aprovado','recusado','expirado','estornado','disputa')),
  valor numeric(12,2) not null check (valor > 0),
  taxa_real numeric(12,2),                            -- taxa cobrada de verdade pelo gateway (substitui a estimada)
  pix_copia_cola text,
  pix_qr text,                                        -- imagem base64 (quando o gateway fornece)
  link_pagamento text,
  expira_em timestamptz,
  pago_em timestamptz,
  payload jsonb not null default '{}'::jsonb,         -- resposta bruta do gateway (sem segredos)
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);
create unique index pagamentos_provider_uk on public.pagamentos (gateway, provider_id) where provider_id is not null;
create unique index pagamentos_pendente_uk on public.pagamentos (pedido_id, metodo) where status = 'pendente';
create index pagamentos_pedido_idx on public.pagamentos (pedido_id);
create index pagamentos_status_idx on public.pagamentos (status, criado_em desc);

-- eventos já processados (idempotência do webhook)
create table public.pagamento_eventos (
  evento_id text not null,
  gateway text not null,
  pagamento_id uuid references public.pagamentos(id) on delete cascade,
  tipo text not null,
  criado_em timestamptz not null default now(),
  primary key (gateway, evento_id)
);

alter table public.pagamentos enable row level security;
alter table public.pagamento_eventos enable row level security;
create policy pag_sel on public.pagamentos for select to authenticated using ((select public.tem_permissao('financeiro.ver')));
-- sem política de escrita: tudo passa pelas funções abaixo

-- ===== núcleo: aplica um resultado do gateway (usado pelo webhook, pelo modo teste e pelo painel) =====
create function app_private.pagamento_aplicar(p_pag uuid, p_tipo text, p_taxa numeric, p_payload jsonb) returns text
language plpgsql security definer set search_path = '' as $$
declare pg public.pagamentos; ped public.pedidos;
begin
  select * into pg from public.pagamentos where id = p_pag for update;
  if not found then raise exception 'pagamento_inexistente' using errcode = '22023'; end if;
  select * into ped from public.pedidos where id = pg.pedido_id for update;

  if p_tipo = 'aprovado' then
    if pg.status = 'aprovado' then return 'aprovado'; end if;
    if pg.status = 'estornado' then return pg.status; end if;
    update public.pagamentos set status = 'aprovado', pago_em = now(), taxa_real = coalesce(p_taxa, taxa_real),
      payload = payload || coalesce(p_payload, '{}'::jsonb), atualizado_em = now() where id = pg.id;
    if ped.status = 'cancelado' then
      -- pagou um pedido já cancelado: fica registrado em "disputa" para o dono decidir (reembolso)
      update public.pagamentos set status = 'disputa' where id = pg.id;
      return 'disputa';
    end if;
    update public.pedidos set forma_pagamento = pg.metodo where id = ped.id and forma_pagamento is distinct from pg.metodo;
    if ped.status in ('pendente','confirmado') then
      update public.pedidos set status = 'pago' where id = ped.id;     -- gatilhos geram caixa, pontos e baixa de estoque
    end if;
    if p_taxa is not null then
      update public.lancamentos set taxa = p_taxa where pedido_id = ped.id and origem = 'pedido';
    end if;
    return 'aprovado';

  elsif p_tipo in ('recusado','expirado') then
    if pg.status <> 'pendente' then return pg.status; end if;
    update public.pagamentos set status = p_tipo, payload = payload || coalesce(p_payload, '{}'::jsonb), atualizado_em = now() where id = pg.id;
    return p_tipo;

  elsif p_tipo in ('estornado','disputa') then
    if pg.status = 'estornado' then return pg.status; end if;
    update public.pagamentos set status = p_tipo, payload = payload || coalesce(p_payload, '{}'::jsonb), atualizado_em = now() where id = pg.id;
    if p_tipo = 'estornado' then
      if ped.status in ('pendente','confirmado','pago') then
        update public.pedidos set status = 'cancelado' where id = ped.id;   -- o gatilho estorna caixa, pontos e estoque
      else
        perform app_private.estornar_pedido(ped);                          -- já saiu/entregue: só estorna o dinheiro e os pontos
      end if;
    end if;
    return p_tipo;
  end if;
  raise exception 'evento_invalido' using errcode = '22023';
end $$;
revoke all on function app_private.pagamento_aplicar(uuid,text,numeric,jsonb) from public, anon, authenticated;

-- cria a linha da cobrança (a função de borda chama isto depois de criar a cobrança no gateway)
create function public.pagamento_registrar(p_pedido uuid, p_gateway text, p_provider text, p_metodo text, p_pix text, p_qr text,
                                           p_link text, p_expira timestamptz, p_payload jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare ped public.pedidos; novo uuid;
begin
  select * into ped from public.pedidos where id = p_pedido;
  if not found then raise exception 'pedido_inexistente' using errcode = '22023'; end if;
  if ped.status not in ('pendente','confirmado') then raise exception 'pedido_nao_cobravel' using errcode = '22023'; end if;
  update public.pagamentos set status = 'expirado', atualizado_em = now()
    where pedido_id = p_pedido and metodo = p_metodo and status = 'pendente' and expira_em < now();
  insert into public.pagamentos (pedido_id, gateway, provider_id, metodo, valor, pix_copia_cola, pix_qr, link_pagamento, expira_em, payload)
  values (p_pedido, p_gateway, p_provider, p_metodo, ped.total, p_pix, p_qr, p_link, p_expira, coalesce(p_payload, '{}'::jsonb))
  returning id into novo;
  return novo;
end $$;
revoke all on function public.pagamento_registrar(uuid,text,text,text,text,text,text,timestamptz,jsonb) from public, anon, authenticated;
grant execute on function public.pagamento_registrar(uuid,text,text,text,text,text,text,timestamptz,jsonb) to service_role;

-- webhook: idempotente por (gateway, evento_id). Só a função de borda (service_role) chama, depois de validar a assinatura.
create function public.pagamento_webhook(p_gateway text, p_evento_id text, p_provider_id text, p_tipo text, p_taxa numeric, p_payload jsonb) returns text
language plpgsql security definer set search_path = '' as $$
declare pg public.pagamentos; n int;
begin
  select * into pg from public.pagamentos where gateway = p_gateway and provider_id = p_provider_id;
  if not found then return 'desconhecido'; end if;
  insert into public.pagamento_eventos (evento_id, gateway, pagamento_id, tipo) values (p_evento_id, p_gateway, pg.id, p_tipo)
    on conflict do nothing;
  get diagnostics n = row_count;
  if n = 0 then return 'repetido'; end if;
  return app_private.pagamento_aplicar(pg.id, p_tipo, p_taxa, p_payload);
end $$;
revoke all on function public.pagamento_webhook(text,text,text,text,numeric,jsonb) from public, anon, authenticated;
grant execute on function public.pagamento_webhook(text,text,text,text,numeric,jsonb) to service_role;

create function app_private.gateway_ativo() returns text
language sql stable security definer set search_path = '' as $$
  select coalesce((select valor from public.configuracoes where chave = 'gateway_ativo'), 'nenhum')
$$;
revoke all on function app_private.gateway_ativo() from public, anon, authenticated;

-- ===== modo teste: cobrança simulada =====
create function app_private.pagamento_teste_criar(p_pedido uuid, p_metodo text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare ped public.pedidos; existente uuid; minutos int; novo uuid; pid text;
begin
  select id into existente from public.pagamentos where pedido_id = p_pedido and metodo = p_metodo and status = 'pendente' and expira_em > now();
  if existente is not null then return existente; end if;
  select valor::int into minutos from public.configuracoes where chave = 'pix_expira_min';
  select * into ped from public.pedidos where id = p_pedido;
  pid := 'teste_' || replace(gen_random_uuid()::text, '-', '');
  novo := public.pagamento_registrar(p_pedido, 'teste', pid, p_metodo,
    '00020126TESTE-SEM-VALOR-REAL5204000053039865802BR5913TQR ACAI TESTE6008TERESINA62070503***6304' || upper(substr(md5(pid), 1, 4)),
    null, null, now() + make_interval(mins => coalesce(minutos, 30)), jsonb_build_object('modo', 'teste', 'codigo_pedido', ped.codigo));
  return novo;
end $$;
revoke all on function app_private.pagamento_teste_criar(uuid,text) from public, anon, authenticated;

-- painel: gerar cobrança no modo teste (nos gateways reais o painel chama a função de borda)
create function public.pagamento_admin_cobrar_teste(p_pedido uuid, p_metodo text default 'pix') returns uuid
language plpgsql security definer set search_path = '' as $$
begin
  if not (public.tem_permissao('financeiro.gerir') or public.tem_permissao('pedidos.status')) then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if app_private.gateway_ativo() <> 'teste' then raise exception 'gateway_nao_e_teste' using errcode = '22023'; end if;
  return app_private.pagamento_teste_criar(p_pedido, p_metodo);
end $$;

-- painel: simular resultado (somente cobranças de teste)
create function public.pagamento_admin_simular(p_pagamento uuid, p_tipo text) returns text
language plpgsql security definer set search_path = '' as $$
declare g text;
begin
  if not public.tem_permissao('financeiro.gerir') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  select gateway into g from public.pagamentos where id = p_pagamento;
  if g is distinct from 'teste' then raise exception 'so_modo_teste' using errcode = '22023'; end if;
  return app_private.pagamento_aplicar(p_pagamento, p_tipo, case when p_tipo = 'aprovado' then 0 end, jsonb_build_object('simulado', true));
end $$;

-- painel: estorno de pagamento de teste (nos gateways reais a função de borda pede o estorno ao gateway)
create function public.pagamento_admin_estornar_teste(p_pagamento uuid) returns text
language plpgsql security definer set search_path = '' as $$
declare g text;
begin
  if not public.tem_permissao('financeiro.gerir') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  select gateway into g from public.pagamentos where id = p_pagamento;
  if g is distinct from 'teste' then raise exception 'so_modo_teste' using errcode = '22023'; end if;
  return app_private.pagamento_aplicar(p_pagamento, 'estornado', null, jsonb_build_object('simulado', true));
end $$;

-- ===== site: Pix online (gateway 'teste' resolve aqui; nos reais a função de borda atende) =====
create function public.pagamento_publico(p_codigo text, p_whatsapp text, p_criar boolean default true) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare ped public.pedidos; pg public.pagamentos; gw text := app_private.gateway_ativo();
begin
  select p.* into ped from public.pedidos p join public.clientes c on c.id = p.cliente_id
    where p.codigo = upper(trim(coalesce(p_codigo, ''))) and c.whatsapp = regexp_replace(coalesce(p_whatsapp, ''), '\D', '', 'g');
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
revoke all on function public.pagamento_publico(text,text,boolean) from public;
grant execute on function public.pagamento_publico(text,text,boolean) to anon, authenticated;

revoke all on function public.pagamento_admin_cobrar_teste(uuid,text), public.pagamento_admin_simular(uuid,text), public.pagamento_admin_estornar_teste(uuid) from public, anon;
grant execute on function public.pagamento_admin_cobrar_teste(uuid,text), public.pagamento_admin_simular(uuid,text), public.pagamento_admin_estornar_teste(uuid) to authenticated;
