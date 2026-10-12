-- TQR Açaí · relatórios (funções que devolvem jsonb para os gráficos do painel). Só leitura; exigem financeiro.ver.
-- "Venda" = pedido com status pago, saiu_entrega ou entregue. Datas no fuso de Fortaleza.
create function app_private.rel_ok() returns void
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.tem_permissao('financeiro.ver') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
end $$;
revoke all on function app_private.rel_ok() from public, anon, authenticated;

-- vendas: por dia, hora, dia da semana, bairro, forma de pagamento, modalidade
create function public.rel_vendas(p_ini date, p_fim date) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare r jsonb;
begin
  perform app_private.rel_ok();
  if p_ini is null or p_fim is null or p_fim < p_ini or p_fim - p_ini > 400 then raise exception 'periodo_invalido' using errcode = '22023'; end if;
  with v as (
    select p.*, (p.criado_em at time zone 'America/Fortaleza') as loc
    from public.pedidos p
    where (p.criado_em at time zone 'America/Fortaleza')::date between p_ini and p_fim
  ), ok as (select * from v where status in ('pago','saiu_entrega','entregue'))
  select jsonb_build_object(
    'resumo', (select jsonb_build_object('pedidos', count(*), 'total', coalesce(sum(total), 0), 'ticket', coalesce(round(avg(total), 2), 0),
                 'descontos', coalesce(sum(desconto), 0), 'entregas', coalesce(sum(taxa_entrega), 0),
                 'cancelados', (select count(*) from v where status = 'cancelado')) from ok),
    'por_dia', coalesce((select jsonb_agg(jsonb_build_object('dia', d.dia, 'pedidos', coalesce(x.n, 0), 'total', coalesce(x.t, 0)) order by d.dia)
                 from generate_series(p_ini, p_fim, interval '1 day') g(dia0), lateral (select g.dia0::date as dia) d
                 left join (select loc::date dia, count(*) n, sum(total) t from ok group by 1) x on x.dia = d.dia), '[]'::jsonb),
    'por_hora', coalesce((select jsonb_agg(jsonb_build_object('hora', h, 'pedidos', coalesce(x.n, 0), 'total', coalesce(x.t, 0)) order by h)
                 from generate_series(0, 23) h left join (select extract(hour from loc)::int hh, count(*) n, sum(total) t from ok group by 1) x on x.hh = h), '[]'::jsonb),
    'por_semana', coalesce((select jsonb_agg(jsonb_build_object('dow', dw, 'pedidos', coalesce(x.n, 0), 'total', coalesce(x.t, 0)) order by dw)
                 from generate_series(0, 6) dw left join (select extract(dow from loc)::int d, count(*) n, sum(total) t from ok group by 1) x on x.d = dw), '[]'::jsonb),
    'por_bairro', coalesce((select jsonb_agg(jsonb_build_object('bairro', b, 'pedidos', n, 'total', t) order by t desc)
                 from (select coalesce(nullif(bairro, ''), 'Retirada/sem bairro') b, count(*) n, sum(total) t from ok group by 1 limit 15) q), '[]'::jsonb),
    'por_pagamento', coalesce((select jsonb_agg(jsonb_build_object('forma', coalesce(forma_pagamento, 'não informado'), 'pedidos', n, 'total', t) order by t desc)
                 from (select forma_pagamento, count(*) n, sum(total) t from ok group by 1) q), '[]'::jsonb),
    'por_modalidade', coalesce((select jsonb_agg(jsonb_build_object('modalidade', coalesce(modalidade, 'retirada'), 'pedidos', n, 'total', t) order by t desc)
                 from (select modalidade, count(*) n, sum(total) t from ok group by 1) q), '[]'::jsonb)
  ) into r;
  return r;
end $$;

