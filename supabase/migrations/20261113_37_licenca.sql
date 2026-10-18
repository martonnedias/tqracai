-- Licença: a loja confirma com o painel mestre, a cada 5 minutos, o plano e os módulos liberados.
-- Sem chave configurada, nada muda (a loja segue como hoje). Com chave:
--   * a resposta do mestre liga/desliga os módulos (instancia_modulos.origem = 'licenca');
--   * contrato suspenso ou cancelado, ou mais de 10 dias sem confirmar, BLOQUEIA os módulos pagos (só o núcleo continua)
--     e o painel AVISA o dono. O site e os pedidos dos clientes finais nunca são bloqueados (o núcleo não desliga).
create extension if not exists http with schema extensions;
create extension if not exists pg_cron;

create table public.licenca_estado (
  id int primary key default 1 check (id = 1),
  ativa boolean not null default false,        -- há chave configurada
  ativada_em timestamptz,
  situacao text,                               -- teste | ativo | suspenso | cancelado (o que o mestre respondeu)
  plano text,
  modulos jsonb not null default '[]'::jsonb,
  verificado_em timestamptz,                   -- última resposta válida do mestre
  tentativa_em timestamptz,
  erro text
);
insert into public.licenca_estado (id) values (1);
alter table public.licenca_estado enable row level security;
revoke all on public.licenca_estado from anon, authenticated;

-- a licença vale? (sem chave = sempre vale; com chave: contrato ok e confirmado nos últimos 10 dias)
create function app_private.licenca_vigente() returns boolean
language sql stable security definer set search_path = '' as $$
  select case when not e.ativa then true
              else (e.verificado_em is null or e.situacao in ('ativo', 'teste'))
                   and coalesce(e.verificado_em, e.ativada_em) > now() - interval '10 days' end
  from public.licenca_estado e where e.id = 1
$$;
revoke all on function app_private.licenca_vigente() from public, anon, authenticated;

create or replace function public.modulo_ativo(m text) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select mo.obrigatorio or (app_private.licenca_vigente() and im.ativo and (im.ate is null or im.ate > now()))
                   from public.modulos mo left join public.instancia_modulos im on im.modulo = mo.codigo
                   where mo.codigo = m), false)
$$;

-- aplica a resposta do mestre
create function app_private.aplicar_licenca(j jsonb) returns void
language plpgsql security definer set search_path = '' as $$
declare cod text;
begin
  update public.licenca_estado set situacao = j ->> 'situacao', plano = j ->> 'plano', modulos = coalesce(j -> 'modulos', '[]'::jsonb),
         verificado_em = now(), tentativa_em = now(), erro = null where id = 1;
  if j ->> 'plano' is not null and exists (select 1 from public.planos where codigo = j ->> 'plano') then
    update public.instancia_plano set plano = j ->> 'plano' where id = 1;
  end if;
  for cod in select codigo from public.modulos loop
    insert into public.instancia_modulos (modulo, ativo, origem) values (cod, coalesce(j -> 'modulos', '[]'::jsonb) ? cod, 'licenca')
    on conflict (modulo) do update set ativo = excluded.ativo, ate = null, origem = 'licenca';
  end loop;
end $$;
revoke all on function app_private.aplicar_licenca(jsonb) from public, anon, authenticated;

