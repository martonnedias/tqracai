-- TQR Açaí · impressão: dados da loja para comanda, cupom de entrega e recibo
insert into public.configuracoes (chave, valor, descricao) values
 ('loja_nome','#TQR Açaí','Nome da loja nos impressos'),
 ('loja_razao','','Razão social (impressos e nota fiscal)'),
 ('loja_cnpj','','CNPJ da loja (impressos e nota fiscal)'),
 ('loja_endereco','Teresina - PI','Endereço da loja nos impressos'),
 ('loja_telefone','(86) 99588-4770','Telefone ou WhatsApp da loja nos impressos'),
 ('loja_rodape','Obrigado pela preferência!','Mensagem no fim do recibo')
on conflict (chave) do nothing;

create function public.dados_loja() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  return (select coalesce(jsonb_object_agg(replace(chave, 'loja_', ''), valor), '{}'::jsonb) from public.configuracoes where chave like 'loja\_%');
end $$;
revoke all on function public.dados_loja() from public, anon, authenticated;
grant execute on function public.dados_loja() to authenticated;
