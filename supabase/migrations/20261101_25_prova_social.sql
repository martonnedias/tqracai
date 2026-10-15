-- TQR Açaí · aviso de pedidos recentes no site ("prova social"). Configurado no painel (módulo marketing).
-- Pedidos REAIS aparecem sem dado pessoal sensível (só primeiro nome ou inicial, bairro e quantidade, nunca telefone/endereço).
-- Itens de EXEMPLO são sempre mostrados com a marca "Exemplo" no site (o servidor devolve tipo = 'exemplo' e o site não permite esconder a marca).
create table public.prova_social (
  id int primary key default 1 check (id = 1),
  dados jsonb not null default '{}'::jsonb,
  atualizado_em timestamptz not null default now()
);
insert into public.prova_social (id) values (1);
alter table public.prova_social enable row level security;
create policy ps_sel on public.prova_social for select to authenticated using ((select public.tem_permissao('config.gerir')));

create function app_private.prova_social_valida(p jsonb) returns jsonb
language plpgsql immutable set search_path = '' as $$
declare r jsonb := '{}'::jsonb; k text; v text; n int; arr jsonb; it jsonb; lista jsonb := '[]'::jsonb; q int;
begin
  if jsonb_typeof(p) <> 'object' then raise exception 'ps_invalido' using errcode = '22023'; end if;
  r := jsonb_build_object('ativo', coalesce((p ->> 'ativo')::boolean, false));
  v := coalesce(p ->> 'modo', 'real');
  if v not in ('real','ficticio','misto') then raise exception 'ps_invalido:modo' using errcode = '22023'; end if;
  r := r || jsonb_build_object('modo', v);
  v := coalesce(p ->> 'posicao', 'inferior_esquerda');
  if v not in ('inferior_esquerda','inferior_direita','superior_centro') then raise exception 'ps_invalido:posicao' using errcode = '22023'; end if;
  r := r || jsonb_build_object('posicao', v);
  v := coalesce(p ->> 'mostrar_nome', 'primeiro');
  if v not in ('primeiro','inicial','anonimo') then raise exception 'ps_invalido:mostrar_nome' using errcode = '22023'; end if;
  r := r || jsonb_build_object('mostrar_nome', v);
  r := r || jsonb_build_object('mostrar_bairro', coalesce((p ->> 'mostrar_bairro')::boolean, true),
                               'mostrar_quantidade', coalesce((p ->> 'mostrar_quantidade')::boolean, true));
  foreach k in array array['locais','dispositivos'] loop
    arr := coalesce(p -> k, '[]'::jsonb);
    if jsonb_typeof(arr) <> 'array' then raise exception 'ps_invalido:%', k using errcode = '22023'; end if;
    for it in select * from jsonb_array_elements(arr) loop
      v := it #>> '{}';
      if k = 'locais' and v not in ('inicio','blog','politicas') then raise exception 'ps_invalido:locais' using errcode = '22023'; end if;
      if k = 'dispositivos' and v not in ('desktop','mobile') then raise exception 'ps_invalido:dispositivos' using errcode = '22023'; end if;
    end loop;
    r := r || jsonb_build_object(k, arr);
  end loop;
  foreach k in array array['atraso_s','intervalo_s','duracao_s','max_por_visita','janela_horas'] loop
    n := coalesce((p ->> k)::int, case k when 'atraso_s' then 8 when 'intervalo_s' then 25 when 'duracao_s' then 6 when 'max_por_visita' then 6 else 24 end);
    if (k = 'atraso_s' and n not between 0 and 120) or (k = 'intervalo_s' and n not between 5 and 300) or (k = 'duracao_s' and n not between 3 and 20)
       or (k = 'max_por_visita' and n not between 1 and 30) or (k = 'janela_horas' and n not between 1 and 72) then
      raise exception 'ps_invalido:%', k using errcode = '22023'; end if;
    r := r || jsonb_build_object(k, n);
  end loop;
  arr := coalesce(p -> 'ficticios', '[]'::jsonb);
  if jsonb_typeof(arr) <> 'array' or jsonb_array_length(arr) > 30 then raise exception 'ps_invalido:ficticios' using errcode = '22023'; end if;
  for it in select * from jsonb_array_elements(arr) loop
    if jsonb_typeof(it) <> 'object' then raise exception 'ps_invalido:ficticios' using errcode = '22023'; end if;
    v := btrim(coalesce(it ->> 'nome', ''));
    if char_length(v) < 2 or char_length(v) > 30 or v ~ '[<>"&]' then raise exception 'ps_invalido:ficticio_nome' using errcode = '22023'; end if;
    q := coalesce((it ->> 'quantidade')::int, 1);
    if q not between 1 and 50 then raise exception 'ps_invalido:ficticio_quantidade' using errcode = '22023'; end if;
    lista := lista || jsonb_build_array(jsonb_build_object('nome', v, 'bairro', left(btrim(coalesce(it ->> 'bairro', '')), 40), 'quantidade', q));
  end loop;
  return r || jsonb_build_object('ficticios', lista);
