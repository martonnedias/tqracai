-- Escolha de sabor: um grupo de opções marcado como "sabor" vira cartões com foto no pedido.
-- O sabor é uma opção do mesmo produto, então Combo 3 e 5+ valem para qualquer mistura de sabores.
-- Regra: grupo de sabor = escolha única e obrigatória (mínimo 1, máximo 1).
alter table public.grupos_opcao add column sabor boolean not null default false;
alter table public.grupos_opcao add constraint grupo_sabor_unico check (not sabor or (minimo = 1 and maximo = 1));
alter table public.opcoes add column foto_url text check (foto_url is null or length(foto_url) <= 400),
                          add column descricao text check (descricao is null or length(descricao) <= 120);

create or replace function public.obter_vitrine() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'categorias', coalesce((select jsonb_agg(jsonb_build_object('id', c.id, 'nome', c.nome) order by c.ordem, c.criado_em)
                 from public.categorias_produto c where c.ativo), '[]'::jsonb),
    'produtos', coalesce((select jsonb_agg(jsonb_build_object('id', p.id, 'nome', p.nome, 'descricao', p.descricao, 'preco', p.preco,
                   'foto_url', p.foto_url, 'volume_ml', p.volume_ml, 'categoria', p.categoria, 'categoria_id', p.categoria_id, 'sugerir', p.sugerir_venda) order by p.ordem, p.criado_em)
                 from public.produtos p where p.ativo and p.preco is not null), '[]'::jsonb),
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
