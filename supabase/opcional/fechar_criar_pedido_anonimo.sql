-- APLICAR SÓ DEPOIS que a função de borda criar-pedido estiver publicada e testada
-- (ver supabase/functions/criar-pedido/README.md). Depois disto, o site só consegue criar pedido via Turnstile.
-- Para desfazer: grant execute on function public.criar_pedido(text,int,text,date,text,boolean,text,text,text,text) to anon, authenticated;
revoke execute on function public.criar_pedido(text,int,text,date,text,boolean,text,text,text,text) from anon, authenticated;
grant  execute on function public.criar_pedido(text,int,text,date,text,boolean,text,text,text,text) to service_role;
