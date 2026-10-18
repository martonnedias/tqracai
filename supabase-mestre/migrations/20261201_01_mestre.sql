-- Painel mestre (projeto Supabase próprio): assinantes, contratos, instâncias (lojas) e módulos liberados.
-- Guarda só gestão: nada de pedidos nem de clientes das lojas. O acesso é só do dono, com verificação em duas etapas (aal2).
-- As lojas consultam a função public.licenca(chave) com a chave da própria instância (guardada só como hash).

create schema if not exists app_private;

-- ===== quem pode entrar no painel mestre =====
create table public.administradores_mestre (
  user_id uuid primary key references auth.users on delete cascade,
  nome text,
  criado_em timestamptz not null default now()
);
alter table public.administradores_mestre enable row level security;
revoke all on public.administradores_mestre from anon, authenticated;   -- só por SQL do dono do projeto

-- só vale com verificação em duas etapas concluída (aal2)
create function public.eh_admin_mestre() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.administradores_mestre a where a.user_id = (select auth.uid()))
     and coalesce((select auth.jwt() ->> 'aal'), '') = 'aal2'
$$;
revoke all on function public.eh_admin_mestre() from public, anon;
grant execute on function public.eh_admin_mestre() to authenticated;

-- ===== catálogo: mesmos códigos de módulos e planos das lojas =====
create table public.modulos (
  codigo text primary key check (codigo ~ '^[a-z][a-z0-9_]{1,30}$'),
  nome text not null,
  descricao text,
  obrigatorio boolean not null default false,
  ordem int not null default 0
);
create table public.planos (
  codigo text primary key check (codigo ~ '^[a-z][a-z0-9_]{1,30}$'),
  nome text not null,
  preco_centavos int check (preco_centavos is null or preco_centavos >= 0),
  ativo boolean not null default true,
  ordem int not null default 0
);
create table public.plano_modulos (
  plano text not null references public.planos on delete cascade,
  modulo text not null references public.modulos on delete cascade,
  primary key (plano, modulo)
);
insert into public.modulos (codigo, nome, descricao, obrigatorio, ordem) values
  ('nucleo',        'Núcleo',            'Site, pedidos, clientes, produtos, usuários e configurações', true, 1),
  ('gestao',        'Gestão',            'Financeiro, relatórios, custos e estoque', false, 2),
  ('marketing',     'Marketing',         'CRM, mensagens, promoções e fidelidade', false, 3),
  ('pagamentos',    'Pagamentos online', 'Cobrança Pix/cartão pelo gateway', false, 4),
  ('fiscal',        'Nota fiscal',       'Emissão de nota fiscal', false, 5),
  ('personalizacao','Personalização',    'Marca própria, cores e vocabulário', false, 6);
insert into public.planos (codigo, nome, ordem) values ('essencial','Essencial',1), ('profissional','Profissional',2), ('completo','Completo',3);
insert into public.plano_modulos (plano, modulo) values
  ('essencial','nucleo'),
  ('profissional','nucleo'),('profissional','gestao'),('profissional','marketing'),
  ('completo','nucleo'),('completo','gestao'),('completo','marketing'),('completo','pagamentos'),('completo','fiscal'),('completo','personalizacao');

-- ===== assinantes e o que pertence a eles =====
create table public.assinantes (
  id uuid primary key default gen_random_uuid(),
  nome text not null check (length(trim(nome)) between 2 and 120),
  documento text check (documento is null or documento ~ '^[0-9./-]{11,18}$'),
  segmento text not null default 'outro' check (segmento in ('acai','hamburgueria','pizzaria','restaurante','outro')),
  situacao text not null default 'teste' check (situacao in ('teste','ativo','suspenso','cancelado')),
  observacoes text check (observacoes is null or length(observacoes) <= 2000),
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);
create unique index assinantes_documento_uq on public.assinantes (documento) where documento is not null;

