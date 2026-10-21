-- Produto "sugerido na hora do pedido" pode ficar fora do cardápio do site.
-- * "Aparece no site" (ativo) só decide se o produto entra no cardápio; "Sugerir na hora do pedido" vale sozinho.
-- * obter_vitrine devolve também os produtos sugeridos que estão fora do site (campo no_site = false).
-- * O motor de pedido passa a aceitar esses produtos nas linhas do pedido.
create or replace function public.obter_vitrine() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'estoque', coalesce((select jsonb_agg(jsonb_build_object('produto_id', x.pid, 'opcao_id', x.oid, 'qtd', greatest(x.saldo, 0))) from app_private.pronto_saldo_lista() x), '[]'::jsonb),
    'categorias', coalesce((select jsonb_agg(jsonb_build_object('id', c.id, 'nome', c.nome) order by c.ordem, c.criado_em)
                 from public.categorias_produto c where c.ativo), '[]'::jsonb),
    'produtos', coalesce((select jsonb_agg(jsonb_build_object('id', p.id, 'nome', p.nome, 'descricao', p.descricao, 'preco', p.preco,
                   'foto_url', p.foto_url, 'volume_ml', p.volume_ml, 'categoria', p.categoria, 'categoria_id', p.categoria_id, 'sugerir', p.sugerir_venda, 'familia', p.familia, 'no_site', p.ativo) order by p.ordem, p.criado_em)
                 from public.produtos p where (p.ativo or p.sugerir_venda) and p.preco is not null), '[]'::jsonb),
    'promocoes', coalesce((select jsonb_agg(jsonb_build_object('id', x.id, 'tipo', x.tipo, 'nome', x.nome, 'regra', x.regra, 'titulo', x.titulo,
                   'qtd_label', x.qtd_label, 'rotulo', x.rotulo, 'notas', x.notas, 'imagem_url', x.imagem_url, 'cta', x.cta,
                   'qtd_sugerida', x.qtd_sugerida, 'destaque', x.destaque, 'frete_gratis', x.frete_gratis or x.tipo = 'frete_gratis',
                   'min_qtd', x.min_qtd, 'min_valor', x.min_valor) order by x.ordem_site, x.criado_em)
                 from public.promocoes x
                 where x.ativo and x.publica and x.codigo is null
                   and (x.inicio is null or now() >= x.inicio) and (x.fim is null or now() < x.fim)
                   and (x.limite_usos is null or x.usos < x.limite_usos)), '[]'::jsonb),
    'personalizacao', coalesce((select jsonb_agg(jsonb_build_object('id', g.id, 'nome', g.nome, 'tipo', g.tipo, 'sabor', g.sabor, 'minimo', g.minimo, 'maximo', g.maximo,
                   'gratis_ate', g.gratis_ate, 'produtos', to_jsonb(g.produtos),
                   'opcoes', coalesce((select jsonb_agg(jsonb_build_object('id', o.id, 'nome', o.nome, 'preco', o.preco_adicional, 'esgotado', o.esgotado, 'foto_url', o.foto_url, 'descricao', o.descricao)
                                       order by o.ordem, o.criado_em) from public.opcoes o where o.grupo_id = g.id and o.ativo), '[]'::jsonb))
                   order by g.ordem, g.criado_em)
                 from public.grupos_opcao g where g.ativo
                   and exists (select 1 from public.opcoes o2 where o2.grupo_id = g.id and o2.ativo)), '[]'::jsonb))
$$;
grant execute on function public.obter_vitrine() to anon, authenticated;

do $m$
declare def text;
begin
  def := pg_get_functiondef('app_private.motor_pedido(jsonb,text,text,uuid,text,uuid,boolean)'::regprocedure);
  def := replace(def, 'pr2.ativo and pr2.preco is not null', '(pr2.ativo or pr2.sugerir_venda) and pr2.preco is not null');
  execute def;
end $m$;