-- produtos: mais vendidos, lucro (só com custos.ver), opções de montagem, promoções e cupons
create function public.rel_produtos(p_ini date, p_fim date) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare r jsonb; ver_custo boolean := public.tem_permissao('custos.ver');
begin
  perform app_private.rel_ok();
  if p_ini is null or p_fim is null or p_fim < p_ini or p_fim - p_ini > 400 then raise exception 'periodo_invalido' using errcode = '22023'; end if;
  with ok as (
    select p.* from public.pedidos p
    where p.status in ('pago','saiu_entrega','entregue') and (p.criado_em at time zone 'America/Fortaleza')::date between p_ini and p_fim
  )
  select jsonb_build_object(
    'produtos', coalesce((select jsonb_agg(jsonb_build_object('nome', nome, 'quantidade', qtd, 'receita', rec,
                   'lucro', case when ver_custo then lucro end, 'margem_pct', case when ver_custo and rec > 0 then round(lucro / rec * 100, 1) end) order by qtd desc)
                 from (select i.nome_produto nome, sum(i.quantidade) qtd, sum(i.subtotal) rec,
                              sum(i.subtotal - coalesce(i.custo_unitario, 0) * i.quantidade) filter (where i.custo_unitario is not null) lucro
                       from public.itens_pedido i join ok on ok.id = i.pedido_id group by 1 limit 20) q), '[]'::jsonb),
    'opcoes', coalesce((select jsonb_agg(jsonb_build_object('grupo', g, 'opcao', o, 'vezes', n) order by n desc)
                 from (select op->>'grupo' g, op->>'nome' o, count(*) n
                       from ok, jsonb_array_elements(coalesce(ok.montagens, '[]'::jsonb)) m, jsonb_array_elements(coalesce(m->'opcoes', '[]'::jsonb)) op
                       group by 1, 2 order by 3 desc limit 20) q), '[]'::jsonb),
    'promocoes', coalesce((select jsonb_agg(jsonb_build_object('nome', nome, 'pedidos', n, 'desconto', d, 'receita', t) order by n desc)
                 from (select coalesce(pr.titulo, pr.nome) nome, count(*) n, sum(ok.desconto) d, sum(ok.total) t
                       from ok join public.promocoes pr on pr.id = ok.promocao_id group by 1 limit 15) q), '[]'::jsonb),
    'cupons', coalesce((select jsonb_agg(jsonb_build_object('cupom', c, 'pedidos', n, 'desconto', d) order by n desc)
                 from (select upper(cupom) c, count(*) n, sum(desconto) d from ok where nullif(cupom, '') is not null group by 1 limit 15) q), '[]'::jsonb),
    'com_promocao', (select jsonb_build_object('pedidos', count(*) filter (where promocao_id is not null or desconto > 0),
                       'ticket_com', round(avg(total) filter (where promocao_id is not null or desconto > 0), 2),
                       'ticket_sem', round(avg(total) filter (where promocao_id is null and desconto = 0), 2)) from ok)
  ) into r;
  return r;
end $$;

