-- APLICAR SÓ DEPOIS que a migração 04 estiver aplicada e que todos os usuários do painel tiverem cadastrado
-- a verificação em duas etapas (painel → Segurança) e feito login com o código ao menos uma vez.
-- Passa a exigir aal2 (senha + código) para qualquer acesso aos dados do painel.
-- Desfazer: recriar is_admin() sem a condição do aal (ver a migração 04).
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.admins where user_id = (select auth.uid()) and ativo)
     and coalesce((select auth.jwt() ->> 'aal'), 'aal1') = 'aal2'
$$;
