-- TQR Açaí · Fase 3 · insumos, compras, histórico de custo, ficha técnica, margem e estoque
-- Regras: compra de insumo atualiza o custo do insumo (histórico) -> recalcula o custo de cada produto que o usa (histórico).
-- Pedido pago dá baixa nos insumos pela ficha técnica; cancelar estorna. Custo fica gravado no item do pedido (instantâneo).
-- Nada é apagado: histórico e movimentos são só de acréscimo; compras são "anuladas", receitas "desativadas".

-- ===== permissões =====
update public.perfis set permissoes = permissoes || '{custos.ver,custos.gerir,estoque.ver,estoque.gerir}'::text[]
  where id = 'gerente' and not (permissoes @> '{custos.ver}'::text[]);

insert into public.configuracoes (chave, valor, descricao) values
 ('custo_metodo','media_ponderada','Como calcular o custo do insumo: media_ponderada (últimas N compras) ou ultimo (último preço)'),
 ('custo_compras_n','3','Quantas compras entram na média ponderada do custo do insumo'),
 ('margem_alvo_pct','60','Margem-alvo padrão sobre o preço de venda (%), para alertas e preço sugerido')
on conflict (chave) do nothing;

-- ===== insumos =====
create table public.insumos (
  id uuid primary key default gen_random_uuid(),
  nome text not null unique check (length(trim(nome)) >= 2 and length(nome) <= 80),
  tipo text not null default 'ingrediente' check (tipo in ('ingrediente','embalagem','outro')),
  unidade text not null check (unidade in ('g','ml','un')),
  custo_atual numeric(14,6) not null default 0,        -- por unidade-base (g, ml ou un)
  estoque_atual numeric(16,3) not null default 0,
  estoque_minimo numeric(16,3) not null default 0 check (estoque_minimo >= 0),
  ativo boolean not null default true,
  criado_em timestamptz not null default now()
);

create table public.compras_insumo (
  id uuid primary key default gen_random_uuid(),
  insumo_id uuid not null references public.insumos(id) on delete restrict,
  fornecedor text check (length(fornecedor) <= 80),
  data date not null default ((now() at time zone 'America/Fortaleza')::date),
  embalagens numeric(12,3) not null check (embalagens > 0),
  conteudo numeric(14,3) not null check (conteudo > 0),      -- quanto vem em cada embalagem
  unidade text not null check (unidade in ('g','kg','ml','l','un')),
  preco_total numeric(12,2) not null check (preco_total >= 0), -- total pago por todas as embalagens
  frete numeric(12,2) not null default 0 check (frete >= 0),
  qtd_base numeric(16,3),
  custo_unit numeric(14,6),
  anulada boolean not null default false,
  gerar_lancamento boolean not null default true,
  pago boolean not null default true,
  vencimento date,
  lancamento_id uuid references public.lancamentos(id) on delete set null,
  observacao text check (length(observacao) <= 200),
  criado_em timestamptz not null default now(),
  criado_por uuid
);
create index compras_insumo_idx on public.compras_insumo (insumo_id, data desc, criado_em desc);

create table public.historico_custo_insumo (
  id bigint generated always as identity primary key,
  insumo_id uuid not null references public.insumos(id) on delete cascade,
  compra_id uuid references public.compras_insumo(id) on delete set null,
  custo_anterior numeric(14,6) not null,
  custo_novo numeric(14,6) not null,
  motivo text,
  criado_em timestamptz not null default now()
);
create index hist_custo_insumo_idx on public.historico_custo_insumo (insumo_id, criado_em desc);

-- ===== ficha técnica =====
create table public.custos_produto (
  produto_id uuid primary key references public.produtos(id) on delete cascade,
  custo_extra numeric(10,4) not null default 0 check (custo_extra >= 0),   -- gás, energia, mão de obra por unidade
  custo_atual numeric(12,4) not null default 0,
  margem_alvo numeric(5,2) check (margem_alvo >= 0 and margem_alvo < 100),
  atualizado_em timestamptz not null default now()
);
create table public.produto_receitas (
  id uuid primary key default gen_random_uuid(),
  produto_id uuid not null references public.produtos(id) on delete cascade,
  insumo_id uuid not null references public.insumos(id) on delete restrict,
  quantidade numeric(14,4) not null check (quantidade > 0),    -- na unidade-base do insumo
  perda_pct numeric(5,2) not null default 0 check (perda_pct >= 0 and perda_pct <= 90),
  ativo boolean not null default true,
  unique (produto_id, insumo_id)
);
create table public.historico_custo_produto (
  id bigint generated always as identity primary key,
  produto_id uuid not null references public.produtos(id) on delete cascade,
  custo_anterior numeric(12,4) not null,
  custo_novo numeric(12,4) not null,
  motivo text,
  criado_em timestamptz not null default now()
);
create index hist_custo_produto_idx on public.historico_custo_produto (produto_id, criado_em desc);

