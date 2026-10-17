-- Marca do SITE público (nome, logo e cores), guardada junto da marca do painel em marca_painel.dados -> 'site'.
-- A leitura pública continua em obter_marca(); sem nada salvo (ou módulo "personalizacao" desligado) o site usa o visual padrão.
create or replace function app_private.marca_valida(p jsonb) returns jsonb
language plpgsql immutable set search_path = '' as $$
declare k text; v text; mx int; r jsonb := '{}'::jsonb; c jsonb := '{}'::jsonb; cor text; s jsonb; sr jsonb := '{}'::jsonb;
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
  -- site público
  if p ? 'site' then
    s := p -> 'site';
    if jsonb_typeof(s) <> 'object' then raise exception 'marca_invalida:site' using errcode = '22023'; end if;
    foreach k in array array['nome','slogan'] loop
      if s ? k then
        v := btrim(s ->> k);
        mx := 80; if k = 'nome' then mx := 40; end if;
        if v is null or char_length(v) > mx or v ~ '[<>]' then raise exception 'marca_invalida:site_%', k using errcode = '22023'; end if;
        if v <> '' then sr := sr || jsonb_build_object(k, v); end if;
      end if;
    end loop;
    if s ? 'logo' and coalesce(s ->> 'logo', '') <> '' then
      v := btrim(s ->> 'logo');
      if v !~ '^(https://[^\s"''<>]{4,250}|img/[A-Za-z0-9_./-]{1,120})$' then raise exception 'marca_invalida:site_logo' using errcode = '22023'; end if;
      sr := sr || jsonb_build_object('logo', v);
    end if;
    if s ? 'cores' then
      if jsonb_typeof(s -> 'cores') <> 'object' then raise exception 'marca_invalida:site_cores' using errcode = '22023'; end if;
      c := '{}'::jsonb;
      foreach k in array array['destaque','destaque2','fundo','fundo2'] loop
        if (s -> 'cores') ? k then
          cor := s -> 'cores' ->> k;
          if cor !~ '^#[0-9a-fA-F]{6}$' then raise exception 'marca_invalida:site_cor_%', k using errcode = '22023'; end if;
          c := c || jsonb_build_object(k, lower(cor));
        end if;
      end loop;
      sr := sr || jsonb_build_object('cores', c);
    end if;
    if sr <> '{}'::jsonb then r := r || jsonb_build_object('site', sr); end if;
  end if;
  return r;
end $$;
revoke all on function app_private.marca_valida(jsonb) from public, anon, authenticated;
