-- TQR Açaí · ajuste de segurança das visões de custo (o linter do Supabase aponta visões "security definer")
-- v_custo_produto passa a respeitar as permissões de quem consulta; o custo das mercadorias vira função com checagem de permissão.
create function public.margem_padrao() returns numeric
language sql stable security definer set search_path = '' as $$
  select coalesce((select valor::numeric from public.configuracoes where chave = 'margem_alvo_pct'), 60)
$$;
revoke all on function public.margem_padrao() from public, anon;
grant execute on function public.margem_padrao() to authenticated;

create or replace view public.v_custo_produto with (security_invoker = true) as
select p.id as produto_id, p.nome, p.ativo, p.preco,
  coalesce(cp.custo_atual, 0) as custo_atual, coalesce(cp.custo_extra, 0) as custo_extra,
  exists (select 1 from public.produto_receitas r where r.produto_id = p.id and r.ativo) as tem_ficha,
  coalesce(cp.margem_alvo, public.margem_padrao()) as margem_alvo,
  case when p.preco is not null then round(p.preco - coalesce(cp.custo_atual, 0), 2) end as margem_valor,
  case when coalesce(p.preco, 0) > 0 then round((p.preco - coalesce(cp.custo_atual, 0)) / p.preco * 100, 1) end as margem_pct,
  case when coalesce(cp.custo_atual, 0) > 0 and p.preco is not null then round((p.preco - cp.custo_atual) / cp.custo_atual * 100, 1) end as markup_pct,
  case when coalesce(cp.custo_atual, 0) > 0 then round(cp.custo_atual / (1 - coalesce(cp.margem_alvo, public.margem_padrao()) / 100), 2) end as preco_sugerido
from public.produtos p left join public.custos_produto cp on cp.produto_id = p.id
where public.tem_permissao('custos.ver');

alter view public.v_cmv_mes set (security_invoker = true);   -- não é mais usada: veja public.cmv_mes()

create function public.cmv_mes(p_mes date) returns table (cmv numeric, receita_itens numeric, itens_sem_custo bigint)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.tem_permissao('custos.ver') then raise exception 'nao_autorizado' using errcode = '42501'; end if;
  return query
  select coalesce(sum(i.quantidade * coalesce(i.custo_unitario, 0)), 0), coalesce(sum(i.subtotal), 0), count(*) filter (where i.custo_unitario is null)
  from public.itens_pedido i join public.pedidos p on p.id = i.pedido_id
  where p.status in ('pago','saiu_entrega','entregue')
    and (p.criado_em at time zone 'America/Fortaleza')::date >= date_trunc('month', p_mes)::date
    and (p.criado_em at time zone 'America/Fortaleza')::date < (date_trunc('month', p_mes) + interval '1 month')::date;
end $$;
revoke all on function public.cmv_mes(date) from public, anon;
grant execute on function public.cmv_mes(date) to authenticated;
