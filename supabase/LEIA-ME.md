# Como aplicar o banco e as funções (ordem)

**Status (12/10/2026): migrações 03 a 08 e a função `admin-usuarios` JÁ ESTÃO APLICADAS no projeto `elaczoriyaejkixkubxn`** (aplicadas em blocos menores; os nomes no histórico do Supabase terminam em a/b/c/d). O seu usuário é o Dono. As migrações foram testadas antes num PostgreSQL local com papéis e funções de autenticação simulados.

Diferenças entre o repositório e a produção: as políticas antigas `admin_all` estão neutralizadas (`using (false)`) e não apagadas, e `solicitar_codigo` não faz limpeza automática. Motivo: a ferramenta que aplica migrações trava em comandos `drop`/`delete`. Se quiser, remova as políticas antigas no SQL Editor (comandos no comentário da migração 04).

## 1. Migrações (`supabase/migrations/`)

| Arquivo | O que faz |
| --- | --- |
| `20261011_03_obter_precos.sql` | Leitura pública dos preços (legado; o site novo usa a vitrine). |
| `20261012_04_fundacao_painel.sql` | Perfis e permissões (seu usuário vira **dono**), formas de pagamento, bairros, novas configurações, contador, políticas por permissão. |
| `20261013_05_produtos_promocoes_motor.sql` | Produtos com preço/foto, promoções, motor de preço no servidor, `criar_pedido_v2`, bucket de fotos. As regras "Combo 3" e "5 ou mais" viram promoções. |
| `20261014_06_verificacao_enderecos.sql` | Código de verificação, sessão do cliente e endereços múltiplos. |
| `20261015_07_pontos_financeiro.sql` | Fase 2: livro de pontos, caixa (lançamentos), estorno automático, resgate/ajuste/aniversário, consulta de saldo, visões do financeiro. |
| `20261016_08_config_publica_pontos.sql` | O site lê as regras de pontos. |

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

## Dados fictícios de demonstração (migrações 09 e 10 — já aplicadas)
- Produtos de exemplo (granola, zero, 500 ml, cupuaçu), 8 bairros com taxas, forma "Dinheiro" e taxa de 3,99% no cartão, cupons `BEMVINDO10` e `SEXTOU5`, frete grátis ≥ R$ 80, brinde ≥ R$ 150, "Leve 4 pague 3" (desligada).
- 6 clientes `(exemplo)` com WhatsApp `55869990000xx` e observação `[EXEMPLO]`, 5 endereços, 16 pedidos em vários status (gerando caixa e pontos), despesas de 3 meses e 2 contas a pagar.
- O contador do site foi neutralizado em `contador_ajuste` (-43) para as vendas de exemplo não alterarem o número público.
- Catálogo (produtos, bairros, formas, promoções): edite/exclua pelo painel. Pedidos, clientes e lançamentos de exemplo: rode `supabase/opcional/remover_dados_ficticios.sql` no SQL Editor (também zera `contador_ajuste`).

## Fase 3: custos e estoque (migrações 11 a 14 — já aplicadas)
- **11:** `admin_atualizar_cliente` (nome, nascimento, e-mail, observações) e `admin_resgatar_pontos_v2` (resgate que também grava o nascimento esquecido).
- **12:** insumos, compras (atualizam custo e estoque), histórico de custo do insumo e do produto, ficha técnica, margem, movimentos de estoque (baixa automática no pedido pago, estorno no cancelamento), custo gravado no item do pedido. Permissões novas: `custos.ver`, `custos.gerir`, `estoque.ver`, `estoque.gerir` (gerente já recebe; dono tem tudo). Configurações: `custo_metodo` (media_ponderada | ultimo), `custo_compras_n`, `margem_alvo_pct`.
- **13:** dados fictícios de custos (9 insumos, 10 compras, 5 fichas, estoque de tampas abaixo do mínimo). Remoção no `opcional/remover_dados_ficticios.sql`.
- **14:** visões de custo sem "security definer" (`v_custo_produto` com invoker; custo das mercadorias pela função `cmv_mes`). A visão `v_cmv_mes` ficou sem uso e pode ser apagada no SQL Editor.
- A função `admin-usuarios` foi republicada (v3) com as 4 permissões novas na lista de perfis.
- Apagar compra/insumo não existe: compra é "anulada" e ficha/insumo é "desativado", para preservar o histórico.
