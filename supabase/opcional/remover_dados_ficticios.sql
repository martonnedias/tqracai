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

-- custos e estoque de exemplo (migração 13): compras, movimentos, fichas e insumos de exemplo
delete from public.movimentos_estoque where compra_id in (select id from public.compras_insumo where observacao = '[EXEMPLO]')
  or motivo like '[EXEMPLO]%' or insumo_id in (select id from public.insumos where nome in
  ('Polpa de açaí','Polpa de cupuaçu','Xarope de guaraná','Granola','Adoçante','Garrafa 300 ml','Garrafa 500 ml','Tampa','Rótulo'));
delete from public.compras_insumo where observacao = '[EXEMPLO]';
delete from public.historico_custo_insumo where insumo_id in (select id from public.insumos where nome in
  ('Polpa de açaí','Polpa de cupuaçu','Xarope de guaraná','Granola','Adoçante','Garrafa 300 ml','Garrafa 500 ml','Tampa','Rótulo'));
delete from public.produto_receitas where insumo_id in (select id from public.insumos where nome in
  ('Polpa de açaí','Polpa de cupuaçu','Xarope de guaraná','Granola','Adoçante','Garrafa 300 ml','Garrafa 500 ml','Tampa','Rótulo'));
delete from public.historico_custo_produto where motivo like '%exemplo%' or motivo like 'Custo de %';
update public.custos_produto set custo_atual = 0, custo_extra = 0;
delete from public.insumos where nome in ('Polpa de açaí','Polpa de cupuaçu','Xarope de guaraná','Granola','Adoçante','Garrafa 300 ml','Garrafa 500 ml','Tampa','Rótulo');
-- obs.: se você já usou esses nomes de insumo com dados reais, não rode este bloco.
commit;
