-- TQR Açaí · selo "Novo" no painel: configuração (liga/desliga, dias de duração, itens ocultos).
insert into public.configuracoes (chave, valor, descricao) values
 ('novidades_ativo','true','Mostrar o selo "Novo" nas funções recentes do painel (true/false)'),
 ('novidades_dias','14','Por quantos dias o selo "Novo" fica visível'),
 ('novidades_ocultas','','Itens com o selo desligado manualmente (ids separados por vírgula)')
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
  if new.chave in ('aviso_ativo','novidades_ativo') and new.valor not in ('true','false') then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave = 'novidades_ocultas' and new.valor !~ '^[a-z0-9:,_-]{0,500}$' then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  if new.chave in ('whatsapp_pedidos','whatsapp_loja') and new.valor !~ '^55[0-9]{10,11}$' then
    raise exception 'valor_invalido:%', new.chave using errcode = '22023';
  end if;
  return new;
end $$;

-- qualquer usuário do painel lê (a tabela configuracoes só abre para quem gerencia)
create function public.obter_novidades() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'ativo', coalesce((select valor from public.configuracoes where chave = 'novidades_ativo'), 'true') = 'true',
    'dias', coalesce((select valor::numeric::int from public.configuracoes where chave = 'novidades_dias'), 14),
    'ocultas', coalesce((select valor from public.configuracoes where chave = 'novidades_ocultas'), ''))
  where (select public.is_admin()) $$;
revoke all on function public.obter_novidades() from public, anon;
grant execute on function public.obter_novidades() to authenticated;