-- financeiro: últimos N meses, ponto de equilíbrio, despesas por categoria, a pagar e a receber
create function public.rel_financeiro(p_meses int default 12) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare r jsonb; ini date; hoje date := (now() at time zone 'America/Fortaleza')::date;
begin
  perform app_private.rel_ok();
  p_meses := least(greatest(coalesce(p_meses, 12), 1), 24);
  ini := (date_trunc('month', hoje) - make_interval(months => p_meses - 1))::date;
  select jsonb_build_object(
    'meses', coalesce((select jsonb_agg(jsonb_build_object('mes', m.mes, 'entradas', coalesce(f.entradas, 0), 'taxas', coalesce(f.taxas, 0), 'saidas', coalesce(f.saidas, 0),
                'resultado', coalesce(f.resultado, 0), 'fixas', coalesce(f.despesas_fixas, 0)) order by m.mes)
              from (select generate_series(ini, date_trunc('month', hoje)::date, interval '1 month')::date mes) m
              left join public.v_fluxo_mensal f on f.mes = m.mes), '[]'::jsonb),
    'despesas_categoria', coalesce((select jsonb_agg(jsonb_build_object('categoria', c.nome, 'valor', s.v) order by s.v desc)
              from (select categoria_id, sum(valor) v from public.lancamentos where tipo = 'saida' and pago and data >= ini group by 1) s
              join public.categorias_financeiras c on c.id = s.categoria_id), '[]'::jsonb),
    'a_pagar', coalesce((select jsonb_agg(jsonb_build_object('descricao', descricao, 'valor', valor, 'vencimento', vencimento) order by vencimento nulls last)
              from (select * from public.lancamentos where tipo = 'saida' and not pago order by vencimento nulls last limit 15) q), '[]'::jsonb),
    'a_receber', coalesce((select jsonb_agg(jsonb_build_object('descricao', descricao, 'valor', valor, 'vencimento', vencimento) order by vencimento nulls last)
              from (select * from public.lancamentos where tipo = 'entrada' and not pago order by vencimento nulls last limit 15) q), '[]'::jsonb),
    'equilibrio', (select jsonb_build_object('fixas_media', round(coalesce(avg(despesas_fixas), 0), 2),
                     'margem_pct', case when sum(entradas) > 0 then round((sum(entradas) - sum(taxas) - sum(saidas) + sum(despesas_fixas)) / sum(entradas) * 100, 1) end,
                     'faturamento_necessario', case when sum(entradas) > 0 and (sum(entradas) - sum(taxas) - sum(saidas) + sum(despesas_fixas)) > 0
                        then round(avg(despesas_fixas) / ((sum(entradas) - sum(taxas) - sum(saidas) + sum(despesas_fixas)) / sum(entradas)), 2) end)
                   from public.v_fluxo_mensal where mes >= ini and mes < date_trunc('month', hoje)::date)
  ) into r;
  return r;
end $$;

-- clientes e fidelidade
create function public.rel_clientes(p_ini date, p_fim date) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare r jsonb;
begin
  perform app_private.rel_ok();
  if p_ini is null or p_fim is null or p_fim < p_ini or p_fim - p_ini > 400 then raise exception 'periodo_invalido' using errcode = '22023'; end if;
  with ok as (
    select p.* from public.pedidos p
    where p.status in ('pago','saiu_entrega','entregue') and (p.criado_em at time zone 'America/Fortaleza')::date between p_ini and p_fim
  ), prim as (select cliente_id, min(criado_em) pri from public.pedidos where status in ('pago','saiu_entrega','entregue') group by 1)
  select jsonb_build_object(
    'clientes_ativos', (select count(distinct cliente_id) from ok),
    'novos', (select count(*) from prim where (pri at time zone 'America/Fortaleza')::date between p_ini and p_fim),
    'recorrentes', (select count(distinct ok.cliente_id) from ok join prim on prim.cliente_id = ok.cliente_id where (prim.pri at time zone 'America/Fortaleza')::date < p_ini),
    'segmentos', coalesce((select jsonb_agg(jsonb_build_object('segmento', segmento, 'clientes', n) order by n desc)
                  from (select segmento, count(*) n from public.crm_clientes() group by 1) q), '[]'::jsonb),
    'top_clientes', coalesce((select jsonb_agg(jsonb_build_object('nome', nome, 'pedidos', n, 'total', t) order by t desc)
                  from (select coalesce(c.nome, c.whatsapp) nome, count(*) n, sum(ok.total) t from ok join public.clientes c on c.id = ok.cliente_id group by 1 order by 3 desc limit 10) q), '[]'::jsonb),
    'pontos', (select jsonb_build_object('ganhos', coalesce(sum(pontos) filter (where pontos > 0), 0), 'resgates', coalesce(-sum(pontos) filter (where tipo = 'resgate'), 0))
               from public.livro_pontos where (criado_em at time zone 'America/Fortaleza')::date between p_ini and p_fim)
  ) into r;
  return r;
end $$;

revoke all on function public.rel_vendas(date,date), public.rel_produtos(date,date), public.rel_financeiro(int), public.rel_clientes(date,date) from public, anon;
grant execute on function public.rel_vendas(date,date), public.rel_produtos(date,date), public.rel_financeiro(int), public.rel_clientes(date,date) to authenticated;