create table public.assinante_contatos (
  id uuid primary key default gen_random_uuid(),
  assinante_id uuid not null references public.assinantes on delete cascade,
  nome text not null check (length(trim(nome)) between 2 and 120),
  cargo text check (cargo is null or length(cargo) <= 60),
  email text check (email is null or email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
  whatsapp text check (whatsapp is null or whatsapp ~ '^[0-9]{10,13}$'),
  principal boolean not null default false,
  criado_em timestamptz not null default now()
);
create index on public.assinante_contatos (assinante_id);
create unique index assinante_contato_principal_uq on public.assinante_contatos (assinante_id) where principal;

create table public.assinante_contratos (
  id uuid primary key default gen_random_uuid(),
  assinante_id uuid not null references public.assinantes on delete cascade,
  plano text not null references public.planos,
  valor_centavos int not null default 0 check (valor_centavos >= 0),
  inicio date not null default current_date,
  fim date check (fim is null or fim >= inicio),
  situacao text not null default 'ativo' check (situacao in ('ativo','suspenso','encerrado')),
  vencimento_dia int check (vencimento_dia is null or vencimento_dia between 1 and 28),
  forma_pagamento text check (forma_pagamento is null or length(forma_pagamento) <= 40),
  criado_em timestamptz not null default now()
);
create index on public.assinante_contratos (assinante_id);
create unique index assinante_contrato_ativo_uq on public.assinante_contratos (assinante_id) where situacao = 'ativo';   -- um contrato ativo por vez

-- instância = uma loja instalada (site + banco próprio)
create table public.assinante_instancias (
  id uuid primary key default gen_random_uuid(),
  assinante_id uuid not null references public.assinantes on delete cascade,
  nome text not null check (length(trim(nome)) between 2 and 80),
  url_site text check (url_site is null or url_site ~ '^https://[^\s"''<>]{4,200}$'),
  supabase_ref text check (supabase_ref is null or supabase_ref ~ '^[a-z]{20}$'),
  tema text,
  versao text,
  ativo boolean not null default true,
  chave_prefixo text,                      -- só para o dono reconhecer a chave (primeiros caracteres)
  ultimo_contato timestamptz,
  criado_em timestamptz not null default now()
);
create index on public.assinante_instancias (assinante_id);

-- a chave da instância nunca é lida pelo painel: só a função licenca() a compara (por hash)
create table public.instancia_chaves (
  instancia_id uuid primary key references public.assinante_instancias on delete cascade,
  chave_hash text not null unique,
  gerada_em timestamptz not null default now()
);
alter table public.instancia_chaves enable row level security;
revoke all on public.instancia_chaves from anon, authenticated;

-- exceções do plano, só para aquela loja
create table public.instancia_modulos (
  instancia_id uuid not null references public.assinante_instancias on delete cascade,
  modulo text not null references public.modulos on delete cascade,
  ativo boolean not null,
  ate timestamptz,                          -- null = sem prazo
  primary key (instancia_id, modulo)
);

-- histórico: só entra, nunca muda nem some
create table public.assinante_eventos (
  id bigint generated always as identity primary key,
  assinante_id uuid references public.assinantes on delete set null,
  instancia_id uuid references public.assinante_instancias on delete set null,
  tipo text not null,
  detalhe jsonb not null default '{}'::jsonb,
  por uuid,
  em timestamptz not null default now()
);
create index on public.assinante_eventos (assinante_id, em desc);

-- ===== segurança por linha: só o administrador com aal2 =====
do $$
declare t text;
begin
  foreach t in array array['modulos','planos','plano_modulos','assinantes','assinante_contatos','assinante_contratos','assinante_instancias','instancia_modulos'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
    execute format('create policy mestre_tudo on public.%I for all to authenticated using ((select public.eh_admin_mestre())) with check ((select public.eh_admin_mestre()))', t);
  end loop;
end $$;
alter table public.assinante_eventos enable row level security;
revoke all on public.assinante_eventos from anon, authenticated;
grant select on public.assinante_eventos to authenticated;
create policy eventos_leitura on public.assinante_eventos for select to authenticated using ((select public.eh_admin_mestre()));

-- ===== registro automático de mudanças =====
create function app_private.registra_evento() returns trigger
language plpgsql security definer set search_path = '' as $$
declare ass uuid; ins uuid; novo jsonb; velho jsonb; det jsonb;
begin
  novo := case when tg_op = 'DELETE' then null else to_jsonb(new) end;
  velho := case when tg_op = 'INSERT' then null else to_jsonb(old) end;
  if tg_table_name = 'assinantes' then ass := coalesce((novo ->> 'id'), (velho ->> 'id'))::uuid;
  elsif tg_table_name = 'assinante_instancias' then ass := coalesce((novo ->> 'assinante_id'), (velho ->> 'assinante_id'))::uuid; ins := coalesce((novo ->> 'id'), (velho ->> 'id'))::uuid;
  elsif tg_table_name = 'instancia_modulos' then ins := coalesce((novo ->> 'instancia_id'), (velho ->> 'instancia_id'))::uuid;
       select i.assinante_id into ass from public.assinante_instancias i where i.id = ins;
  else ass := coalesce((novo ->> 'assinante_id'), (velho ->> 'assinante_id'))::uuid;
  end if;
  det := jsonb_build_object('tabela', tg_table_name, 'antes', velho, 'depois', novo);
  det := det #- '{antes,observacoes}' #- '{depois,observacoes}';          -- texto livre não vai para o histórico
  insert into public.assinante_eventos (assinante_id, instancia_id, tipo, detalhe, por)
  values (ass, ins, tg_table_name || '.' || lower(tg_op), det, (select auth.uid()));
  return coalesce(new, old);
end $$;
revoke all on function app_private.registra_evento() from public, anon, authenticated;

create function app_private.atualiza_em() returns trigger
language plpgsql set search_path = '' as $$
begin new.atualizado_em := now(); return new; end $$;
create trigger assinantes_atualiza before update on public.assinantes for each row execute function app_private.atualiza_em();

do $$
declare t text;
begin
  foreach t in array array['assinantes','assinante_contatos','assinante_contratos','assinante_instancias','instancia_modulos'] loop
    execute format('create trigger %I after insert or update or delete on public.%I for each row execute function app_private.registra_evento()', t || '_evento', t);
  end loop;
end $$;

-- módulo obrigatório nunca fica desligado
create function app_private.modulo_obrigatorio_fica() returns trigger
language plpgsql set search_path = '' as $$
begin
  if not new.ativo and (select obrigatorio from public.modulos where codigo = new.modulo) then
    raise exception 'modulo_obrigatorio' using errcode = '22023';
  end if;
  return new;
end $$;
create trigger instancia_modulos_obrig before insert or update on public.instancia_modulos for each row execute function app_private.modulo_obrigatorio_fica();

-- ===== chave da instância: gerada uma vez, mostrada uma vez =====
create function public.admin_gerar_chave(p_instancia uuid) returns text
language plpgsql security definer set search_path = '' as $$
declare chave text;
begin
  if not public.eh_admin_mestre() then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if not exists (select 1 from public.assinante_instancias where id = p_instancia) then raise exception 'instancia_invalida' using errcode = '22023'; end if;
  chave := 'tqrk_' || encode(extensions.gen_random_bytes(24), 'hex');
  insert into public.instancia_chaves (instancia_id, chave_hash) values (p_instancia, encode(extensions.digest(chave, 'sha256'), 'hex'))
  on conflict (instancia_id) do update set chave_hash = excluded.chave_hash, gerada_em = now();
  update public.assinante_instancias set chave_prefixo = left(chave, 9) where id = p_instancia;
  insert into public.assinante_eventos (assinante_id, instancia_id, tipo, por)
    select i.assinante_id, i.id, 'instancia.chave_gerada', (select auth.uid()) from public.assinante_instancias i where i.id = p_instancia;
  return chave;
end $$;
revoke all on function public.admin_gerar_chave(uuid) from public, anon;
grant execute on function public.admin_gerar_chave(uuid) to authenticated;

-- ===== licença: o que a loja pergunta a cada 5 minutos =====
-- Resposta mínima, sem dados de outras lojas. Chave inválida e chave de loja desativada dão a mesma resposta.
create function public.licenca(p_chave text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare ins public.assinante_instancias; ass public.assinantes; con public.assinante_contratos; mods jsonb; situ text;
begin
  if p_chave is null or p_chave !~ '^tqrk_[0-9a-f]{48}$' then return jsonb_build_object('ok', false); end if;
  select i.* into ins from public.assinante_instancias i join public.instancia_chaves k on k.instancia_id = i.id
   where k.chave_hash = encode(extensions.digest(p_chave, 'sha256'), 'hex') and i.ativo;
  if not found then return jsonb_build_object('ok', false); end if;
  select * into ass from public.assinantes where id = ins.assinante_id;
  select * into con from public.assinante_contratos where assinante_id = ass.id and situacao = 'ativo' limit 1;
  situ := case when ass.situacao in ('suspenso','cancelado') then ass.situacao
               when con.id is null and ass.situacao <> 'teste' then 'suspenso'
               else ass.situacao end;
  select coalesce(jsonb_agg(m.codigo order by m.ordem), '[]'::jsonb) into mods
    from public.modulos m
   where m.obrigatorio
      or coalesce((select o.ativo and (o.ate is null or o.ate > now()) from public.instancia_modulos o where o.instancia_id = ins.id and o.modulo = m.codigo),
                  exists (select 1 from public.plano_modulos pm where pm.plano = con.plano and pm.modulo = m.codigo));
  update public.assinante_instancias set ultimo_contato = now() where id = ins.id;
  return jsonb_build_object('ok', true, 'situacao', situ, 'plano', con.plano, 'modulos', mods, 'verificado_em', now());
end $$;
revoke all on function public.licenca(text) from public;
grant execute on function public.licenca(text) to anon, authenticated;

-- ===== primeiro assinante: a loja de açaí (dados públicos do projeto; contatos e documento o dono preenche no painel) =====
insert into public.assinantes (nome, segmento, situacao) values ('TQR Açaí', 'acai', 'ativo');
insert into public.assinante_contratos (assinante_id, plano, situacao) select id, 'completo', 'ativo' from public.assinantes where nome = 'TQR Açaí';
insert into public.assinante_instancias (assinante_id, nome, url_site, supabase_ref, tema, versao)
  select id, 'TQR Açaí', 'https://martonnedias.github.io/tqracai/', 'elaczoriyaejkixkubxn', 'acai', 'item-3' from public.assinantes where nome = 'TQR Açaí';
