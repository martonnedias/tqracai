-- TQR Açaí · módulos e planos (base da assinatura). Cada instância liga/desliga módulos; o servidor recusa o que não está ativo.
-- Esta instância (TQR) já nasce com TODOS os módulos ativos, então nada muda para quem já usa.

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
  ordem int not null default 0
);
create table public.plano_modulos (
  plano text not null references public.planos on delete cascade,
  modulo text not null references public.modulos on delete cascade,
  primary key (plano, modulo)
);
create table public.instancia_modulos (
  modulo text primary key references public.modulos on delete cascade,
  ativo boolean not null default false,
  ate timestamptz,                       -- null = sem prazo
  origem text not null default 'manual'  -- manual | plano | licenca
);
create table public.instancia_plano (
  id int primary key default 1 check (id = 1),
  plano text references public.planos
);
insert into public.instancia_plano (id) values (1);

insert into public.modulos (codigo, nome, descricao, obrigatorio, ordem) values
  ('nucleo',        'Núcleo',            'Site, pedidos, clientes, produtos, usuários e configurações', true, 1),
  ('gestao',        'Gestão',            'Financeiro, relatórios, custos e estoque', false, 2),
  ('marketing',     'Marketing',         'CRM, mensagens, promoções e fidelidade', false, 3),
  ('pagamentos',    'Pagamentos online', 'Cobrança Pix/cartão pelo gateway', false, 4),
  ('fiscal',        'Nota fiscal',       'Emissão de nota fiscal', false, 5),
  ('personalizacao','Personalização',    'Marca própria, cores e vocabulário', false, 6);

insert into public.planos (codigo, nome, ordem) values
  ('essencial','Essencial',1), ('profissional','Profissional',2), ('completo','Completo',3);
insert into public.plano_modulos (plano, modulo) values
  ('essencial','nucleo'),
  ('profissional','nucleo'),('profissional','gestao'),('profissional','marketing'),
  ('completo','nucleo'),('completo','gestao'),('completo','marketing'),('completo','pagamentos'),('completo','fiscal'),('completo','personalizacao');

-- esta instância: tudo ativo, plano completo
insert into public.instancia_modulos (modulo, ativo, origem) select codigo, true, 'plano' from public.modulos;
update public.instancia_plano set plano = 'completo';

-- ===== leitura =====
create function public.modulo_ativo(m text) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select mo.obrigatorio or (im.ativo and (im.ate is null or im.ate > now()))
                   from public.modulos mo left join public.instancia_modulos im on im.modulo = mo.codigo
                   where mo.codigo = m), false)
$$;

create function app_private.exige_modulo(m text) returns void
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.modulo_ativo(m) then raise exception 'modulo_inativo:%', m using errcode = '42501'; end if;
end $$;
revoke all on function app_private.exige_modulo(text) from public, anon, authenticated;

create function public.meus_modulos() returns jsonb
language sql stable security definer set search_path = '' as $$
  select case when not public.is_admin() then '[]'::jsonb else
    coalesce((select jsonb_agg(codigo order by ordem) from public.modulos where public.modulo_ativo(codigo)), '[]'::jsonb) end
$$;

-- tela "Plano e módulos" (só dono)
create function public.admin_modulos() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.eh_dono() then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  return jsonb_build_object(
    'plano', (select plano from public.instancia_plano where id = 1),
    'modulos', coalesce((select jsonb_agg(jsonb_build_object('codigo', m.codigo, 'nome', m.nome, 'descricao', m.descricao,
        'obrigatorio', m.obrigatorio, 'ativo', public.modulo_ativo(m.codigo), 'ate', im.ate, 'origem', im.origem) order by m.ordem)
      from public.modulos m left join public.instancia_modulos im on im.modulo = m.codigo), '[]'::jsonb),
    'planos', coalesce((select jsonb_agg(jsonb_build_object('codigo', p.codigo, 'nome', p.nome,
        'modulos', (select coalesce(jsonb_agg(pm.modulo), '[]'::jsonb) from public.plano_modulos pm where pm.plano = p.codigo)) order by p.ordem)
      from public.planos p), '[]'::jsonb));
end $$;

-- ===== escrita (dono; no futuro, também a licença do painel mestre) =====
create function public.admin_definir_modulo(p_modulo text, p_ativo boolean) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.eh_dono() then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if (select obrigatorio from public.modulos where codigo = p_modulo) is null then raise exception 'modulo_invalido' using errcode = '22023'; end if;
  if (select obrigatorio from public.modulos where codigo = p_modulo) and not p_ativo then raise exception 'modulo_obrigatorio' using errcode = '22023'; end if;
  insert into public.instancia_modulos (modulo, ativo, origem) values (p_modulo, p_ativo, 'manual')
  on conflict (modulo) do update set ativo = excluded.ativo, origem = 'manual';
