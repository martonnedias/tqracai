-- TQR Açaí · nota fiscal em HOMOLOGAÇÃO (simulada, sem valor fiscal) + exportação para o contador
-- Nada aqui fala com a SEFAZ. O emissor real (Focus NFe, eNotas, etc.) entra depois, com os dados do contador, trocando só `nota_emitir`.
-- Valores padrão de NCM/CFOP/CSOSN são EXEMPLOS comuns e precisam ser confirmados pelo contador.
insert into public.configuracoes (chave, valor, descricao) values
 ('nf_ambiente','homologacao','Ambiente da nota fiscal: homologacao (simulada) ou producao (exige emissor real)'),
 ('nf_emissao_auto','false','Emitir nota automaticamente quando o pedido é pago'),
 ('nf_tipo','nfce','Tipo de nota: nfce (consumidor) ou nfe'),
 ('nf_regime','simples','Regime tributário: simples, presumido ou real'),
 ('nf_serie','1','Série da nota'),
 ('nf_ie','','Inscrição estadual'),
 ('nf_im','','Inscrição municipal')
on conflict (chave) do nothing;

alter table public.produtos
  add column ncm text not null default '21069090' check (ncm ~ '^[0-9]{8}$'),
  add column cfop text not null default '5102' check (cfop ~ '^[0-9]{4}$'),
  add column csosn text not null default '102' check (csosn ~ '^[0-9]{2,3}$'),
  add column origem_mercadoria text not null default '0' check (origem_mercadoria ~ '^[0-8]$');

create sequence public.nota_numero_seq;

create table public.notas_fiscais (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references public.pedidos(id) on delete restrict,
  tipo text not null default 'nfce',
  serie text not null,
  numero bigint not null,
  ambiente text not null check (ambiente in ('homologacao','producao')),
  status text not null default 'emitida' check (status in ('emitida','cancelada','rejeitada')),
  chave text,
  protocolo text,
  valor_total numeric(12,2) not null,
  emitente jsonb not null default '{}'::jsonb,        -- foto dos dados da loja na emissão
  destinatario jsonb not null default '{}'::jsonb,
  itens jsonb not null default '[]'::jsonb,
  xml text,
  motivo_cancelamento text,
  emitido_em timestamptz not null default now(),
  cancelado_em timestamptz,
  criado_por uuid
);
create unique index notas_numero_uk on public.notas_fiscais (tipo, serie, numero, ambiente);
create unique index notas_pedido_ativa_uk on public.notas_fiscais (pedido_id) where status = 'emitida';
create index notas_emitido_idx on public.notas_fiscais (emitido_em desc);
alter table public.notas_fiscais enable row level security;
create policy nf_sel on public.notas_fiscais for select to authenticated using ((select public.tem_permissao('financeiro.ver')));

