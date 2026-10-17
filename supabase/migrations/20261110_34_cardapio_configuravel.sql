-- Cardápio configurável (base para outros segmentos): categorias de produto e tipo de grupo de opções.
-- Nada muda para a loja atual: produtos sem categoria seguem como estão e os grupos existentes são "adicional".

-- ===== categorias de produto =====
create table public.categorias_produto (
  id uuid primary key default gen_random_uuid(),
  nome text not null check (length(trim(nome)) >= 2 and length(nome) <= 40),
  ordem int not null default 0,
  ativo boolean not null default true,
  criado_em timestamptz not null default now(),
  unique (nome)
);
alter table public.categorias_produto enable row level security;
revoke all on public.categorias_produto from anon, authenticated;
grant select, insert, update on public.categorias_produto to authenticated;
create policy catprod_sel on public.categorias_produto for select to authenticated using ((select public.tem_permissao('produtos.gerir')));
create policy catprod_ins on public.categorias_produto for insert to authenticated with check ((select public.tem_permissao('produtos.gerir')));
create policy catprod_upd on public.categorias_produto for update to authenticated using ((select public.tem_permissao('produtos.gerir'))) with check ((select public.tem_permissao('produtos.gerir')));

alter table public.produtos add column categoria_id uuid references public.categorias_produto(id) on delete set null;

-- as categorias que já foram digitadas como texto viram cadastros
insert into public.categorias_produto (nome, ordem)
select c, row_number() over (order by c) from (select distinct trim(categoria) c from public.produtos where categoria is not null and length(trim(categoria)) >= 2) x
on conflict (nome) do nothing;
update public.produtos p set categoria_id = c.id from public.categorias_produto c where trim(p.categoria) = c.nome and p.categoria_id is null;

-- ===== tipo do grupo de opções =====
-- adicional: soma preço e dá baixa na ficha técnica. retirar: "sem cebola" (não cobra, não mexe no estoque).
alter table public.grupos_opcao add column tipo text not null default 'adicional' check (tipo in ('adicional', 'retirar'));

create function app_private.opcao_retirar_sem_preco() returns trigger
language plpgsql set search_path = '' as $$
begin
  if exists (select 1 from public.grupos_opcao g where g.id = new.grupo_id and g.tipo = 'retirar') then new.preco_adicional := 0; end if;
  return new;
end $$;
create trigger opcao_retirar_sem_preco before insert or update on public.opcoes
  for each row execute function app_private.opcao_retirar_sem_preco();

-- ===== vitrine pública: acrescenta categorias, categoria_id e tipo =====
create or replace function public.obter_vitrine() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'categorias', coalesce((select jsonb_agg(jsonb_build_object('id', c.id, 'nome', c.nome) order by c.ordem, c.criado_em)
                 from public.categorias_produto c where c.ativo), '[]'::jsonb),
    'produtos', coalesce((select jsonb_agg(jsonb_build_object('id', p.id, 'nome', p.nome, 'descricao', p.descricao, 'preco', p.preco,
                   'foto_url', p.foto_url, 'volume_ml', p.volume_ml, 'categoria', p.categoria, 'categoria_id', p.categoria_id) order by p.ordem, p.criado_em)
                 from public.produtos p where p.ativo and p.preco is not null), '[]'::jsonb),
    'promocoes', coalesce((select jsonb_agg(jsonb_build_object('id', x.id, 'tipo', x.tipo, 'nome', x.nome, 'regra', x.regra, 'titulo', x.titulo,
                   'qtd_label', x.qtd_label, 'rotulo', x.rotulo, 'notas', x.notas, 'imagem_url', x.imagem_url, 'cta', x.cta,
                   'qtd_sugerida', x.qtd_sugerida, 'destaque', x.destaque, 'frete_gratis', x.frete_gratis or x.tipo = 'frete_gratis',
                   'min_qtd', x.min_qtd, 'min_valor', x.min_valor) order by x.ordem_site, x.criado_em)
                 from public.promocoes x
                 where x.ativo and x.publica and x.codigo is null
                   and (x.inicio is null or now() >= x.inicio) and (x.fim is null or now() < x.fim)
                   and (x.limite_usos is null or x.usos < x.limite_usos)), '[]'::jsonb),
    'personalizacao', coalesce((select jsonb_agg(jsonb_build_object('id', g.id, 'nome', g.nome, 'tipo', g.tipo, 'minimo', g.minimo, 'maximo', g.maximo,
                   'gratis_ate', g.gratis_ate, 'produtos', to_jsonb(g.produtos),
                   'opcoes', coalesce((select jsonb_agg(jsonb_build_object('id', o.id, 'nome', o.nome, 'preco', o.preco_adicional, 'esgotado', o.esgotado)
                                       order by o.ordem, o.criado_em) from public.opcoes o where o.grupo_id = g.id and o.ativo), '[]'::jsonb))
                   order by g.ordem, g.criado_em)
                 from public.grupos_opcao g where g.ativo
                   and exists (select 1 from public.opcoes o2 where o2.grupo_id = g.id and o2.ativo)), '[]'::jsonb))
$$;
grant execute on function public.obter_vitrine() to anon, authenticated;
