-- TQR Açaí · cadastro de data de nascimento pelo painel e resgate de brinde com nascimento
-- O dono/atendente completa o cadastro do cliente (nascimento, e-mail, nome) e, na hora de resgatar o brinde,
-- pode informar o nascimento que o cliente esqueceu de cadastrar (vale para o brinde de aniversário).

create function public.admin_atualizar_cliente(p_cliente uuid, p_nome text default null, p_nascimento date default null,
  p_email text default null, p_observacoes text default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.tem_permissao('clientes.editar') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if p_nascimento is not null and (p_nascimento > current_date or p_nascimento < date '1900-01-01') then
    raise exception 'nascimento_invalido' using errcode = '22023';
  end if;
  if p_nome is not null and length(trim(p_nome)) < 3 then raise exception 'nome_invalido' using errcode = '22023'; end if;
  if p_email is not null and trim(p_email) <> '' and trim(p_email) !~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'email_invalido' using errcode = '22023';
  end if;
  perform 1 from public.clientes where id = p_cliente for update;
  if not found then raise exception 'cliente_inexistente' using errcode = '22023'; end if;
  update public.clientes set
    nome = coalesce(nullif(trim(p_nome), ''), nome),
    data_nascimento = coalesce(p_nascimento, data_nascimento),
    email = case when p_email is null then email else nullif(trim(p_email), '') end,
    observacoes = case when p_observacoes is null then observacoes else nullif(trim(p_observacoes), '') end,
    atualizado_em = now()
  where id = p_cliente;
end $$;

-- resgate de brinde que, de quebra, completa o nascimento se o cliente ainda não tinha
create function public.admin_resgatar_pontos_v2(p_cliente uuid, p_garrafas int default 1, p_nascimento date default null)
returns int language plpgsql security definer set search_path = '' as $$
declare nasc date;
begin
  if not public.tem_permissao('clientes.editar') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if p_nascimento is not null then
    if p_nascimento > current_date or p_nascimento < date '1900-01-01' then raise exception 'nascimento_invalido' using errcode = '22023'; end if;
    select data_nascimento into nasc from public.clientes where id = p_cliente;
    if nasc is null then
      update public.clientes set data_nascimento = p_nascimento, atualizado_em = now() where id = p_cliente;
    end if;
  end if;
  return public.admin_resgatar_pontos(p_cliente, p_garrafas);
end $$;

revoke all on function public.admin_atualizar_cliente(uuid,text,date,text,text), public.admin_resgatar_pontos_v2(uuid,int,date) from public, anon, authenticated;
grant execute on function public.admin_atualizar_cliente(uuid,text,date,text,text), public.admin_resgatar_pontos_v2(uuid,int,date) to authenticated;
