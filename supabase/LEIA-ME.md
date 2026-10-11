# Como aplicar o banco e as funções (ordem)

Nada disto foi aplicado no Supabase pela sessão de desenvolvimento: as migrações foram testadas num PostgreSQL local com
papéis e funções de autenticação simulados. Aplique na ordem, de preferência fora do horário de pico, e confira o
painel (Advisors) depois de cada passo.

## 1. Migrações (`supabase/migrations/`)

| Arquivo | O que faz |
| --- | --- |
| `20261011_03_obter_precos.sql` | Leitura pública dos preços (legado; o site novo usa a vitrine). |
| `20261012_04_fundacao_painel.sql` | Perfis e permissões (seu usuário vira **dono**), formas de pagamento, bairros, novas configurações, contador, políticas por permissão. |
| `20261013_05_produtos_promocoes_motor.sql` | Produtos com preço/foto, promoções, motor de preço no servidor, `criar_pedido_v2`, bucket de fotos. As regras "Combo 3" e "5 ou mais" viram promoções. |
| `20261014_06_verificacao_enderecos.sql` | Código de verificação, sessão do cliente e endereços múltiplos. |

Depois da 04 o número que recebe os pedidos passa a vir de **Configurações → WhatsApp dos pedidos** (nasce igual ao número de teste
que o site usa hoje). Troque pelo original quando terminar os testes.

## 2. Funções de borda (`supabase/functions/`)

1. `admin-usuarios` (usuários e perfis): `supabase functions deploy admin-usuarios --project-ref elaczoriyaejkixkubxn`
2. `criar-pedido` (Turnstile, opcional): passos em `criar-pedido/README.md`.

## 3. Publicar o site

Suba `index.html`, `admin/index.html` e `politicas/` (e `robots.txt`, `sitemap.xml`) no GitHub. Site e banco são compatíveis nos dois sentidos:
o site novo cai para o pedido simples se o banco ainda não tiver a migração 05.

## 4. Depois de testar

- `supabase/opcional/exigir_mfa_no_painel.sql`: só quando todos os usuários do painel tiverem ativado a verificação em duas etapas.
- `supabase/opcional/fechar_criar_pedido_anonimo.sql`: só depois de publicar e testar a função `criar-pedido` com o Turnstile.