-- ===== estoque =====
create table public.movimentos_estoque (
  id bigint generated always as identity primary key,
  insumo_id uuid not null references public.insumos(id) on delete restrict,
  tipo text not null check (tipo in ('compra','consumo','ajuste','perda','inventario','estorno_consumo','estorno_compra')),
  quantidade numeric(16,3) not null check (quantidade <> 0),   -- com sinal, na unidade-base
  pedido_id uuid references public.pedidos(id) on delete cascade,
  compra_id uuid references public.compras_insumo(id) on delete set null,
  motivo text check (length(motivo) <= 200),
  criado_em timestamptz not null default now(),
  criado_por uuid
);
create index mov_estoque_idx on public.movimentos_estoque (insumo_id, criado_em desc);
create unique index mov_consumo_pedido_uk on public.movimentos_estoque (pedido_id, insumo_id) where tipo = 'consumo';
create unique index mov_estorno_pedido_uk on public.movimentos_estoque (pedido_id, insumo_id) where tipo = 'estorno_consumo';

-- ===== cálculo: unidades =====
create function app_private.fator_unidade(u text) returns numeric
language sql immutable set search_path = '' as $$
  select case u when 'kg' then 1000 when 'l' then 1000 else 1 end
$$;
create function app_private.unidade_base(u text) returns text
language sql immutable set search_path = '' as $$
  select case u when 'kg' then 'g' when 'l' then 'ml' else u end
$$;

-- ===== cálculo: custo do produto (soma da ficha técnica) =====
create function app_private.recalcular_custo_produto(p_produto uuid, p_motivo text) returns void
language plpgsql security definer set search_path = '' as $$
declare novo numeric; antigo numeric; extra numeric;
begin
  select coalesce(custo_extra, 0), custo_atual into extra, antigo from public.custos_produto where produto_id = p_produto;
  if not found then
    extra := 0; antigo := 0;
    insert into public.custos_produto (produto_id) values (p_produto) on conflict do nothing;
  end if;
  select round(coalesce(sum(r.quantidade * (1 + r.perda_pct / 100) * i.custo_atual), 0) + extra, 4) into novo
    from public.produto_receitas r join public.insumos i on i.id = r.insumo_id
    where r.produto_id = p_produto and r.ativo;
  if novo is distinct from antigo then
    update public.custos_produto set custo_atual = novo, atualizado_em = now() where produto_id = p_produto;
    insert into public.historico_custo_produto (produto_id, custo_anterior, custo_novo, motivo)
    values (p_produto, coalesce(antigo, 0), novo, p_motivo);
  end if;
end $$;

-- ===== cálculo: custo do insumo (a partir das compras) e efeito nos produtos =====
create function app_private.recalcular_custo_insumo(p_insumo uuid, p_compra uuid, p_motivo text) returns void
language plpgsql security definer set search_path = '' as $$
declare metodo text; n int; novo numeric; antigo numeric; pid uuid; nome text;
begin
  select valor into metodo from public.configuracoes where chave = 'custo_metodo';
  select coalesce(valor::numeric::int, 3) into n from public.configuracoes where chave = 'custo_compras_n';
  n := greatest(coalesce(n, 3), 1);
  select custo_atual, i.nome into antigo, nome from public.insumos i where i.id = p_insumo;
  if coalesce(metodo, 'media_ponderada') = 'ultimo' then
    select c.custo_unit into novo from public.compras_insumo c
      where c.insumo_id = p_insumo and not c.anulada order by c.data desc, c.criado_em desc limit 1;
  else
    select sum(x.total) / nullif(sum(x.qtd_base), 0) into novo from (
      select c.preco_total + c.frete as total, c.qtd_base from public.compras_insumo c
      where c.insumo_id = p_insumo and not c.anulada order by c.data desc, c.criado_em desc limit n) x;
  end if;
  if novo is null then return; end if;           -- sem compras válidas: mantém o custo que já estava
  novo := round(novo, 6);
  if novo is distinct from antigo then
    update public.insumos set custo_atual = novo where id = p_insumo;
    insert into public.historico_custo_insumo (insumo_id, compra_id, custo_anterior, custo_novo, motivo)
    values (p_insumo, p_compra, antigo, novo, p_motivo);
    for pid in select distinct r.produto_id from public.produto_receitas r where r.insumo_id = p_insumo and r.ativo loop
      perform app_private.recalcular_custo_produto(pid, 'Custo de ' || nome || ' mudou (' || p_motivo || ')');
    end loop;
  end if;
