-- TQR Açaí · insumos, compras, fichas técnicas e estoque FICTÍCIOS (valores inventados; troque pelos reais no painel)
-- Marcas: compras com fornecedor "Fornecedor Exemplo" e observação [EXEMPLO]. Remoção: supabase/opcional/remover_dados_ficticios.sql
-- auxiliar só desta carga: monta a ficha pelo nome dos produtos/insumos (removida no fim)
create function public.salvar_ficha_ficticia(p_produto text, p_linhas jsonb, p_extra numeric) returns void
language plpgsql security definer set search_path = '' as $$
declare itens jsonb; pid uuid;
begin
  select id into pid from public.produtos where nome = p_produto;
  if pid is null then return; end if;
  select jsonb_agg(jsonb_build_object('insumo_id', i.id, 'quantidade', (v.value->>0)::numeric, 'perda_pct', (v.value->>1)::numeric)) into itens
  from jsonb_each(p_linhas) v join public.insumos i on i.nome = v.key;
  insert into public.produto_receitas (produto_id, insumo_id, quantidade, perda_pct)
  select pid, (x->>'insumo_id')::uuid, (x->>'quantidade')::numeric, (x->>'perda_pct')::numeric from jsonb_array_elements(itens) x
  on conflict (produto_id, insumo_id) do nothing;
  insert into public.custos_produto (produto_id, custo_extra) values (pid, p_extra) on conflict (produto_id) do update set custo_extra = excluded.custo_extra;
  perform app_private.recalcular_custo_produto(pid, 'ficha técnica de exemplo');
end $$;
revoke all on function public.salvar_ficha_ficticia(text,jsonb,numeric) from public, anon, authenticated;

do $$
declare iid uuid; pid uuid;
begin
  if exists (select 1 from public.compras_insumo where observacao = '[EXEMPLO]') then return; end if;

  insert into public.insumos (nome, tipo, unidade, estoque_minimo) values
   ('Polpa de açaí','ingrediente','g',3000), ('Polpa de cupuaçu','ingrediente','g',1000), ('Xarope de guaraná','ingrediente','ml',500),
   ('Granola','ingrediente','g',500), ('Adoçante','ingrediente','ml',100),
   ('Garrafa 300 ml','embalagem','un',40), ('Garrafa 500 ml','embalagem','un',30), ('Tampa','embalagem','un',50), ('Rótulo','embalagem','un',50)
  on conflict (nome) do nothing;

  -- compras (a polpa teve duas compras, para mostrar o histórico de custo)
  insert into public.compras_insumo (insumo_id, fornecedor, data, embalagens, conteudo, unidade, preco_total, frete, gerar_lancamento, observacao)
  select i.id, 'Fornecedor Exemplo', c.data, c.emb, c.cont, c.un, c.preco, c.frete, false, '[EXEMPLO]'
  from (values
   ('Polpa de açaí',     current_date - 40, 2, 5,   'kg', 130.00, 0.00),
   ('Polpa de açaí',     current_date - 10, 2, 5,   'kg', 140.00, 0.00),
   ('Polpa de cupuaçu',  current_date - 10, 2, 1,   'kg',  36.00, 0.00),
   ('Xarope de guaraná', current_date - 40, 1, 5,   'l',   38.00, 0.00),
   ('Granola',           current_date - 10, 2, 1,   'kg',  44.00, 0.00),
   ('Adoçante',          current_date - 40, 1, 500, 'ml',  18.00, 0.00),
   ('Garrafa 300 ml',    current_date - 40, 1, 200, 'un', 150.00, 20.00),
   ('Garrafa 500 ml',    current_date - 40, 1, 100, 'un',  95.00, 15.00),
   ('Tampa',             current_date - 40, 1, 300, 'un',  60.00, 0.00),
   ('Rótulo',            current_date - 40, 1, 500, 'un',  75.00, 0.00)
  ) as c(nome, data, emb, cont, un, preco, frete) join public.insumos i on i.nome = c.nome;

  -- fichas técnicas
  perform public.salvar_ficha_ficticia('Açaí tradicional 300 ml', '{"Polpa de açaí":[250,3],"Xarope de guaraná":[40,0],"Garrafa 300 ml":[1,0],"Tampa":[1,0],"Rótulo":[1,0]}'::jsonb, 0.30);
  perform public.salvar_ficha_ficticia('Açaí com granola 300 ml', '{"Polpa de açaí":[230,3],"Xarope de guaraná":[40,0],"Granola":[30,0],"Garrafa 300 ml":[1,0],"Tampa":[1,0],"Rótulo":[1,0]}'::jsonb, 0.30);
  perform public.salvar_ficha_ficticia('Açaí zero açúcar 300 ml', '{"Polpa de açaí":[250,3],"Adoçante":[8,0],"Garrafa 300 ml":[1,0],"Tampa":[1,0],"Rótulo":[1,0]}'::jsonb, 0.30);
  perform public.salvar_ficha_ficticia('Açaí tradicional 500 ml', '{"Polpa de açaí":[420,3],"Xarope de guaraná":[60,0],"Garrafa 500 ml":[1,0],"Tampa":[1,0],"Rótulo":[1,0]}'::jsonb, 0.40);
  perform public.salvar_ficha_ficticia('Cupuaçu 300 ml', '{"Polpa de cupuaçu":[240,3],"Xarope de guaraná":[30,0],"Garrafa 300 ml":[1,0],"Tampa":[1,0],"Rótulo":[1,0]}'::jsonb, 0.30);

  -- estoque de tampas abaixo do mínimo, para mostrar o alerta
  insert into public.movimentos_estoque (insumo_id, tipo, quantidade, motivo)
  select id, 'inventario', 35 - estoque_atual, '[EXEMPLO] contagem de estoque' from public.insumos where nome = 'Tampa';

  -- pedidos de exemplo guardam o custo de hoje (para o lucro aparecer no Financeiro)
  update public.itens_pedido i set custo_unitario = nullif(cp.custo_atual, 0)
  from public.custos_produto cp, public.pedidos p
  where cp.produto_id = i.produto_id and p.id = i.pedido_id and p.observacao = '[EXEMPLO]' and i.custo_unitario is null;
end $$;

