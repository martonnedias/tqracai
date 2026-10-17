-- TQR Açaí · Pix na confirmação do pedido (site): devolve a chave Pix da loja (ou null se não cadastrada).
-- A chave é a mesma que o cliente enxerga ao pagar; o site monta o copia e cola com o valor do pedido.
create function public.obter_pix_publico() returns jsonb
language sql stable security definer set search_path = '' as $$
  select case when coalesce((select valor from public.configuracoes where chave = 'pix_chave'), '') = '' then null
    else jsonb_build_object(
      'chave', (select valor from public.configuracoes where chave = 'pix_chave'),
      'nome', coalesce((select valor from public.configuracoes where chave = 'pix_nome'), ''),
      'cidade', coalesce((select valor from public.configuracoes where chave = 'pix_cidade'), '')) end $$;
revoke all on function public.obter_pix_publico() from public;
grant execute on function public.obter_pix_publico() to anon, authenticated;
