-- TQR Açaí · marca do painel guardada no banco (cores, fontes, nome, logo). Quem tem config.gerir muda pela tela "Personalização";
-- vale para o módulo "personalizacao". Sem nada salvo, o painel usa o arquivo admin/marca.js.
create table public.marca_painel (
  id int primary key default 1 check (id = 1),
  dados jsonb not null default '{}'::jsonb,
  atualizado_em timestamptz not null default now()
);
insert into public.marca_painel (id) values (1);
alter table public.marca_painel enable row level security;
create policy marca_sel on public.marca_painel for select to authenticated using ((select public.tem_permissao('config.gerir')));

-- leitura pública (a tela de login já usa a marca); devolve null se o módulo estiver desligado ou não houver nada salvo
create function public.obter_marca() returns jsonb
language sql stable security definer set search_path = '' as $$
  select case when public.modulo_ativo('personalizacao') and dados <> '{}'::jsonb then dados else null end
  from public.marca_painel where id = 1
$$;

create function app_private.marca_valida(p jsonb) returns jsonb
language plpgsql immutable set search_path = '' as $$
declare k text; v text; mx int; r jsonb := '{}'::jsonb; c jsonb := '{}'::jsonb; cor text;
  fontes text[] := array['Poppins','Inter','Montserrat','Nunito','Lato','Roboto','Open Sans','Source Sans 3','Work Sans','DM Sans','Playfair Display','Merriweather','Kaushan Script','Pacifico','Lobster','Oswald','Raleway'];
begin
  if jsonb_typeof(p) <> 'object' then raise exception 'marca_invalida' using errcode = '22023'; end if;
  foreach k in array array['nome','subtitulo'] loop
    if p ? k then
      v := btrim(p ->> k);
      mx := 70; if k = 'nome' then mx := 40; end if;
      if v is null or char_length(v) > mx then raise exception 'marca_invalida:%', k using errcode = '22023'; end if;
      if v <> '' then r := r || jsonb_build_object(k, v); end if;
    end if;
  end loop;
  if p ? 'logo' and coalesce(p ->> 'logo', '') <> '' then
    v := btrim(p ->> 'logo');
    if v !~ '^(https://[^\s"''<>]{4,250}|\.\./[A-Za-z0-9_./-]{1,120})$' then raise exception 'marca_invalida:logo' using errcode = '22023'; end if;
    r := r || jsonb_build_object('logo', v);
  end if;
  if p ? 'cores' then
    if jsonb_typeof(p -> 'cores') <> 'object' then raise exception 'marca_invalida:cores' using errcode = '22023'; end if;
    foreach k in array array['casca','casca2','marca','marcaHover','destaque','destaque2','fundo'] loop
      if (p -> 'cores') ? k then
        cor := p -> 'cores' ->> k;
        if cor !~ '^#[0-9a-fA-F]{6}$' then raise exception 'marca_invalida:cor_%', k using errcode = '22023'; end if;
        c := c || jsonb_build_object(k, lower(cor));
      end if;
    end loop;
    r := r || jsonb_build_object('cores', c);
  end if;
  foreach k in array array['fonteTexto','fonteTitulo','fonteDestaque'] loop
    if p ? k and coalesce(p ->> k, '') <> '' then
      if not (p ->> k) = any(fontes) then raise exception 'marca_invalida:%', k using errcode = '22023'; end if;
      r := r || jsonb_build_object(k, p ->> k);
    end if;
  end loop;
  return r;
end $$;
revoke all on function app_private.marca_valida(jsonb) from public, anon, authenticated;

create function public.admin_salvar_marca(p_dados jsonb) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.tem_permissao('config.gerir') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  perform app_private.exige_modulo('personalizacao');
  update public.marca_painel set dados = app_private.marca_valida(p_dados), atualizado_em = now() where id = 1;
end $$;

create function public.admin_restaurar_marca() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.tem_permissao('config.gerir') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  perform app_private.exige_modulo('personalizacao');
  update public.marca_painel set dados = '{}'::jsonb, atualizado_em = now() where id = 1;
end $$;

revoke all on function public.obter_marca(), public.admin_salvar_marca(jsonb), public.admin_restaurar_marca() from public, anon;
grant execute on function public.obter_marca() to anon, authenticated;
grant execute on function public.admin_salvar_marca(jsonb), public.admin_restaurar_marca() to authenticated;