end $$;

create function public.admin_aplicar_plano(p_plano text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.eh_dono() then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if not exists (select 1 from public.planos where codigo = p_plano) then raise exception 'plano_invalido' using errcode = '22023'; end if;
  insert into public.instancia_modulos (modulo, ativo, origem)
    select m.codigo, exists (select 1 from public.plano_modulos pm where pm.plano = p_plano and pm.modulo = m.codigo), 'plano'
    from public.modulos m
  on conflict (modulo) do update set ativo = excluded.ativo, origem = 'plano', ate = null;
  update public.instancia_plano set plano = p_plano where id = 1;
end $$;

revoke all on function public.modulo_ativo(text), public.meus_modulos(), public.admin_modulos(),
  public.admin_definir_modulo(text, boolean), public.admin_aplicar_plano(text) from public, anon;
grant execute on function public.modulo_ativo(text), public.meus_modulos(), public.admin_modulos(),
  public.admin_definir_modulo(text, boolean), public.admin_aplicar_plano(text) to authenticated;

-- tabelas de módulos: só leitura para a equipe; escrita só pelas funções acima
alter table public.modulos enable row level security;
alter table public.planos enable row level security;
alter table public.plano_modulos enable row level security;
alter table public.instancia_modulos enable row level security;
alter table public.instancia_plano enable row level security;
create policy mod_sel on public.modulos for select to authenticated using ((select public.is_admin()));
create policy pla_sel on public.planos for select to authenticated using ((select public.is_admin()));
create policy plm_sel on public.plano_modulos for select to authenticated using ((select public.is_admin()));
create policy ins_sel on public.instancia_modulos for select to authenticated using ((select public.eh_dono()));
create policy inp_sel on public.instancia_plano for select to authenticated using ((select public.eh_dono()));

-- ===== trava no servidor =====
-- 1) permissões de gestão (financeiro/custos/estoque) e promoções passam a exigir o módulo; vale para RLS e RPCs que usam tem_permissao
create or replace function public.tem_permissao(p text) returns boolean
language sql stable security definer set search_path = '' as $$
  select public.is_admin() and exists (
    select 1 from public.admins a join public.perfis f on f.id = a.perfil_id
    where a.user_id = (select auth.uid()) and a.ativo and ('*' = any(f.permissoes) or p = any(f.permissoes)))
  and case split_part(p, '.', 1)
        when 'financeiro' then public.modulo_ativo('gestao')
        when 'custos'     then public.modulo_ativo('gestao')
        when 'estoque'    then public.modulo_ativo('gestao')
        when 'promocoes'  then public.modulo_ativo('marketing')
        else true end
$$;

-- 2) funções de marketing, pagamentos e nota fiscal: insere a checagem do módulo no começo do corpo
do $$
declare r record; def text;
begin
  for r in
    select p.oid, p.proname,
      case when p.proname like 'crm\_%' or p.proname in ('admin_resgatar_pontos','admin_resgatar_pontos_v2','admin_ajustar_pontos','admin_conceder_aniversario') then 'marketing'
           when p.proname like 'pagamento\_admin\_%' then 'pagamentos'
           when p.proname in ('nota_emitir','nota_cancelar') then 'fiscal' end as modulo
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and (p.proname like 'crm\_%' or p.proname in ('admin_resgatar_pontos','admin_resgatar_pontos_v2','admin_ajustar_pontos','admin_conceder_aniversario','nota_emitir','nota_cancelar')
           or p.proname like 'pagamento\_admin\_%')
  loop
    def := pg_get_functiondef(r.oid);
    if def !~* '\mbegin\M' then raise exception 'sem corpo plpgsql: %', r.proname; end if;
    def := regexp_replace(def, '\mbegin\M', format('begin perform app_private.exige_modulo(%L);', r.modulo), 'i');
    execute def;
  end loop;
end $$;

-- 3) minhas_permissoes passa a trazer também os módulos ativos
create or replace function public.minhas_permissoes() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce((select jsonb_build_object('perfil', a.perfil_id, 'nome', coalesce(a.nome, ''),
                    'permissoes', to_jsonb(f.permissoes), 'modulos', public.meus_modulos())
                   from public.admins a join public.perfis f on f.id = a.perfil_id
                   where a.user_id = (select auth.uid()) and a.ativo), 'null'::jsonb)
$$;
