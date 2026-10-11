-- TQR Açaí · Fase 1 · leitura pública dos preços
-- O site passa a ler os preços daqui (tabela configuracoes é a fonte de verdade).
-- Devolve só os três preços; não expõe as outras configurações.

create function public.obter_precos() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'unitario', (select valor::numeric from public.configuracoes where chave = 'preco_unitario'),
    'combo3',   (select valor::numeric from public.configuracoes where chave = 'preco_combo3'),
    'mais5',    (select valor::numeric from public.configuracoes where chave = 'preco_5mais'))
$$;

revoke all on function public.obter_precos() from public, anon, authenticated;
grant execute on function public.obter_precos() to anon, authenticated;
