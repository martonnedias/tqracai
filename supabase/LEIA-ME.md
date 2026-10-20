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

## Marca do painel (migração 23 — já aplicada)
Cores, fontes, nome e logo do painel guardados em `marca_painel` e editados na tela **Personalização** (permissão `config.gerir` + módulo `personalizacao`). `obter_marca()` é pública (a tela de login usa); `admin_salvar_marca`/`admin_restaurar_marca` validam no servidor (cores `#rrggbb`, fontes de lista liberada, logo `https://`). Sem nada salvo, vale o arquivo `admin/marca.js`.

## Cancelar pedido com motivo (migração 24 — já aplicada)
`pedidos` ganha `motivo_cancelamento`, `detalhe_cancelamento`, `cancelado_em` e `cancelado_por`. A função `admin_cancelar_pedido(p_pedido, p_motivo, p_detalhe)` (permissão `pedidos.cancelar`) exige um motivo da lista (cliente desistiu, pagamento não confirmado, sem estoque, fora da área, pedido duplicado, erro no pedido, outro — este exige detalhes) e muda o status; o estorno do caixa, dos pontos e do estoque continua vindo dos gatilhos. Vale também para pedido já entregue. O gatilho `pedidos_guarda` trata os campos do cancelamento como parte do status.


## 25 · Prova social (`20261101_25_prova_social.sql`)
Aviso de pedidos recentes no site. Tabela `prova_social`, `obter_prova_social()` (pública, saneada), `admin_salvar_prova_social(jsonb)` (config.gerir + módulo marketing). Exemplos sempre aparecem com a etiqueta "Exemplo". Já aplicada em produção.

## 26 · Selo "Novo" (`20261102_26_novidades.sql`)
Chaves `novidades_ativo`, `novidades_dias`, `novidades_ocultas` em `configuracoes` (validadas em `validar_config`) e `obter_novidades()` (qualquer usuário do painel). Já aplicada em produção. O registro das novidades fica em `admin/novidades.js`.

## 27 · Acompanhamento do pedido (`20261103_27_acompanhar_pedido.sql`)
Função pública `acompanhar_pedido(codigo, whatsapp)`: devolve situação, modalidade, forma de pagamento, total e horário de cada etapa (a partir de `pedido_eventos`). Exige código **e** WhatsApp do pedido (como `pagamento_publico`). O site (`pedido.html`) consulta a cada 20 s na confirmação e em `?acompanhar=TQR-0001`; a mensagem do WhatsApp leva esse link. Aplicada em produção.

## 28 · Código de entrega/retirada (`20261104_28_codigo_entrega.sql`)
`pedidos.codigo_entrega` (PIN de 4 dígitos, gerado por padrão) e `entrega_codigo_ok`. `acompanhar_pedido` devolve o código só enquanto o status é `saiu_entrega`. `admin_concluir_entrega(pedido, codigo)` marca "entregue" conferindo o código (opcional); com `exigir_codigo_entrega = true` (Configurações) o gatilho `guarda_pedido` bloqueia "entregue" por qualquer outro caminho. Aplicada em produção.

## 29 · Pix com valor (`20261105_29_pix_com_valor.sql`)
Configurações `pix_chave`, `pix_nome`, `pix_cidade` (Configurações > Funcionamento > Pix da loja) e a função `obter_pix_loja()` (quem muda status de pedido lê). O painel monta o Pix "copia e cola" (BR Code estático, CRC16) com o valor do pedido e o identificador `TQR0007`, no botão "Enviar Pix" do pedido, sem gateway. Não confirma o pagamento sozinho: marque o pedido como pago ao receber. Aplicada em produção.

## 30 · Pix na confirmação do site (`20261106_30_pix_publico.sql`)
`obter_pix_publico()` (público) devolve a chave Pix da loja ou `null`. Na confirmação de pedido pago por Pix (retirada, entrega por bairro ou frete grátis), se não houver gateway ligado, o site mostra o copia e cola com o valor do pedido. Entrega por aplicativo (taxa confirmada depois) não mostra: o painel envia o Pix depois. Aplicada em produção.

## 31 · WhatsApp com 55 (`20261107_31_whatsapp_55.sql`)
Correção: o site envia o WhatsApp sem o 55 e o banco guarda com 55; `acompanhar_pedido` e `pagamento_publico` agora aceitam os dois formatos (o Pix online e o acompanhamento não achavam o pedido). Aplicada em produção.

## QR Code do Pix
Sem mudança no banco. O QR é gerado no navegador (biblioteca local `vendor/qrcode.js`, qrcode-generator 1.4.4, MIT) a partir do mesmo copia e cola: na confirmação do site e no popup "Enviar Pix" do painel.

