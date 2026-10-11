-- TQR Açaí · Etapa 6 · código de verificação (WhatsApp) e endereços múltiplos do cliente
-- Rodar depois da 05.
--
-- Como funciona: o cliente pede um código no site; o código aparece no painel (quem tem clientes.ver) e o dono o envia
-- pelo WhatsApp. Com o código certo o site recebe um token de 30 min para listar, salvar e apagar os endereços daquele número.
-- Observação de projeto: o código fica em texto no banco por até 10 minutos porque o dono precisa lê-lo no painel para
-- enviar; o token do cliente é guardado só como hash. O mesmo mecanismo vai servir para a consulta de saldo de pontos (fase 2).

create table public.codigos_verificacao (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.clientes(id) on delete cascade,
  codigo text not null check (codigo ~ '^[0-9]{6}$'),
  finalidade text not null default 'cliente' check (finalidade in ('cliente','saldo')),
  criado_em timestamptz not null default now(),
  expira_em timestamptz not null default now() + interval '10 minutes',
  tentativas int not null default 0,
  usado boolean not null default false
);
create index codigos_cliente_idx on public.codigos_verificacao (cliente_id, criado_em desc);
create index codigos_criado_idx on public.codigos_verificacao (criado_em);

create table public.sessoes_cliente (
  token_hash text primary key,
  cliente_id uuid not null references public.clientes(id) on delete cascade,
  criado_em timestamptz not null default now(),
  expira_em timestamptz not null default now() + interval '30 minutes'
);
create index sessoes_cliente_idx on public.sessoes_cliente (cliente_id);

create table public.enderecos_cliente (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.clientes(id) on delete cascade,
  apelido text check (length(apelido) <= 30),
  rua text not null check (length(trim(rua)) >= 3 and length(rua) <= 160),
  complemento text check (length(complemento) <= 80),
  bairro text not null check (length(trim(bairro)) >= 2 and length(bairro) <= 60),
  bairro_id uuid references public.bairros_entrega(id) on delete set null,
  referencia text check (length(referencia) <= 120),
  padrao boolean not null default false,
  ativo boolean not null default true,        -- apagar = ativo false (o histórico de pedidos não muda)
  criado_em timestamptz not null default now()
);
create index enderecos_cliente_idx on public.enderecos_cliente (cliente_id) where ativo;
create unique index enderecos_padrao_uk on public.enderecos_cliente (cliente_id) where padrao and ativo;

alter table public.codigos_verificacao enable row level security;
alter table public.sessoes_cliente enable row level security;
alter table public.enderecos_cliente enable row level security;
revoke all on public.codigos_verificacao, public.sessoes_cliente, public.enderecos_cliente from anon;
revoke all on public.codigos_verificacao, public.sessoes_cliente from authenticated;   -- só por funções
create policy end_sel on public.enderecos_cliente for select to authenticated using ((select public.tem_permissao('clientes.ver')));
create policy end_ins on public.enderecos_cliente for insert to authenticated with check ((select public.tem_permissao('clientes.editar')));
create policy end_upd on public.enderecos_cliente for update to authenticated
  using ((select public.tem_permissao('clientes.editar'))) with check ((select public.tem_permissao('clientes.editar')));

