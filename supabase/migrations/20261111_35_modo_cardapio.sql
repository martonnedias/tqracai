-- Modo do cardápio no site: 'garrafa' (padrão, como a loja de açaí hoje) ou 'carrinho' (vários produtos por categoria, cada um com suas opções).
insert into public.configuracoes (chave, valor, descricao) values
  ('modo_cardapio', 'garrafa', 'Cardápio do site: garrafa (um produto principal) ou carrinho (categorias e carrinho)')
on conflict (chave) do nothing;

create or replace function public.obter_config_publica() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'whatsapp',  (select valor from public.configuracoes where chave = 'whatsapp_pedidos'),
    'horario_abre',  (select valor from public.configuracoes where chave = 'horario_abre'),
    'horario_fecha', (select valor from public.configuracoes where chave = 'horario_fecha'),
    'aviso', case when (select valor from public.configuracoes where chave = 'aviso_ativo') = 'true'
                  then nullif(trim((select valor from public.configuracoes where chave = 'aviso_site')), '') end,
    'pedido_min', (select valor::int from public.configuracoes where chave = 'pedido_min'),
    'pedido_max', (select valor::int from public.configuracoes where chave = 'pedido_max'),
    'pontos_por_real', (select valor::numeric from public.configuracoes where chave = 'pontos_por_real'),
    'pontos_por_brinde', (select valor::numeric::int from public.configuracoes where chave = 'pontos_por_brinde'),
    'aniversario_pontos', (select valor::numeric::int from public.configuracoes where chave = 'aniversario_pontos'),
    'modo_cardapio', coalesce((select valor from public.configuracoes where chave = 'modo_cardapio' and valor in ('garrafa', 'carrinho')), 'garrafa'),
    'contador', public.obter_contador(),
    'formas_pagamento', coalesce((select jsonb_agg(jsonb_build_object('id', f.id, 'nome', f.nome, 'instrucoes', f.instrucoes) order by f.ordem, f.nome)
                                  from public.formas_pagamento f where f.ativo), '[]'::jsonb),
    'bairros', coalesce((select jsonb_agg(jsonb_build_object('id', b.id, 'nome', b.nome, 'taxa', b.taxa) order by b.ordem, b.nome)
                         from public.bairros_entrega b where b.ativo), '[]'::jsonb))
$$;