## 32 · Pagamento confirmado antes de "pago" (`20261108_32_confirmar_pagamento.sql`)
`admin_confirmar_pagamento(pedido)` (quem tem `pedidos.status`) leva pendente/confirmado a "pago". O gatilho `guarda_pedido` passa a bloquear, para edição direta pelo painel (papel `authenticated`), a ida de pendente/confirmado para pago, saiu_entrega ou entregue (`pagamento_nao_confirmado`); gateway, webhook e funções internas continuam livres. Pedidos > Kanban/lista mostram "Confirmar pagamento" (leva a Pagamentos). Aplicada em produção.

## 33 · Aparelho reconhecido e código de acesso (`20261109_33_aparelho_reconhecido.sql`)
Fim do código enviado à mão. `registrar_aparelho(pedido, whatsapp)` roda logo depois do pedido (só nos 5 primeiros minutos, uma única vez) e entrega a chave do aparelho (180 dias, guardada em `sessoes_cliente` como antes) e o código de acesso `TQR-0027-K7F2` (`pedidos.chave_acesso`, 4 letras/números aleatórios). `entrar_com_codigo(whatsapp, código de acesso)` serve para outro aparelho (token de 90 dias; 5 erros por número em 30 min bloqueiam; limite global). `consultar_saldo`, `listar/salvar/apagar_endereco` seguem iguais, agora com a chave do aparelho. `solicitar_codigo` e `verificar_codigo` perderam a permissão pública; o bloco "Clientes pedindo código" saiu do painel. Pedidos anteriores à migração não geram acesso. Aplicada em produção (em partes, por causa do bloqueio da tabela pedidos).

## 34 · Cardápio configurável (`20261110_34_cardapio_configuravel.sql`)
Base para vender o sistema a outros segmentos (hamburgueria etc.). Nada muda na loja atual.
- `categorias_produto` (nome, ordem, ativo) e `produtos.categoria_id`; as categorias que já estavam como texto viraram cadastros.
- `grupos_opcao.tipo`: `adicional` (soma preço e baixa estoque) ou `retirar` ("sem cebola": preço sempre 0, trigger `opcao_retirar_sem_preco`).
- `obter_vitrine` passa a devolver `categorias`, `categoria_id` do produto e `tipo` do grupo.

## 35 · Modo do cardápio (`20261111_35_modo_cardapio.sql`)
Chave `modo_cardapio` em `configuracoes` (`garrafa` = padrão, igual à loja de açaí; `carrinho` = cardápio por categoria com vários produtos, cada um com as suas opções e "sem ingrediente"). `obter_config_publica` passa a devolver `modo_cardapio`. No site, o modo carrinho está em `site.js` (funções `montaCardapio`, `abrirOpcoes`, `renderLinhas`) e usa os mesmos RPCs de simulação/criação (`simular_pedido_v3`, `criar_pedido_v3`). Para ligar: `update configuracoes set valor='carrinho' where chave='modo_cardapio'` (a tela no painel vem na fatia 1C).

### 1C · Painel do cardápio configurável (sem migração nova)
- Produtos > **Categorias**: criar, ordenar, ocultar e renomear; o produto escolhe a categoria num seletor (grava `categoria_id` e mantém o nome em `categoria`).
- Montagem: o grupo ganha **Tipo** (Adicional ou Retirar ingrediente), ao criar e ao editar.
- Configurações > Pedidos: **Modo do cardápio** (Garrafa ou Carrinho) liga o cardápio por categoria no site.

## 36 · Marca do site (`20261112_36_marca_site.sql`)
`marca_painel.dados` ganha o objeto `site` (`nome`, `slogan`, `logo`, `cores.{destaque,destaque2,fundo,fundo2}`), validado em `app_private.marca_valida` (hex `#rrggbb`, logo `https://…` ou `img/…`, nome sem `<` `>`). A leitura pública continua em `obter_marca()`; se o módulo `personalizacao` estiver desligado ou nada salvo, o site usa o visual padrão.
No site, `marca-site.js` (carregado antes de `site.js`) aplica nome, logo e cores via variáveis CSS (`--gold`, `--bg`… e os canais `--gold-rgb`, `--bg-rgb`), guarda cópia em `localStorage['tqr_marca_site']` (não pisca na abertura) e expõe `TQR_br()` para trocar o nome nas mensagens de WhatsApp e títulos. O `site.css` e o `blog.css` passaram a usar essas variáveis no lugar das cores fixas (sem mudança visual com o padrão: conferido por comparação de imagens). Painel: Personalização > **Site**.

## Temas do site (sem migração)
Gerador em `temas/gerar_site.py`, com temas `acai`, `hamburgueria` e `pizzaria` (ver `temas/LEIA-ME.md`). `index.html`, `pedido.html` e `tema.css` passam a ser **gerados**; o tema `acai` reproduz exatamente o site atual.

