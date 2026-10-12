-- Remove os dados FICTÍCIOS de demonstração (migrações 09 e 10). Rode no SQL Editor do Supabase quando for usar dados reais.
-- Apaga pedidos de exemplo (leva junto itens, caixa e pontos deles), lançamentos de exemplo e os clientes de exemplo.
-- Produtos, bairros, formas de pagamento e promoções de exemplo você edita/exclui pelo painel.
begin;
select count(*) as pedidos_exemplo from public.pedidos where observacao = '[EXEMPLO]';
delete from public.pedidos where observacao = '[EXEMPLO]';
delete from public.lancamentos where descricao like '[EXEMPLO]%';
delete from public.clientes where observacoes = '[EXEMPLO]';
-- devolve o ajuste do contador (as vendas de exemplo já saíram da conta); confira o valor no painel depois
update public.configuracoes set valor = '0' where chave = 'contador_ajuste';
commit;
