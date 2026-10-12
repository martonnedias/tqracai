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

## "Monte o seu açaí" (migrações 15 e 16 — já aplicadas)
- **15:** grupos de opções e opções (preço adicional, esgotado, ordem), ficha técnica por opção (custo e baixa de estoque), montagem validada no servidor (`calcular_montagens`: mínimo/máximo/grátis; as opções mais caras saem grátis primeiro), funções `simular_pedido_v3`, `criar_pedido_v3`, `admin_criar_pedido_v3` e `salvar_ficha_opcao`, colunas `pedidos.extras` e `pedidos.montagens`, vitrine pública com a personalização (sem nenhum custo).
- **16:** grupos/opções de exemplo (Complementos, Caldas, Turbine seu açaí), editáveis na aba Montagem do painel.
- Promoções valem sobre o produto-base; o adicional das opções entra depois, sem desconto. O custo das opções entra no custo do item do pedido.
- A função de borda `criar-pedido` (Turnstile, ainda não publicada) aceita `versao: 3` para as montagens.
- O pedido manual do painel (aba Novo pedido) também escolhe opções e usa `admin_criar_pedido_v3`.

## CRM (migração 17 — já aplicada)
- `crm_clientes()` devolve cada cliente com segmento automático (novo, recorrente, VIP, em risco, inativo) a partir dos pedidos; os limites ficam em Configurações do banco: `crm_vip_pedidos` (5), `crm_risco_dias` (30), `crm_inativo_dias` (60). Gasto e ticket médio só aparecem para quem tem `financeiro.ver`.
- Funil em Kanban na aba CRM (arrastar muda a etapa à mão; arrastar para a etapa automática volta ao automático), etiquetas, tarefas com data, anotações/contatos (`crm_registrar`) e mensagens prontas editáveis com {nome}, {pontos}, {garrafas}.
- Permissões: ver = `clientes.ver`; editar = `clientes.editar`; editar mensagens prontas = `config.gerir`. O envio é sempre manual: o painel abre o WhatsApp e só registra que houve contato.

## Impressão (migração 18 — já aplicada)
- Dados da loja (nome, razão social, CNPJ, telefone, endereço, rodapé) ficam em Configurações > Dados da loja e são lidos por `dados_loja()` (só equipe).
- Botão "Imprimir" no pedido (lista e Kanban): comanda de produção, cupom de entrega e recibo, em bobina térmica 80 mm ou A4. "Imprimir fila do dia" imprime todas as comandas ativas. O recibo traz "sem valor fiscal".

## Pagamentos (migração 19 — já aplicada)
- Tabelas `pagamentos` e `pagamento_eventos`; gateway em Configurações do banco: `gateway_ativo` = `nenhum` (padrão, Pix manual) | `teste` | `asaas`. A aba Pagamentos troca o modo.
- **Modo teste** roda inteiro no banco: gera Pix simulado, "Simular pagamento aprovado/recusa" e estorno. Aprovar marca o pedido como pago e os gatilhos existentes geram caixa, pontos e baixa de estoque; a taxa real (quando o gateway informa) substitui a estimada.
- **Gateway real (Asaas):** publique a função `supabase/functions/pagamentos` com `supabase functions deploy pagamentos --no-verify-jwt` e defina os segredos `GATEWAY_API_KEY`, `GATEWAY_WEBHOOK_TOKEN` e `GATEWAY_URL` (sandbox: `https://sandbox.asaas.com/api/v3`). No Asaas, cadastre o webhook `https://elaczoriyaejkixkubxn.supabase.co/functions/v1/pagamentos?webhook=asaas` com o mesmo token. O webhook é idempotente (`pagamento_eventos`). O adaptador segue a documentação pública e deve ser validado no sandbox antes de ligar o modo `asaas`.
- No site, o Pix aparece na tela após o pedido só quando o gateway não está `nenhum`; consulta por `pagamento_publico(codigo, whatsapp)`.

## Nota fiscal em homologação (migração 20 — já aplicada)
- `notas_fiscais` guarda cada nota (numeração, chave, itens, XML simulado); `nota_emitir(pedido)` e `nota_cancelar(nota, motivo)` exigem `financeiro.gerir`. Só pedidos pagos recebem nota; uma nota ativa por pedido.
- Tudo é **simulado e sem valor fiscal** (`nf_ambiente = homologacao`). Em `producao` a função recusa (`producao_indisponivel`) até um emissor real ser conectado trocando o corpo de `app_private.nota_emitir_interno`.
- Dados fiscais: Configurações (IE, IM, regime, tipo, série, emissão automática) e NCM/CFOP/CSOSN/origem por produto (padrões são exemplos; confirmar com o contador).
- Aba Notas fiscais: emitir, cancelar, imprimir cupom 80 mm e baixar CSV/XML do mês para o contador.

## Relatórios (migração 21 — já aplicada)
- Funções só de leitura, todas exigem `financeiro.ver`: `rel_vendas(ini, fim)`, `rel_produtos(ini, fim)` (lucro só com `custos.ver`), `rel_financeiro(meses)` e `rel_clientes(ini, fim)`. Cada uma devolve um jsonb que a aba Relatórios desenha em SVG (sem biblioteca). Período máximo de 400 dias.
- Venda = pedido pago, em saída para entrega ou entregue; datas no fuso de Fortaleza. Exportação em CSV e impressão/PDF pelo navegador.

## Módulos e planos (migração 22 — já aplicada)
Base da assinatura. Tabelas `modulos`, `planos`, `plano_modulos`, `instancia_modulos`, `instancia_plano`. Esta loja nasce com **todos os módulos ativos** (plano Completo).
- `modulo_ativo(m)` / `meus_modulos()` leem o estado; o dono liga/desliga com `admin_definir_modulo` e troca de plano com `admin_aplicar_plano` (tela **Plano e módulos**).
- Trava no servidor: `tem_permissao` passa a exigir o módulo (financeiro/custos/estoque → `gestao`; promocoes → `marketing`); as funções `crm_*`, de pontos, `pagamento_admin_*` e `nota_*` chamam `app_private.exige_modulo`. Módulo desligado devolve `modulo_inativo:<módulo>`; nada é apagado.
- `minhas_permissoes()` agora devolve também `modulos`. O menu do painel esconde o que está desligado.