## 37 · Licença (`20261113_37_licenca.sql`)
Liga a loja ao painel mestre (projeto `supabase-mestre/`). A chave `tqrk_…` fica no vault (`licenca_chave`); a cada 5 min o `pg_cron` chama `app_private.sincronizar_licenca()`, que consulta a RPC pública `licenca(p_chave)` do mestre e grava plano/módulos (`instancia_modulos.origem='licenca'`). **Sem chave nada muda.** Com chave: contrato suspenso/cancelado, ou mais de 10 dias sem confirmar, bloqueia os módulos pagos (`modulo_ativo` só libera o núcleo); site e pedidos seguem funcionando e o painel avisa o dono (faixa no topo + Configurações > Licença). RPCs: `licenca_status()` (admin), `admin_definir_licenca(chave)` e `admin_sincronizar_agora()` (dono).

## 38 · Oferta extra e exclusões (`20261114_38_upsell_exclusoes.sql`)
`produtos.sugerir_venda`: o produto aparece em "Que tal levar também?" no pedido (a vitrine pública devolve `sugerir`). Produtos com grupo de opções obrigatório (mínimo > 0) não são oferecidos assim. RPCs `admin_excluir_opcao`, `admin_excluir_grupo` (apaga as opções junto) e `admin_excluir_categoria` (produtos ficam sem categoria), todas exigem `produtos.gerir`. Pedidos antigos guardam instantâneo em `pedidos.montagens`, então não mudam. No site, "Monte o seu açaí" passa a criar uma montagem para todas as garrafas sem montagem, em vez de uma por clique.

## 39 · Sabores (`20261115_39_sabores.sql`)
`grupos_opcao.sabor` marca um grupo como escolha de sabor (mínimo 1, máximo 1, check `grupo_sabor_unico`); `opcoes.foto_url` e `opcoes.descricao` alimentam os cartões. A vitrine devolve `sabor`, `foto_url` e `descricao`. O sabor é uma **opção do mesmo produto**: Combo 3 e 5+ continuam valendo para qualquer mistura. No site (`site.js`, bloco "Sabores") a soma dos sabores é a quantidade do pedido; cada sabor vira uma montagem com a opção de sabor, e os complementos escolhidos num cartão de montagem valem só para as garrafas daquele sabor. Sem montagens manuais, o site envia uma montagem por sabor. Não vale no modo carrinho. A página inicial aponta para `pedido.html?sabor=tropical` etc.

## 40 · Estoque de garrafas prontas (`20261116_40_estoque_pronto.sql`)
`produtos.controla_pronto` liga o controle do produto acabado. `movimentos_pronto` é o livro-razão (producao, perda, inventario, venda, estorno_venda), por produto e, quando o produto tem grupo de sabor, por sabor (`opcao_id`). O pedido (`criar_pedido_core`, usado por site e painel) confere o saldo com trava (`pg_advisory_xact_lock`), reserva as garrafas e responde `estoque_insuficiente:<nome>:<saldo>` se faltar; cancelar o pedido devolve (trigger `pedidos_pronto`). RPCs do painel: `pronto_saldos`, `registrar_movimento_pronto` (producao, perda, inventario), `pronto_historico`. A vitrine devolve `estoque` e o site limita quantidades e mostra "Esgotado". Se o site tentar enviar acima do saldo, nada vai ao WhatsApp: mostra quanto sobrou. Separado do estoque de insumos (ficha técnica), que não mudou. Brindes e promoções de kit não baixam o estoque pronto.

## 41 · Venda de balcão (`20261117_41_venda_balcao.sql`)
`admin_venda_balcao(...)` cria o pedido pelo mesmo `criar_pedido_core` do site (promoções, sabor, estoque pronto), como retirada, e já o marca `pago` e `entregue` (entra no caixa e baixa o estoque pronto). Exige `pedidos.criar` e `pedidos.status`. Sem WhatsApp usa o cliente reservado "Cliente balcão" (whatsapp `550000000000`), que não ganha pontos (`lancar_pedido_pago` ignora esse cliente). Cancelar a venda estorna caixa e estoque como em qualquer pedido. No painel: Novo pedido > Venda de balcão.

## 42 · Sabores como produtos (`20261118_42_familia_sabores.sql`)
Cada sabor é um produto (Açaí tradicional 300 ml, TQR Tropical 300 ml, TQR Tentação 300 ml). `produtos.familia` liga os sabores: `app_private.qtd_produto` soma as linhas de todos os produtos da mesma família e `preco_produto` usa o preço de qualquer linha da família, então Combo 3 e 5+ valem para qualquer mistura (premissa: mesmo preço na família). A vitrine devolve `familia`. No site, os produtos da família do produto principal viram cartões de sabor (soma = quantidade); complementos continuam por montagem de um sabor. Substitui a ideia anterior de sabor como opção (colunas `grupos_opcao.sabor`, `opcoes.foto_url/descricao` ficam sem uso; o grupo "Sabor" foi desativado). Estoque de garrafas prontas, ficha técnica e relatórios passam a ser por sabor. Dados do cliente atual: produtos criados e família `acai-300` aplicada; complementos estendidos aos novos produtos. Fichas técnicas dos sabores novos ainda não cadastradas.
