-- APLICAR SÓ DEPOIS que o administrador tiver cadastrado a verificação em duas etapas no painel
-- e feito login com o código ao menos uma vez. Passa a exigir aal2 (senha + código) para ler/escrever os dados.
-- Desfazer: recriar is_admin() sem a condição do aal.
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.admins where user_id = (select auth.uid()))
     and coalesce((select auth.jwt() ->> 'aal'), 'aal1') = 'aal2'
$$;