create function app_private.nota_emitir_interno(p_pedido uuid, p_usuario uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare ped public.pedidos; cli public.clientes; cfg jsonb; amb text; serie text; n bigint; chv text; itens jsonb; emit jsonb; xml text; nid uuid; hoje text;
begin
  select * into ped from public.pedidos where id = p_pedido for update;
  if not found then raise exception 'pedido_inexistente' using errcode = '22023'; end if;
  if ped.status not in ('pago','saiu_entrega','entregue') then raise exception 'pedido_nao_pago' using errcode = '22023'; end if;
  if exists (select 1 from public.notas_fiscais where pedido_id = p_pedido and status = 'emitida') then raise exception 'nota_ja_emitida' using errcode = '22023'; end if;
  select jsonb_object_agg(c.chave, c.valor) into cfg from public.configuracoes c where c.chave like 'nf\_%' or c.chave like 'loja\_%';
  amb := coalesce(cfg->>'nf_ambiente', 'homologacao');
  if amb <> 'homologacao' then raise exception 'producao_indisponivel' using errcode = '22023'; end if;  -- emissor real ainda não conectado
  serie := coalesce(nullif(cfg->>'nf_serie', ''), '1');
  n := nextval('public.nota_numero_seq');
  select * into cli from public.clientes where id = ped.cliente_id;
  select coalesce(jsonb_agg(jsonb_build_object('descricao', i.nome_produto, 'quantidade', i.quantidade, 'valor_unitario', i.preco_unitario,
         'valor', i.subtotal, 'brinde', i.brinde, 'ncm', coalesce(pr.ncm, '21069090'), 'cfop', coalesce(pr.cfop, '5102'),
         'csosn', coalesce(pr.csosn, '102'), 'origem', coalesce(pr.origem_mercadoria, '0')) order by i.id), '[]'::jsonb)
    into itens from public.itens_pedido i left join public.produtos pr on pr.id = i.produto_id where i.pedido_id = p_pedido;
  emit := jsonb_build_object('nome', cfg->>'loja_nome', 'razao', cfg->>'loja_razao', 'cnpj', cfg->>'loja_cnpj', 'ie', cfg->>'nf_ie',
          'im', cfg->>'nf_im', 'regime', cfg->>'nf_regime', 'endereco', cfg->>'loja_endereco');
  hoje := to_char(now() at time zone 'America/Fortaleza', 'YYMM');
  chv := '22' || hoje || lpad(regexp_replace(coalesce(cfg->>'loja_cnpj', ''), '\D', '', 'g'), 14, '0') || '65' || lpad(serie, 3, '0') || lpad(n::text, 9, '0') || '1' || lpad((abs(hashtext(p_pedido::text)) % 100000000)::text, 8, '0');
  chv := left(chv, 43) || '0';
  xml := '<?xml version="1.0" encoding="UTF-8"?><!-- HOMOLOGAÇÃO: documento SIMULADO, SEM VALOR FISCAL --><NFe><infNFe Id="NFe' || chv || '">'
      || '<ide><serie>' || serie || '</serie><nNF>' || n || '</nNF><tpAmb>2</tpAmb><dhEmi>' || to_char(now(), 'YYYY-MM-DD"T"HH24:MI:SSOF') || '</dhEmi></ide>'
      || '<emit><CNPJ>' || regexp_replace(coalesce(cfg->>'loja_cnpj', ''), '\D', '', 'g') || '</CNPJ><xNome>' || replace(replace(coalesce(cfg->>'loja_razao', ''), '&', '&amp;'), '<', '&lt;') || '</xNome></emit>'
      || '<total><vNF>' || ped.total || '</vNF></total><infAdic><infCpl>Pedido ' || ped.codigo || ' - AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL</infCpl></infAdic></infNFe></NFe>';
  insert into public.notas_fiscais (pedido_id, tipo, serie, numero, ambiente, chave, protocolo, valor_total, emitente, destinatario, itens, xml, criado_por)
  values (p_pedido, coalesce(cfg->>'nf_tipo', 'nfce'), serie, n, amb, chv, 'HOMOLOG-' || lpad(n::text, 9, '0'), ped.total, emit,
          jsonb_build_object('nome', cli.nome, 'whatsapp', cli.whatsapp), itens, xml, p_usuario)
  returning id into nid;
  return nid;
end $$;
revoke all on function app_private.nota_emitir_interno(uuid, uuid) from public, anon, authenticated;

create function public.nota_emitir(p_pedido uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
begin
  if not public.tem_permissao('financeiro.gerir') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  return app_private.nota_emitir_interno(p_pedido, (select auth.uid()));
end $$;

create function public.nota_cancelar(p_nota uuid, p_motivo text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.tem_permissao('financeiro.gerir') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if length(trim(coalesce(p_motivo, ''))) < 15 then raise exception 'motivo_curto' using errcode = '22023'; end if;
  update public.notas_fiscais set status = 'cancelada', motivo_cancelamento = trim(p_motivo), cancelado_em = now()
    where id = p_nota and status = 'emitida';
  if not found then raise exception 'nota_nao_cancelavel' using errcode = '22023'; end if;
end $$;

-- emissão automática quando o pedido é pago (se ligada); falha de nota nunca trava o pedido
create function app_private.pedido_nota_auto() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.status = 'pago' and old.status is distinct from 'pago'
     and coalesce((select valor from public.configuracoes where chave = 'nf_emissao_auto'), 'false') = 'true' then
    begin
      perform app_private.nota_emitir_interno(new.id, null);
    exception when others then null;
    end;
  end if;
  return new;
end $$;
create trigger pedidos_nota_auto after update of status on public.pedidos
  for each row execute function app_private.pedido_nota_auto();

revoke all on function public.nota_emitir(uuid), public.nota_cancelar(uuid, text) from public, anon;
grant execute on function public.nota_emitir(uuid), public.nota_cancelar(uuid, text) to authenticated;
