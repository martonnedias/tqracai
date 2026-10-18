# Painel mestre (banco próprio)

Projeto Supabase **TQR Painel Mestre** (`brhvzfipycswhpwkfqdg`, São Paulo). Guarda só gestão: assinantes, contatos, contratos, lojas (instâncias), módulos liberados e o histórico.
Pedidos e clientes de cada loja ficam no banco da própria loja e nunca passam por aqui.

A tela é `mestre/index.html` (no site: `.../mestre/`). Login com senha + verificação em duas etapas (aplicativo autenticador).

## Migrações (em ordem)
| Arquivo | O que faz |
|---|---|
| `migrations/20261201_01_mestre.sql` | Tabelas, regras de acesso (RLS), histórico automático, `admin_gerar_chave`, `licenca`, e o primeiro assinante (a loja TQR Açaí). Já aplicada. |

## Como o acesso é protegido
- Todas as tabelas têm RLS: só entra quem está em `administradores_mestre` **e** fez a verificação em duas etapas (`aal2`). Visitante, usuário comum e administrador sem a segunda etapa não veem nada.
- A chave de cada loja (`tqrk_…`) é mostrada **uma vez** ao gerar. O banco guarda só o hash (`instancia_chaves`, sem nenhum acesso pelo painel). Gerar outra chave invalida a anterior.
- `licenca(chave)` é a única função aberta ao público (as lojas a chamam). Chave inválida, falsa ou de loja desativada devolve sempre `{"ok":false}`.
- O histórico (`assinante_eventos`) só recebe registros; ninguém edita nem apaga pelo painel. Observações (texto livre) não vão para o histórico.

## Primeiro acesso (uma vez, feito pelo dono)
1. No painel do Supabase deste projeto: **Authentication > Users > Add user** (e-mail e senha fortes, marque "Auto confirm user").
2. **Authentication > Sign In / Providers**: desligue **"Allow new users to sign up"** (ninguém mais deve conseguir criar conta aqui).
3. Autorize o usuário como administrador (SQL Editor):
   ```sql
   insert into public.administradores_mestre (user_id, nome)
   select id, 'Dono' from auth.users where email = 'SEU-EMAIL-AQUI';
   ```
4. Abra `.../mestre/`, entre, cadastre o aplicativo autenticador (QR) e confirme o código. Guarde os códigos de recuperação do seu autenticador.

## Como a loja usa a licença (próximo passo)
A loja chama `POST {URL do mestre}/rest/v1/rpc/licenca` com `{"p_chave":"tqrk_..."}` e a chave pública do projeto, a cada ~5 minutos, e guarda a resposta
(`situacao`, `plano`, `modulos`). Resposta de exemplo:
`{"ok":true,"situacao":"ativo","plano":"completo","modulos":["nucleo","gestao"],"verificado_em":"2026-10-18T00:00:00Z"}`.

## Pendente / a decidir
- Quanto tempo a loja funciona sem confirmar com o mestre, e se contrato suspenso bloqueia ou só avisa.
- A ligação da loja ao mestre (função na loja que chama `licenca` e atualiza `instancia_modulos` com `origem = 'licenca'`).
- Planos e preços reais (hoje: Essencial, Profissional e Completo, com valor R$ 0 no cadastro).

## Ligar uma loja ao mestre
1. No painel mestre, abra a assinatura da loja e gere a chave (aparece uma única vez).
2. Na loja: Central > Configurações > **Licença** > cole a chave > Salvar chave. A loja confirma sozinha a cada 5 minutos (use "Verificar agora" para testar).

## Links de acesso
Na lista e na ficha de cada assinante o painel mestre mostra: Site, Fazer pedido, Painel da loja (`/admin/`) e Banco (Supabase). Eles saem do endereço do site (`url_site`) e do código do banco (`supabase_ref`) cadastrados na loja.