end $$;
revoke all on function app_private.prova_social_valida(jsonb) from public, anon, authenticated;

create function public.admin_salvar_prova_social(p_dados jsonb) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.tem_permissao('config.gerir') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  perform app_private.exige_modulo('marketing');
  update public.prova_social set dados = app_private.prova_social_valida(p_dados), atualizado_em = now() where id = 1;
end $$;

-- pública: devolve a configuração e os itens já saneados (nunca dados pessoais completos)
create function public.obter_prova_social() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare d jsonb; itens jsonb := '[]'::jsonb; modo text; mn text;
begin
  if not public.modulo_ativo('marketing') then return null; end if;
  select dados into d from public.prova_social where id = 1;
  if d is null or coalesce((d ->> 'ativo')::boolean, false) is not true then return null; end if;
  modo := d ->> 'modo'; mn := coalesce(d ->> 'mostrar_nome', 'primeiro');
  if modo in ('real','misto') then
    select coalesce(jsonb_agg(t.x order by (t.x ->> 'minutos')::int), '[]'::jsonb) into itens from (
      select jsonb_build_object(
               'id', left(md5(p.id::text), 12), 'tipo', 'real',
               'nome', case mn when 'anonimo' then 'Alguém' when 'inicial' then upper(left(btrim(c.nome), 1)) || '.' else split_part(btrim(c.nome), ' ', 1) end,
               'bairro', case when coalesce((d ->> 'mostrar_bairro')::boolean, true) and nullif(btrim(p.bairro), '') is not null then btrim(p.bairro) end,
               'quantidade', case when coalesce((d ->> 'mostrar_quantidade')::boolean, true) then (select sum(i.quantidade) from public.itens_pedido i where i.pedido_id = p.id) end,
               'minutos', greatest(0, floor(extract(epoch from (now() - p.criado_em)) / 60))::int) as x
        from public.pedidos p join public.clientes c on c.id = p.cliente_id
       where p.status <> 'cancelado' and c.nome !~* '\(exemplo\)|teste'
         and p.criado_em > now() - make_interval(hours => coalesce((d ->> 'janela_horas')::int, 24))
       order by p.criado_em desc limit 15) t;
  end if;
  if modo in ('ficticio','misto') then
    itens := itens || coalesce((select jsonb_agg(jsonb_build_object('id', 'ex' || (o - 1), 'tipo', 'exemplo', 'nome', e ->> 'nome', 'bairro', nullif(e ->> 'bairro', ''), 'quantidade', (e ->> 'quantidade')::int))
                                from jsonb_array_elements(d -> 'ficticios') with ordinality as t(e, o)), '[]'::jsonb);
  end if;
  return jsonb_build_object('modo', modo, 'locais', d -> 'locais', 'dispositivos', d -> 'dispositivos', 'posicao', d ->> 'posicao',
    'atraso_s', (d ->> 'atraso_s')::int, 'intervalo_s', (d ->> 'intervalo_s')::int, 'duracao_s', (d ->> 'duracao_s')::int,
    'max_por_visita', (d ->> 'max_por_visita')::int, 'itens', itens);
end $$;

revoke all on function public.admin_salvar_prova_social(jsonb), public.obter_prova_social() from public, anon;
grant execute on function public.obter_prova_social() to anon, authenticated;
grant execute on function public.admin_salvar_prova_social(jsonb) to authenticated;
