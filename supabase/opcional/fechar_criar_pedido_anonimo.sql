-- APLICAR SÓ DEPOIS que a função de borda criar-pedido estiver publicada e testada
-- (ver supabase/functions/criar-pedido/README.md). Depois disto, o site só consegue criar pedido via Turnstile.
-- Para desfazer: dar de novo grant execute às duas funções (criar_pedido e criar_pedido_v2) para anon, authenticated.
revoke execute on function public.criar_pedido(text,int,text,date,text,boolean,text,text,text,text) from anon, authenticated;
grant  execute on function public.criar_pedido(text,int,text,date,text,boolean,text,text,text,text) to service_role;

-- versão 2 (vários itens, bairro, cupom)
revoke execute on function public.criar_pedido_v2(text,jsonb,text,date,text,boolean,text,text,text,uuid,text,text,text) from anon, authenticated;
grant  execute on function public.criar_pedido_v2(text,jsonb,text,date,text,boolean,text,text,text,uuid,text,text,text) to service_role;