-- pergunta ao mestre (chamada pelo agendador e pelo botão "Verificar agora")
create function app_private.sincronizar_licenca() returns void
language plpgsql security definer set search_path = '' as $$
declare chave text; est public.licenca_estado; resp extensions.http_response; j jsonb;
begin
  select * into est from public.licenca_estado where id = 1;
  if not est.ativa then return; end if;
  select decrypted_secret into chave from vault.decrypted_secrets where name = 'licenca_chave' limit 1;
  if chave is null then update public.licenca_estado set tentativa_em = now(), erro = 'sem_chave' where id = 1; return; end if;
  begin
    perform extensions.http_set_curlopt('CURLOPT_TIMEOUT', '8');
    select * into resp from extensions.http((
      'POST', 'https://brhvzfipycswhpwkfqdg.supabase.co/rest/v1/rpc/licenca',
      array[extensions.http_header('apikey', 'sb_publishable_sLySnv5DxnrD7ujCeirbZw_vR_kf9KN')],
      'application/json', json_build_object('p_chave', chave)::text)::extensions.http_request);
    if resp.status <> 200 then raise exception 'http_%', resp.status; end if;
    j := resp.content::jsonb;
    if (j ->> 'ok') = 'true' then perform app_private.aplicar_licenca(j);
    else update public.licenca_estado set tentativa_em = now(), erro = 'chave_recusada' where id = 1; end if;
  exception when others then
    update public.licenca_estado set tentativa_em = now(), erro = left(sqlerrm, 200) where id = 1;
  end;
end $$;
revoke all on function app_private.sincronizar_licenca() from public, anon, authenticated;

select cron.schedule('licenca_sync', '*/5 * * * *', 'select app_private.sincronizar_licenca()');

-- ===== painel da loja: ver o estado, colar a chave, verificar agora =====
create function public.licenca_status() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare e public.licenca_estado; vig boolean; dias numeric; aviso text; nivel text;
begin
  if not public.is_admin() then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  select * into e from public.licenca_estado where id = 1;
  vig := app_private.licenca_vigente();
  if e.ativa then
    dias := 10 - extract(epoch from (now() - coalesce(e.verificado_em, e.ativada_em))) / 86400;
    if e.situacao in ('suspenso', 'cancelado') then
      nivel := 'bloqueado';
      aviso := case when e.situacao = 'suspenso' then 'A assinatura está suspensa. Os módulos pagos ficam bloqueados até regularizar. O site e os pedidos continuam funcionando.'
                    else 'A assinatura foi cancelada. Os módulos pagos estão bloqueados. O site e os pedidos continuam funcionando.' end;
    elsif not vig then
      nivel := 'bloqueado';
      aviso := 'Não conseguimos confirmar a licença há mais de 10 dias. Os módulos pagos foram bloqueados até a confirmação. O site e os pedidos continuam funcionando.';
    elsif e.erro is not null and dias <= 3 then
      nivel := 'atencao';
      aviso := 'Não estamos conseguindo confirmar a licença. Se continuar assim, os módulos pagos serão bloqueados em ' || greatest(ceil(dias), 0)::int || ' dia(s).';
    end if;
  end if;
  return jsonb_build_object('ativa', e.ativa, 'situacao', e.situacao, 'plano', e.plano, 'verificado_em', e.verificado_em, 'tentativa_em', e.tentativa_em,
    'erro', e.erro, 'vigente', vig, 'nivel', nivel, 'aviso', aviso);
end $$;

create function public.admin_definir_licenca(p_chave text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare sid uuid;
begin
  if not public.eh_dono() then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if p_chave is null or btrim(p_chave) !~ '^tqrk_[0-9a-f]{48}$' then raise exception 'chave_invalida' using errcode = '22023'; end if;
  select id into sid from vault.secrets where name = 'licenca_chave';
  if sid is null then perform vault.create_secret(btrim(p_chave), 'licenca_chave', 'Chave de licença do painel mestre');
  else perform vault.update_secret(sid, btrim(p_chave)); end if;
  update public.licenca_estado set ativa = true, ativada_em = now(), situacao = null, verificado_em = null, erro = null, tentativa_em = null where id = 1;
  perform app_private.sincronizar_licenca();
  return public.licenca_status();
end $$;

create function public.admin_sincronizar_agora() returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  if not public.eh_dono() then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  perform app_private.sincronizar_licenca();
  return public.licenca_status();
end $$;

revoke all on function public.licenca_status(), public.admin_definir_licenca(text), public.admin_sincronizar_agora() from public, anon;
grant execute on function public.licenca_status(), public.admin_definir_licenca(text), public.admin_sincronizar_agora() to authenticated;