-- ===== validação de sessão do cliente =====
create function app_private.cliente_da_sessao(p_whatsapp text, p_token text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare cid uuid;
begin
  if p_token is null or length(p_token) < 20 then return null; end if;
  select s.cliente_id into cid
  from public.sessoes_cliente s join public.clientes c on c.id = s.cliente_id
  where s.token_hash = encode(sha256(convert_to(p_token, 'UTF8')), 'hex')
    and s.expira_em > now() and c.whatsapp = public.normalizar_whatsapp(p_whatsapp);
  return cid;
end $$;

-- ===== pedir e confirmar o código =====
create function public.solicitar_codigo(p_whatsapp text) returns boolean
language plpgsql security definer set search_path = '' as $$
declare cid uuid; w text := public.normalizar_whatsapp(p_whatsapp);
begin
  delete from public.codigos_verificacao where criado_em < now() - interval '1 day';
  delete from public.sessoes_cliente where expira_em < now();
  select id into cid from public.clientes where whatsapp = w;
  if cid is null then return true; end if;     -- resposta igual para número desconhecido
  if (select count(*) from public.codigos_verificacao where cliente_id = cid and criado_em > now() - interval '10 minutes') >= 3
     or (select count(*) from public.codigos_verificacao where criado_em > now() - interval '10 minutes') >= 30 then
    raise exception 'muitas_solicitacoes' using errcode = 'P0001';
  end if;
  update public.codigos_verificacao set usado = true where cliente_id = cid and not usado;
  insert into public.codigos_verificacao (cliente_id, codigo)
  values (cid, lpad((('x' || substr(md5(gen_random_uuid()::text), 1, 8))::bit(32)::bigint % 1000000)::text, 6, '0'));
  return true;
end $$;

-- Devolve o token, ou NULL quando o código não confere. Não usa exceção de propósito: uma exceção desfaria a contagem de tentativas.
create function public.verificar_codigo(p_whatsapp text, p_codigo text) returns text
language plpgsql security definer set search_path = '' as $$
declare cid uuid; c public.codigos_verificacao; tok text;
begin
  select id into cid from public.clientes where whatsapp = public.normalizar_whatsapp(p_whatsapp);
  if cid is null then return null; end if;
  select * into c from public.codigos_verificacao
   where cliente_id = cid and not usado and expira_em > now() order by criado_em desc limit 1 for update;
  if not found then return null; end if;
  if c.codigo is distinct from trim(p_codigo) then
    update public.codigos_verificacao set tentativas = tentativas + 1, usado = (tentativas + 1 >= 5) where id = c.id;
    return null;
  end if;
  update public.codigos_verificacao set usado = true where id = c.id;
  tok := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
  insert into public.sessoes_cliente (token_hash, cliente_id) values (encode(sha256(convert_to(tok, 'UTF8')), 'hex'), cid);
  return tok;
end $$;

-- ===== endereços (só com sessão verificada) =====
create function public.listar_enderecos(p_whatsapp text, p_token text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare cid uuid := app_private.cliente_da_sessao(p_whatsapp, p_token);
begin
  if cid is null then raise exception 'sessao_invalida' using errcode = '42501'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id', e.id, 'apelido', e.apelido, 'rua', e.rua, 'complemento', e.complemento,
            'bairro', e.bairro, 'bairro_id', e.bairro_id, 'referencia', e.referencia, 'padrao', e.padrao) order by e.padrao desc, e.criado_em desc)
          from public.enderecos_cliente e where e.cliente_id = cid and e.ativo), '[]'::jsonb);
end $$;

create function public.salvar_endereco(
  p_whatsapp text, p_token text, p_rua text, p_bairro text, p_apelido text default null, p_complemento text default null,
  p_referencia text default null, p_bairro_id uuid default null, p_padrao boolean default false)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare cid uuid := app_private.cliente_da_sessao(p_whatsapp, p_token); eid uuid; n int;
begin
  if cid is null then raise exception 'sessao_invalida' using errcode = '42501'; end if;
  select count(*) into n from public.enderecos_cliente where cliente_id = cid and ativo;
  -- mesmo endereço (rua e bairro) não duplica: atualiza o existente
  select id into eid from public.enderecos_cliente
   where cliente_id = cid and ativo and lower(trim(rua)) = lower(trim(p_rua)) and lower(trim(bairro)) = lower(trim(p_bairro)) limit 1;
  if eid is null and n >= 10 then raise exception 'limite_enderecos' using errcode = 'P0001'; end if;
  if coalesce(p_padrao, false) or n = 0 then
    update public.enderecos_cliente set padrao = false where cliente_id = cid and padrao;
  end if;
  if eid is null then
    insert into public.enderecos_cliente (cliente_id, apelido, rua, complemento, bairro, bairro_id, referencia, padrao)
    values (cid, nullif(trim(p_apelido), ''), trim(p_rua), nullif(trim(p_complemento), ''), trim(p_bairro),
            (select id from public.bairros_entrega where id = p_bairro_id), nullif(trim(p_referencia), ''), coalesce(p_padrao, false) or n = 0)
    returning id into eid;
  else
    update public.enderecos_cliente set apelido = coalesce(nullif(trim(p_apelido), ''), apelido), complemento = nullif(trim(p_complemento), ''),
      referencia = nullif(trim(p_referencia), ''), bairro_id = (select id from public.bairros_entrega where id = p_bairro_id),
      padrao = coalesce(p_padrao, false) or padrao where id = eid;
  end if;
  return eid;
end $$;

create function public.apagar_endereco(p_whatsapp text, p_token text, p_id uuid) returns boolean
language plpgsql security definer set search_path = '' as $$
declare cid uuid := app_private.cliente_da_sessao(p_whatsapp, p_token);
begin
  if cid is null then raise exception 'sessao_invalida' using errcode = '42501'; end if;
  update public.enderecos_cliente set ativo = false, padrao = false where id = p_id and cliente_id = cid and ativo;
  return found;
end $$;

