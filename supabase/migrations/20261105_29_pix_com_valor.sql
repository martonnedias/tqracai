-- TQR Açaí · Pix com valor: a chave Pix da loja fica em Configurações; o painel monta o "copia e cola" (BR Code) com o valor do pedido.
insert into public.configuracoes (chave, valor, descricao) values
 ('pix_chave','','Chave Pix da loja (CPF/CNPJ, e-mail, telefone ou aleatória) usada para gerar o Pix com valor'),
 ('pix_nome','','Nome do recebedor no Pix (até 25 letras, sem acento)'),
 ('pix_cidade','','Cidade do recebedor no Pix (até 15 letras, sem acento)')
on conflict (chave) do nothing;

create or replace function app_private.validar_config() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.chave in ('preco_unitario','preco_combo3','preco_5mais','pontos_por_real','pontos_por_brinde',
                   'contador_base','contador_ajuste','pedido_min','pedido_max','novidades_dias')
     and new.valor !~ '^-?[0-9]+(\.[0-9]+)?$' then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave in ('preco_unitario','preco_combo3','preco_5mais','pedido_min','pedido_max')
     and new.valor::numeric < 0 then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave = 'novidades_dias' and (new.valor::numeric < 1 or new.valor::numeric > 90) then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave in ('horario_abre','horario_fecha') and new.valor !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave in ('aviso_ativo','novidades_ativo','exigir_codigo_entrega') and new.valor not in ('true','false') then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave = 'novidades_ocultas' and new.valor !~ '^[a-z0-9:,_-]{0,500}$' then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave in ('whatsapp_pedidos','whatsapp_loja') and new.valor !~ '^55[0-9]{10,11}$' then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave = 'pix_chave' and (char_length(new.valor) > 77 or new.valor ~ '\s') then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave = 'pix_nome' and char_length(new.valor) > 25 then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave = 'pix_cidade' and char_length(new.valor) > 15 then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  return new;
end $$;

-- quem muda status de pedido lê os dados Pix da loja (a tabela configuracoes só abre para quem gerencia)
create function public.obter_pix_loja() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'chave', coalesce((select valor from public.configuracoes where chave = 'pix_chave'), ''),
    'nome', coalesce((select valor from public.configuracoes where chave = 'pix_nome'), ''),
    'cidade', coalesce((select valor from public.configuracoes where chave = 'pix_cidade'), ''))
  where public.tem_permissao('pedidos.status') $$;
revoke all on function public.obter_pix_loja() from public, anon;
grant execute on function public.obter_pix_loja() to authenticated;
