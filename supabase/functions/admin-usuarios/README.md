# admin-usuarios (usuários e perfis do painel)

Só o perfil **dono** consegue chamar. O painel envia o token de quem está logado.

1. `supabase functions deploy admin-usuarios --project-ref elaczoriyaejkixkubxn` (deixe a verificação de JWT ligada).
2. Opcional: `supabase secrets set ALLOWED_ORIGINS=https://martonnedias.github.io,https://tqracai.com.br`.
3. Aplique antes a migração `20261012_04_fundacao_painel.sql`.

Ações: `listar`, `criar`, `atualizar` (nome, perfil, ativo), `redefinir_senha`, `perfil_salvar`, `perfil_excluir`.
Regras: sempre sobra ao menos um dono ativo; ninguém desativa ou rebaixa a si mesmo; perfis de sistema (dono, gerente, atendente, entregador) não são editáveis; perfis personalizados nunca recebem `*`.
Usuário novo entra com senha temporária definida pelo dono e deve cadastrar a verificação em duas etapas em Segurança.