-- ===== painel: códigos pendentes =====
create function public.admin_codigos_pendentes() returns table (id uuid, nome text, whatsapp text, codigo text, criado_em timestamptz, expira_em timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.tem_permissao('clientes.ver') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  return query select v.id, c.nome, c.whatsapp, v.codigo, v.criado_em, v.expira_em
    from public.codigos_verificacao v join public.clientes c on c.id = v.cliente_id
    where not v.usado and v.expira_em > now() order by v.criado_em desc limit 50;
end $$;

revoke all on function app_private.cliente_da_sessao(text,text) from public, anon, authenticated;
revoke all on function public.solicitar_codigo(text), public.verificar_codigo(text,text), public.listar_enderecos(text,text),
  public.salvar_endereco(text,text,text,text,text,text,text,uuid,boolean), public.apagar_endereco(text,text,uuid),
  public.admin_codigos_pendentes() from public, anon, authenticated;
grant execute on function public.solicitar_codigo(text), public.verificar_codigo(text,text), public.listar_enderecos(text,text),
  public.salvar_endereco(text,text,text,text,text,text,text,uuid,boolean), public.apagar_endereco(text,text,uuid) to anon, authenticated;
grant execute on function public.admin_codigos_pendentes() to authenticated;

-- ===== o primeiro pedido de um cliente novo já salva o endereço (substitui a função da migração 05) =====
create or replace function app_private.criar_pedido_core(
  p_whatsapp text, p_itens jsonb, p_nome text, p_nasc date, p_email text, p_aceite boolean,
  p_forma text, p_endereco text, p_bairro text, p_bairro_id uuid, p_modalidade text, p_cupom text,
  p_obs text, p_origem text)
returns table (pedido_codigo text, pedido_total numeric, pedido_desconto numeric, pedido_taxa numeric, pedido_promocao text)
language plpgsql security definer set search_path = '' as $$
declare
  w text; cid uuid; ped_id uuid; cod text; forma text; m jsonb; l jsonb; bnome text; novo boolean := false;
begin
  w := public.normalizar_whatsapp(p_whatsapp);
  forma := nullif(trim(p_forma), '');
  if forma is not null and not exists (select 1 from public.formas_pagamento where id = forma and ativo) then
    raise exception 'pagamento_invalido' using errcode = '22023';
  end if;
  if p_nasc is not null and (p_nasc > current_date or p_nasc < date '1900-01-01') then
    raise exception 'nascimento_invalido' using errcode = '22023';
  end if;
  -- valida o carrinho antes de criar cliente (nada é gravado se o pedido for inválido)
  perform app_private.motor_pedido(p_itens, p_cupom, p_modalidade, p_bairro_id, forma, null, false);

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
    novo := true;
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

  m := app_private.motor_pedido(p_itens, p_cupom, p_modalidade, p_bairro_id, forma, cid, true);
  cod := 'TQR-' || lpad(nextval('public.pedido_codigo_seq')::text, 4, '0');
  select nome into bnome from public.bairros_entrega where id = p_bairro_id;

  insert into public.pedidos (codigo, cliente_id, total, subtotal, desconto, taxa_entrega, forma_pagamento, endereco, bairro,
                              observacao, origem, modalidade, bairro_id, promocao_id, cupom)
  values (cod, cid, (m->>'total')::numeric, (m->>'subtotal')::numeric, (m->>'desconto')::numeric, (m->>'taxa_entrega')::numeric,
          forma, nullif(trim(p_endereco), ''), coalesce(bnome, nullif(trim(p_bairro), '')),
          nullif(trim(p_obs), ''), p_origem, p_modalidade,
          case when p_modalidade = 'entrega_bairro' then p_bairro_id end,
          (m->'promocao'->>'id')::uuid,
          case when m->>'cupom_status' = 'aplicado' then m->'promocao'->>'codigo' end)
  returning id into ped_id;

  -- cliente novo: o endereço informado no primeiro pedido já fica salvo (ninguém mais é dono desse número ainda)
  if novo and nullif(trim(p_endereco), '') is not null and coalesce(bnome, nullif(trim(p_bairro), '')) is not null
     and length(trim(p_endereco)) between 3 and 160 and length(coalesce(bnome, trim(p_bairro))) between 2 and 60 then
    insert into public.enderecos_cliente (cliente_id, rua, bairro, bairro_id, padrao)
    values (cid, trim(p_endereco), coalesce(bnome, trim(p_bairro)), case when p_modalidade = 'entrega_bairro' then p_bairro_id end, true);
  end if;

  for l in select * from jsonb_array_elements(m->'itens') loop
    insert into public.itens_pedido (pedido_id, produto_id, quantidade, subtotal, preco_unitario, nome_produto)
    values (ped_id, (l->>'produto_id')::uuid, (l->>'quantidade')::int, (l->>'subtotal')::numeric, (l->>'preco')::numeric, l->>'nome');
  end loop;
  for l in select * from jsonb_array_elements(m->'brindes') loop
    insert into public.itens_pedido (pedido_id, produto_id, quantidade, subtotal, preco_unitario, nome_produto, brinde)
    values (ped_id, (l->>'produto_id')::uuid, (l->>'quantidade')::int, 0, 0, l->>'nome', true);
  end loop;

  return query select cod, (m->>'total')::numeric, (m->>'desconto')::numeric, (m->>'taxa_entrega')::numeric, m->'promocao'->>'nome';
end $$;