end $$;

-- ===== compras =====
create function app_private.compra_calcula() returns trigger
language plpgsql security definer set search_path = '' as $$
declare ub text;
begin
  select unidade into ub from public.insumos where id = new.insumo_id;
  if ub is null then raise exception 'insumo_inexistente' using errcode = '22023'; end if;
  if app_private.unidade_base(new.unidade) <> ub then raise exception 'unidade_incompativel' using errcode = '22023'; end if;
  new.qtd_base := round(new.embalagens * new.conteudo * app_private.fator_unidade(new.unidade), 3);
  new.custo_unit := round((new.preco_total + new.frete) / new.qtd_base, 6);
  new.anulada := false;
  new.lancamento_id := null;
  new.criado_por := coalesce((select auth.uid()), new.criado_por);
  return new;
end $$;
create trigger compras_calcula before insert on public.compras_insumo
  for each row execute function app_private.compra_calcula();

create function app_private.compra_aplica() returns trigger
language plpgsql security definer set search_path = '' as $$
declare lid uuid; nome text; cat text; tipo text;
begin
  select i.nome, i.tipo into nome, tipo from public.insumos i where i.id = new.insumo_id;
  insert into public.movimentos_estoque (insumo_id, tipo, quantidade, compra_id, motivo, criado_por)
  values (new.insumo_id, 'compra', new.qtd_base, new.id, 'Compra de ' || nome, new.criado_por);
  if new.gerar_lancamento and (new.preco_total + new.frete) > 0 then
    cat := case when tipo = 'embalagem' then 'embalagem' else 'insumos' end;
    insert into public.lancamentos (tipo, categoria_id, descricao, valor, data, vencimento, pago, pago_em, origem, criado_por)
    values ('saida', cat, left('Compra: ' || nome || coalesce(' · ' || nullif(new.fornecedor, ''), ''), 200), new.preco_total + new.frete,
            new.data, case when new.pago then null else new.vencimento end, new.pago, case when new.pago then new.data end, 'manual', new.criado_por)
    returning id into lid;
    update public.compras_insumo set lancamento_id = lid where id = new.id;
  end if;
  perform app_private.recalcular_custo_insumo(new.insumo_id, new.id, 'compra de ' || to_char(new.data, 'DD/MM'));
  return new;
end $$;
create trigger compras_aplica after insert on public.compras_insumo
  for each row execute function app_private.compra_aplica();

