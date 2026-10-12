-- TQR Açaí · opções de personalização FICTÍCIAS (troque pelas reais no painel, aba Montagem)
do $$
declare g1 uuid; g2 uuid; g3 uuid; oid uuid;
begin
  if exists (select 1 from public.grupos_opcao where nome = 'Complementos') then return; end if;
  insert into public.grupos_opcao (nome, minimo, maximo, gratis_ate, ordem) values ('Complementos', 0, 4, 2, 1) returning id into g1;
  insert into public.grupos_opcao (nome, minimo, maximo, gratis_ate, ordem) values ('Caldas', 0, 1, 0, 2) returning id into g2;
  insert into public.grupos_opcao (nome, minimo, maximo, gratis_ate, ordem) values ('Turbine seu açaí', 0, 3, 0, 3) returning id into g3;
  insert into public.opcoes (grupo_id, nome, preco_adicional, ordem) values
   (g1, 'Granola', 2.00, 1), (g1, 'Banana', 2.00, 2), (g1, 'Paçoca', 2.50, 3), (g1, 'Leite em pó', 2.50, 4), (g1, 'Morango', 3.00, 5),
   (g2, 'Leite condensado', 2.50, 1), (g2, 'Mel', 2.50, 2), (g2, 'Chocolate', 2.50, 3),
   (g3, 'Whey protein (30 g)', 6.00, 1), (g3, 'Pasta de amendoim', 4.00, 2), (g3, 'Cobertura de morango', 2.00, 3);
  -- ficha da granola (usa o insumo de exemplo, se existir)
  select id into oid from public.opcoes where nome = 'Granola' and grupo_id = g1;
  insert into public.opcao_receitas (opcao_id, insumo_id, quantidade)
  select oid, i.id, 30 from public.insumos i where i.nome = 'Granola';
end $$;