-- anular compra: desfaz estoque e custo; devolve o lançamento para o painel tirar do caixa
create function public.anular_compra(p_compra uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare c public.compras_insumo;
begin
  if not public.tem_permissao('custos.gerir') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  select * into c from public.compras_insumo where id = p_compra for update;
  if not found then raise exception 'compra_inexistente' using errcode = '22023'; end if;
  if c.anulada then raise exception 'ja_anulada' using errcode = '22023'; end if;
  update public.compras_insumo set anulada = true where id = p_compra;
  insert into public.movimentos_estoque (insumo_id, tipo, quantidade, compra_id, motivo, criado_por)
  values (c.insumo_id, 'estorno_compra', -c.qtd_base, c.id, 'Compra anulada', (select auth.uid()));
  perform app_private.recalcular_custo_insumo(c.insumo_id, c.id, 'compra anulada');
  return c.lancamento_id;
end $$;

-- custo informado à mão (insumo ainda sem compra, ou correção)
create function public.definir_custo_insumo(p_insumo uuid, p_custo numeric, p_motivo text default 'ajuste manual') returns void
language plpgsql security definer set search_path = '' as $$
declare antigo numeric; nome text; pid uuid;
begin
  if not public.tem_permissao('custos.gerir') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if p_custo is null or p_custo < 0 then raise exception 'custo_invalido' using errcode = '22023'; end if;
  select custo_atual, i.nome into antigo, nome from public.insumos i where i.id = p_insumo for update;
  if not found then raise exception 'insumo_inexistente' using errcode = '22023'; end if;
  p_custo := round(p_custo, 6);
  if p_custo is distinct from antigo then
    update public.insumos set custo_atual = p_custo where id = p_insumo;
    insert into public.historico_custo_insumo (insumo_id, custo_anterior, custo_novo, motivo)
    values (p_insumo, antigo, p_custo, left(coalesce(nullif(trim(p_motivo), ''), 'ajuste manual'), 200));
    for pid in select distinct r.produto_id from public.produto_receitas r where r.insumo_id = p_insumo and r.ativo loop
      perform app_private.recalcular_custo_produto(pid, 'Custo de ' || nome || ' ajustado');
    end loop;
  end if;
end $$;

-- ===== ficha técnica =====
create function public.salvar_ficha(p_produto uuid, p_itens jsonb, p_custo_extra numeric default 0, p_margem_alvo numeric default null)
returns numeric language plpgsql security definer set search_path = '' as $$
declare it jsonb; ids uuid[] := '{}'; iid uuid; q numeric; perda numeric; cst numeric;
begin
  if not public.tem_permissao('custos.gerir') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  perform 1 from public.produtos where id = p_produto;
  if not found then raise exception 'produto_inexistente' using errcode = '22023'; end if;
  if jsonb_typeof(p_itens) <> 'array' then raise exception 'itens_invalidos' using errcode = '22023'; end if;
  if coalesce(p_custo_extra, 0) < 0 then raise exception 'custo_invalido' using errcode = '22023'; end if;
  if p_margem_alvo is not null and (p_margem_alvo < 0 or p_margem_alvo >= 100) then raise exception 'margem_invalida' using errcode = '22023'; end if;
  for it in select * from jsonb_array_elements(p_itens) loop
    iid := (it->>'insumo_id')::uuid; q := (it->>'quantidade')::numeric; perda := coalesce((it->>'perda_pct')::numeric, 0);
    if q is null or q <= 0 or perda < 0 or perda > 90 then raise exception 'itens_invalidos' using errcode = '22023'; end if;
    perform 1 from public.insumos where id = iid;
    if not found then raise exception 'insumo_inexistente' using errcode = '22023'; end if;
    insert into public.produto_receitas (produto_id, insumo_id, quantidade, perda_pct, ativo)
    values (p_produto, iid, q, perda, true)
    on conflict (produto_id, insumo_id) do update set quantidade = excluded.quantidade, perda_pct = excluded.perda_pct, ativo = true;
    ids := ids || iid;
  end loop;
  update public.produto_receitas set ativo = false where produto_id = p_produto and ativo and not (insumo_id = any(ids));
  insert into public.custos_produto (produto_id, custo_extra, margem_alvo) values (p_produto, coalesce(p_custo_extra, 0), p_margem_alvo)
  on conflict (produto_id) do update set custo_extra = excluded.custo_extra, margem_alvo = excluded.margem_alvo;
  perform app_private.recalcular_custo_produto(p_produto, 'ficha técnica editada');
  select custo_atual into cst from public.custos_produto where produto_id = p_produto;
  return cst;
end $$;

-- ===== estoque =====
create function app_private.movimento_aplica() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.insumos set estoque_atual = estoque_atual + new.quantidade where id = new.insumo_id;
  return new;
end $$;
create trigger movimentos_aplica after insert on public.movimentos_estoque
  for each row execute function app_private.movimento_aplica();

-- ajuste (± quantidade), perda (quantidade positiva sai) ou inventário (informa a contagem; o sistema calcula a diferença)
create function public.registrar_movimento_estoque(p_insumo uuid, p_tipo text, p_quantidade numeric, p_motivo text default null)
returns numeric language plpgsql security definer set search_path = '' as $$
declare atual numeric; delta numeric;
begin
  if not public.tem_permissao('estoque.gerir') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  if p_tipo not in ('ajuste','perda','inventario') then raise exception 'tipo_invalido' using errcode = '22023'; end if;
  if p_quantidade is null then raise exception 'quantidade_invalida' using errcode = '22023'; end if;
  select estoque_atual into atual from public.insumos where id = p_insumo for update;
  if not found then raise exception 'insumo_inexistente' using errcode = '22023'; end if;
  delta := case p_tipo when 'perda' then -abs(p_quantidade) when 'inventario' then p_quantidade - atual else p_quantidade end;
  if p_tipo = 'inventario' and p_quantidade < 0 then raise exception 'quantidade_invalida' using errcode = '22023'; end if;
  if delta = 0 then return atual; end if;
  insert into public.movimentos_estoque (insumo_id, tipo, quantidade, motivo, criado_por)
  values (p_insumo, p_tipo, delta, left(coalesce(nullif(trim(p_motivo), ''), case p_tipo when 'perda' then 'Perda' when 'inventario' then 'Contagem de estoque' else 'Ajuste' end), 200), (select auth.uid()));
  return atual + delta;
end $$;

-- baixa nos insumos quando o pedido é pago; estorno se cancelado depois
create function app_private.pedido_estoque() returns trigger
language plpgsql security definer set search_path = '' as $$
declare pagos text[] := array['pago','saiu_entrega','entregue'];
begin
  if new.status is not distinct from old.status then return new; end if;
  if new.status::text = any(pagos) and not (old.status::text = any(pagos)) then
    insert into public.movimentos_estoque (insumo_id, tipo, quantidade, pedido_id, motivo)
    select r.insumo_id, 'consumo', -round(sum(i.quantidade * r.quantidade * (1 + r.perda_pct / 100)), 3), new.id, 'Pedido ' || new.codigo
    from public.itens_pedido i join public.produto_receitas r on r.produto_id = i.produto_id and r.ativo
    where i.pedido_id = new.id
    group by r.insumo_id
    having round(sum(i.quantidade * r.quantidade * (1 + r.perda_pct / 100)), 3) > 0
    on conflict do nothing;
  elsif new.status = 'cancelado' and old.status::text = any(pagos) then
    insert into public.movimentos_estoque (insumo_id, tipo, quantidade, pedido_id, motivo)
    select m.insumo_id, 'estorno_consumo', -m.quantidade, new.id, 'Estorno do pedido ' || new.codigo
    from public.movimentos_estoque m where m.pedido_id = new.id and m.tipo = 'consumo'
    on conflict do nothing;
  end if;
  return new;
end $$;
create trigger pedidos_estoque after update of status on public.pedidos
  for each row execute function app_private.pedido_estoque();

-- o item do pedido guarda o custo do produto no momento da venda
create function app_private.item_custo() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.custo_unitario is null then
    select nullif(custo_atual, 0) into new.custo_unitario from public.custos_produto where produto_id = new.produto_id;
  end if;
  return new;
end $$;
create trigger itens_custo before insert on public.itens_pedido
  for each row execute function app_private.item_custo();

-- ===== segurança (RLS) =====
alter table public.insumos enable row level security;
alter table public.compras_insumo enable row level security;
alter table public.historico_custo_insumo enable row level security;
alter table public.custos_produto enable row level security;
alter table public.produto_receitas enable row level security;
alter table public.historico_custo_produto enable row level security;
alter table public.movimentos_estoque enable row level security;
revoke all on public.insumos, public.compras_insumo, public.historico_custo_insumo, public.custos_produto,
  public.produto_receitas, public.historico_custo_produto, public.movimentos_estoque from anon, authenticated;
grant select on public.insumos, public.compras_insumo, public.historico_custo_insumo, public.custos_produto,
  public.produto_receitas, public.historico_custo_produto, public.movimentos_estoque to authenticated;
grant insert on public.insumos, public.compras_insumo to authenticated;
grant update (nome, tipo, unidade, ativo, estoque_minimo) on public.insumos to authenticated;

create policy ins_sel on public.insumos for select to authenticated
  using ((select public.tem_permissao('custos.ver')) or (select public.tem_permissao('estoque.ver')));
create policy ins_ins on public.insumos for insert to authenticated with check ((select public.tem_permissao('custos.gerir')));
create policy ins_upd on public.insumos for update to authenticated
  using ((select public.tem_permissao('custos.gerir')) or (select public.tem_permissao('estoque.gerir')))
  with check ((select public.tem_permissao('custos.gerir')) or (select public.tem_permissao('estoque.gerir')));
create policy comp_sel on public.compras_insumo for select to authenticated using ((select public.tem_permissao('custos.ver')));
create policy comp_ins on public.compras_insumo for insert to authenticated with check ((select public.tem_permissao('custos.gerir')));
create policy hci_sel on public.historico_custo_insumo for select to authenticated using ((select public.tem_permissao('custos.ver')));
create policy cp_sel on public.custos_produto for select to authenticated using ((select public.tem_permissao('custos.ver')));
create policy rec_sel on public.produto_receitas for select to authenticated using ((select public.tem_permissao('custos.ver')));
create policy hcp_sel on public.historico_custo_produto for select to authenticated using ((select public.tem_permissao('custos.ver')));
create policy mov_sel on public.movimentos_estoque for select to authenticated
  using ((select public.tem_permissao('estoque.ver')) or (select public.tem_permissao('custos.ver')));

-- o custo gravado no item do pedido só é lido por quem vê custos (aparece nas visões abaixo)
revoke select on public.itens_pedido from authenticated;
grant select (id, pedido_id, produto_id, quantidade, subtotal, preco_unitario, nome_produto, brinde) on public.itens_pedido to authenticated;

revoke all on function public.anular_compra(uuid), public.definir_custo_insumo(uuid,numeric,text),
  public.salvar_ficha(uuid,jsonb,numeric,numeric), public.registrar_movimento_estoque(uuid,text,numeric,text) from public, anon, authenticated;
grant execute on function public.anular_compra(uuid), public.definir_custo_insumo(uuid,numeric,text),
  public.salvar_ficha(uuid,jsonb,numeric,numeric), public.registrar_movimento_estoque(uuid,text,numeric,text) to authenticated;

-- ===== visões para o painel =====
-- margem por produto (usa o preço atual e a margem-alvo do produto ou a padrão)
create view public.v_custo_produto as
select p.id as produto_id, p.nome, p.ativo, p.preco,
  coalesce(cp.custo_atual, 0) as custo_atual, coalesce(cp.custo_extra, 0) as custo_extra,
  exists (select 1 from public.produto_receitas r where r.produto_id = p.id and r.ativo) as tem_ficha,
  coalesce(cp.margem_alvo, (select valor::numeric from public.configuracoes where chave = 'margem_alvo_pct'), 60) as margem_alvo,
  case when p.preco is not null then round(p.preco - coalesce(cp.custo_atual, 0), 2) end as margem_valor,
  case when coalesce(p.preco, 0) > 0 then round((p.preco - coalesce(cp.custo_atual, 0)) / p.preco * 100, 1) end as margem_pct,
  case when coalesce(cp.custo_atual, 0) > 0 and p.preco is not null then round((p.preco - cp.custo_atual) / cp.custo_atual * 100, 1) end as markup_pct,
  case when coalesce(cp.custo_atual, 0) > 0 then
    round(cp.custo_atual / (1 - coalesce(cp.margem_alvo, (select valor::numeric from public.configuracoes where chave = 'margem_alvo_pct'), 60) / 100), 2) end as preco_sugerido
from public.produtos p left join public.custos_produto cp on cp.produto_id = p.id
where public.tem_permissao('custos.ver');

-- custo das mercadorias vendidas por mês (só pedidos pagos)
create view public.v_cmv_mes as
select date_trunc('month', p.criado_em at time zone 'America/Fortaleza')::date as mes,
  sum(i.quantidade * coalesce(i.custo_unitario, 0)) as cmv,
  sum(i.subtotal) as receita_itens,
  count(*) filter (where i.custo_unitario is null) as itens_sem_custo
from public.itens_pedido i join public.pedidos p on p.id = i.pedido_id
where p.status in ('pago','saiu_entrega','entregue') and public.tem_permissao('custos.ver')
group by 1;
revoke all on public.v_custo_produto, public.v_cmv_mes from public, anon;
grant select on public.v_custo_produto, public.v_cmv_mes to authenticated;
