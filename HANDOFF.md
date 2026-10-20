# TQR Açaí — Continuação do projeto (handoff)

Documento para uma nova sessão que não viu a conversa anterior. Leia tudo antes de agir. Data deste handoff: 11/10/2026. Dono do projeto: Martonne (martonnedias@gmail.com). Idioma de trabalho: português do Brasil.

## 0. Checklist de lançamento (atualizado em 18/10/2026)

Este quadro substitui as listas antigas das seções 5.x onde houver conflito. `[x]` = feito e no ar; `[ ]` = falta.

**Sistema (feito)**
- [x] Cardápio configurável (categorias, tipo de grupo Adicional/Retirar, modo Garrafa ou Carrinho).
- [x] Marca do painel e do site (nome, logo, cores) em Personalização.
- [x] Temas do site: açaí, hamburgueria, pizzaria (`temas/gerar_site.py`).
- [x] Painel mestre `/mestre/` (assinantes, contratos, planos, módulos, chaves, links de acesso por loja, ajuda) com banco próprio e MFA obrigatório.
- [x] Licença da loja (migração 37): sincroniza a cada 5 min, 10 dias de tolerância, suspenso/cancelado bloqueia módulos pagos.
- [x] Ajuda e Novidades do painel da loja e ajuda do painel mestre atualizadas.
- [x] Administrador do mestre autorizado (martonnedias@gmail.com).
- [x] Pedido em 3 abas (Pedido, Entrega, Pagamento) com Continuar/Voltar.
- [x] Oferta extra no pedido ("Que tal levar também?") e exclusão de opções, grupos e categorias.
- [x] Novos sabores: seção na página inicial e escolha de sabor com foto no pedido (Combo 3 e 5+ valem para qualquer mistura).
- [x] Estoque de garrafas prontas por sabor (Estoque > Garrafas prontas), com bloqueio de venda no site. **Desligado**: para ativar, marque "Controlar estoque de garrafas prontas" no produto e registre a produção.
- [x] Venda de balcão (Novo pedido), já paga e entregue; WhatsApp opcional.

**Ações do dono (faltam)**
- [ ] Informação nutricional e alérgenos dos sabores Tropical e Tentação (Nutella: avelã, leite e soja); a seção Ingredientes ainda descreve só o Tradicional.
- [ ] Ligar o estoque de garrafas prontas quando for começar a controlar (produzir primeiro, ligar depois) e fazer um pedido de teste.
- [ ] Teste em celular real do pedido com sabores e da mensagem do WhatsApp.
- [ ] Cadastrar o autenticador (TOTP) no `/mestre/` e conferir que o cadastro público de usuários está desligado nos dois projetos Supabase (mestre e loja).
- [ ] Cadastrar o assinante "TQR Açaí" no mestre, com o endereço do site e o código do banco da loja; gerar a chave e colar em Configurações > Licença do painel da loja.
- [ ] Definir planos e preços reais (hoje R$ 0).
- [ ] Políticas: preencher os campos [PREENCHER] (razão social, endereço, e-mail, encarregado LGPD) e revisão jurídica.
- [ ] Chave Pix real e WhatsApp real (hoje o site envia para o número de teste).
- [ ] GA4, Meta Pixel e Turnstile (IDs reais); feed do Instagram.
- [ ] Domínio próprio e ajuste das URLs (sitemap, canonical).
- [ ] Testes ponta a ponta em Android e iPhone (pedido, WhatsApp, painel).
- [ ] Preços e bairros de entrega reais; fotos reais dos produtos.
- [ ] MFA do dono na loja; backups do Supabase (conferir plano); decisão sobre pagamento na entrega.
- [ ] Limpar os dados de teste (pedidos, clientes, caixa avulso, estoque) somente quando o dono disser "pode zerar": antes, fazer cópia e contagem.

**Evolução do produto (faltam)**
- [ ] Fase 3: assistente de implantação (gera o site do tema, aplica as migrações no banco do cliente, atualiza todos os clientes).
- [ ] Fotos dos temas hamburgueria e pizzaria (hoje emoji); blog e políticas por cliente (hoje de açaí).
- [ ] Escolher o tema por botão no painel (hoje é feito na instalação).
- [ ] Auditoria das funções legadas do banco; Etapa 8 (custos e extras), se mantida.

## 1. O que é o projeto

"#TQR Açaí" vende açaí tradicional de 300 ml em garrafa, pronto para tomar, em Teresina (PI). O pedido é feito pelo WhatsApp e o pagamento é confirmado manualmente. O projeto tem três partes: (a) uma landing page estática de venda, (b) um painel do dono para acompanhar pedidos, (c) um banco no Supabase que liga as duas. Um programa de fidelidade (pontos) e o controle financeiro e de custos são as próximas fases.

Dados do negócio (não inventar outros):

- Produto: açaí tradicional 300 ml. Preços: 1 un R$ 16,99; combo de 3 por R$ 42,00; 4 un = R$ 58,99 (combo + 1 avulsa); a partir de 5 un, R$ 14,00 cada com entrega grátis. Pix e cartão. Atendimento das 8h às 2h.
- WhatsApp original da loja: (86) 99588-4770 (`5586995884770`). **Hoje o site envia pedidos para um número de teste: (86) 99414-4709 (`5586994144709`)**, definido em `window.TQR_FONE` no começo do `index.html`. Voltar ao original quando o dono pedir.
- Instagram @tqracai. CNPJ 59.270.529/0001-78.

Regras de marca e texto:

- Dizer "pronto na garrafa" e "chega gelado e no ponto". **Nunca** usar "descongelar" nem "congelado" em texto para o consumidor.
- Público: consumidor de delivery em Teresina. Diferencial: pronto na garrafa, sem preparar.
- Design: "The Midnight Garrafa" (fundo roxo escuro, dourado como único acento, verde do WhatsApp só em botões de envio). Detalhes em `DESIGN.md`, `PRODUCT.md` e `.impeccable/design.json` na raiz do repositório. Fontes Kaushan Script e Poppins. Tokens principais: fundo #16051f, cartão #2b1040, dourado #e8be62, dourado claro #fbe2a0, texto #f6eefa, apoio #cdb9d8, botão WhatsApp #0f7a40 com texto branco (contraste).

## 2. Estado atual (11/10/2026)

Publicado:

- Site: https://martonnedias.github.io/tqracai/ (GitHub Pages, repositório público `martonnedias/tqracai`, branch main, raiz). O painel fica em `/admin/`. O dono subiu os arquivos pelo site do GitHub. Como o Pages serve em `/tqracai/`, use sempre caminhos **relativos** nos links e imagens.
- Há também uma cópia publicada como Artifact no claude.ai (preview, ficou desatualizada e **não consegue falar com o banco** por bloqueio de rede da página). Decidir com o dono se deve ser atualizada ou deixada de lado.

Banco: Supabase, projeto "TQR Acai", ref `elaczoriyaejkixkubxn`, URL `https://elaczoriyaejkixkubxn.supabase.co`, região sa-east-1, organização "Martonne Dias". É um projeto separado dos outros projetos do dono (AfiliadoProShopee e MD_Solution, ambos pausados e não relacionados), de propósito, para facilitar migração futura. A chave pública (publishable) `sb_publishable_NscsoGdrovVNuBol72Rh3Q_ov8i8lGv` já está no `index.html` e no `admin/index.html`; ela é pública por natureza. Nunca colocar chave secreta (service role) no código.

Arquivos do repositório:

| Caminho | O que é |
| --- | --- |
| `index.html` | Landing page completa (HTML, CSS e JS em um arquivo). Formulário de pedido grava no banco e depois abre o WhatsApp. |
| `admin/index.html` | Painel do dono (login, pedidos, pedido manual, clientes). Usa supabase-js 2.45.0 via jsDelivr. |
| `blog/`, `politicas/`, `fonts/`, `img/` | Blog, políticas (privacidade, termos, cookies, trocas), fontes e imagens. |
| `supabase/migrations/` | `20261010_01_schema_fase1.sql` e `20261010_02_funcoes_fase1.sql`, iguais ao que está aplicado no banco. |
| `DESIGN.md`, `PRODUCT.md`, `.impeccable/design.json` | Contexto de design (rodar o skill impeccable usa esses arquivos). |

O que o banco tem (fase 1): tabelas `clientes`, `produtos`, `pedidos`, `itens_pedido`, `pedido_eventos`, `configuracoes`, `admins`; sequência `pedido_codigo_seq` (códigos TQR-0001...); views `v_resumo_dia` e `v_clientes_resumo` (security invoker); funções públicas `criar_pedido`, `cadastrar_cliente`, `cliente_cadastrado`, `calcular_total`; função de admin `admin_criar_pedido`; `is_admin()`. RLS ligado em tudo; o público (anon) não lê nenhuma tabela, só executa as quatro funções acima. O painel exige login e uma linha em `admins`.

Usuário do painel: martonnedias@gmail.com (já criado no Supabase Auth, confirmado e presente em `admins`). Senha só o dono sabe.

Dados de teste: foram apagados e a sequência foi reiniciada (próximo pedido será TQR-0001). Qualquer pedido feito depois disso é real ou teste do dono.

## 3. Como o fluxo funciona

1. O cliente abre o site, escolhe a quantidade e preenche WhatsApp, nome (se for novo), endereço e pagamento.
2. Ao digitar o WhatsApp, o site chama `cliente_cadastrado`. Se já existe, o campo Nome some. O site nunca mostra o nome salvo (evita vazar dado por número).
3. Ao enviar, o site chama `criar_pedido` (tempo limite 7 s). O banco normaliza o telefone (só dígitos, com 55), valida, cria o cliente se for novo, calcula o total pela tabela `configuracoes`, grava pedido e item e devolve o código.
4. O site abre `wa.me/<número>` com a mensagem pronta, incluindo `🔖 Pedido: TQR-0001`. **Se o banco falhar, o WhatsApp abre do mesmo jeito, sem código.** Isso é intencional, para nunca perder venda.
5. O dono vê o pedido em `/admin/` como "pendente", conversa no WhatsApp, recebe o pagamento e muda o status: pendente → confirmado → pago → saiu para entrega → entregue (ou cancelado).

Detalhes de segurança já aplicados: texto vindo do público é sempre inserido com `textContent` no painel (testado com payload de XSS); limite de 5 pedidos por hora por cliente; telefone como chave única; preço e total calculados no servidor.

## 4. Decisões já tomadas

- Pontos do programa de fidelidade: 1 ponto por R$ 1 pago; 170 pontos = 1 garrafa grátis (valores editáveis em `configuracoes`: `pontos_por_real`, `pontos_por_brinde`). **Pontos só entram quando o pedido é marcado como pago.** Cancelar pedido pago estorna com linha negativa.
- Brinde de aniversário uma vez por ano, no mês do aniversário; some depois de resgatado.
- Consulta de saldo só depois de verificar o número com um código enviado por WhatsApp. Na primeira versão, o código pode ser enviado manualmente pelo dono.
- Cadastro: nome completo, WhatsApp, data de nascimento e e-mail; no site é opcional (nascimento e e-mail) e o aceite da política vale ao enviar o pedido.
- Pagamento e entrega continuam manuais. Sem gateway de pagamento por enquanto.
- Custo do insumo: cada compra atualiza o custo; mostrar lado a lado o último preço pago e a média ponderada.
- **Contador de garrafas vendidas (site):** valor exibido = base inicial (1.000, editável) + garrafas dos pedidos pagos (status pago, saiu para entrega ou entregue) + ajuste manual (editável). Atualiza a cada pedido pago, sem arredondar em centenas. Cancelar um pedido pago desconta automaticamente. A base de 1.000 é número real do dono (já vendeu mais de 1.000).
- **Endereços do cliente:** vários por cliente, com apelido e um padrão; o cliente pode apagar os dele no site (exclusão lógica, o pedido guarda cópia do endereço usado). Só aparecem depois de verificar o número por código.
- **Entrega:** três modalidades: retirada; entrega com taxa fixa por bairro (tabela editável no painel); entrega por aplicativo, em que o próprio cliente solicita pelo app dele. Frete grátis continua a partir de 5 garrafas (regra editável).
- **Promoções:** uma promoção por pedido na primeira versão (vale a mais vantajosa para o cliente); a estrutura já prevê acumular, desligado. Empilhar promoções pode ser decidido depois.
- **Usuários do painel:** só o administrador (dono) cadastra usuários, com perfis de acesso limitados e permissões por módulo.
- **Confirmação:** toda mudança de status de pedido abre um popup de confirmação.
- Stack: HTML, CSS e JS puros no site; Supabase para banco e login; GitHub Pages para hospedagem.

## 5. Pendências, em ordem

### 5.1 Ações do dono (a sessão deve lembrar e conferir)

- [ ] Fazer um pedido real de teste pelo site, entrar em `/admin/` e confirmar que o pedido aparece como pendente. Depois apagar o pedido de teste no **SQL Editor do Supabase** (ver armadilhas, seção 7): `delete from public.pedidos; delete from public.clientes; select setval('public.pedido_codigo_seq', 1, false);`
- [ ] Desligar o cadastro público de usuários no Supabase (Authentication, configuração de sign ups).
- [ ] Ativar verificação em duas etapas (MFA) para o administrador (a parte de tela no painel ainda precisa ser feita, ver 5.2).
- [ ] Conferir em Billing do Supabase se o projeto novo gera cobrança (a ferramenta não mostrou o custo ao criar).
- [ ] Voltar o número de recebimento para o original quando terminar os testes (`window.TQR_FONE` = `5586995884770`) e subir o `index.html`.
- [ ] Preencher no rodapé e nas políticas os campos entre colchetes: razão social ou responsável, endereço completo, e-mail, encarregado de dados (LGPD). Revisão das políticas por advogado antes de divulgar.

### 5.2 Código a fazer (fase 1 e endurecimento)

- [x] **Proteção contra robôs** no pedido (ex.: Cloudflare Turnstile ou função de borda com verificação) antes de divulgar. Hoje alguém pode enviar pedidos falsos em volume e testar números pelo `cliente_cadastrado` (existe só o limite de 5 pedidos por hora por cliente). *(Código pronto em 11/10: campo-isca no formulário + Cloudflare Turnstile com função de borda em `supabase/functions/criar-pedido`. Desligado até o dono criar o site no Cloudflare e publicar a função; passos em `supabase/functions/criar-pedido/README.md`. `cliente_cadastrado` ainda permite testar números.)*
- [x] **MFA no painel**: fluxo de inscrição e verificação de fator TOTP com a API de MFA do supabase-js. *(Pronto: tela de cadastro por QR code, desafio no login, botão Segurança. Para exigir no banco: `supabase/opcional/exigir_mfa_no_painel.sql`, só depois do dono cadastrar o fator.)*
- [ ] Testar o painel no navegador real com o login de verdade (os testes automáticos usaram respostas simuladas; a biblioteca vem da jsDelivr e nunca foi carregada de lá em teste). Se a CDN for um problema, hospedar o arquivo da biblioteca na pasta do site.
- [x] Preços estão duplicados: no JS do site (`UN=16.99, C3=42, U5=14`) e na tabela `configuracoes`. O banco é a fonte de verdade para o total gravado, mas a mensagem do WhatsApp usa o total do JS. Fazer o site ler os preços do banco (função pública de leitura) ou garantir os dois em sincronia ao mudar preço. *(Pronto no código: `obter_precos()` na migração `20261011_03_obter_precos.sql` — precisa ser aplicada no Supabase — e a mensagem do WhatsApp usa o total devolvido pelo servidor. Os textos fixos de oferta no HTML continuam manuais.)*
- [x] Painel: alerta de pedido novo (som ou notificação), histórico de status do pedido (tabela `pedido_eventos` já existe), editar observações do cliente, exportar para planilha. *(Pronto: aviso sonoro/notificação, histórico por pedido, exportar CSV. Falta: editar observações do cliente.)*
- [x] `admin/` fora do Google: já tem `noindex`; acrescentar `Disallow: /admin/` no `robots.txt` e não listar no sitemap. *(`robots.txt` e `sitemap.xml` criados; no GitHub Pages de projeto o robots.txt só vale com domínio próprio.)*
- [ ] Opcional: página ou seção de cadastro de fidelidade separada, usando `cadastrar_cliente` (a função já existe e exige nome, nascimento, e-mail e aceite).

### 5.3 Fase 2 — Financeiro e pontos

Seguir a especificação (seção 6 e o documento do projeto). Pontos de projeto já decididos:

- Criar `livro_pontos` (cliente, pedido, tipo: ganho, resgate, estorno, ajuste, aniversário; pontos; motivo; data). Saldo = soma das linhas, nunca um número editado à mão.
- Criar `lancamentos` (tipo entrada ou saída, categoria, valor, data, vencimento, pago, taxa, origem pedido ou compra).
- Ação única de servidor "marcar como pago" (função, não UPDATE solto do navegador) que, na mesma transação: muda o status, cria o lançamento de entrada e credita os pontos. Garantir **uma vez por pedido** com índice único parcial (um ganho por pedido, uma entrada por pedido).
- Cancelar pedido pago: gerar estorno (entrada negativa e pontos negativos) sem apagar linhas originais.
- Resgate de 170 pontos: só com saldo suficiente, nunca saldo negativo, registrado pelo dono no painel.
- Consulta de saldo no site: `solicitar_codigo(whatsapp)` gera código curto com validade (guardar só o hash, no máximo 5 tentativas), o dono vê o código no painel e envia pelo WhatsApp; `consultar_saldo(whatsapp, codigo)` devolve saldo e histórico. Sem código válido, nenhum dado pessoal aparece.
- Financeiro no painel: entradas automáticas dos pagos, saídas por categoria, taxas de Pix e cartão, contas a pagar e a receber, fluxo de caixa mensal, resultado simples, ponto de equilíbrio, exportação.
- **O site precisa comunicar o programa de fidelidade** (seção explicando como ganhar e resgatar, com a regra de 1 ponto por real e 170 pontos por garrafa grátis). Só publicar essa seção quando a fase 2 estiver no ar; hoje o formulário só diz "programa que vem aí".

### 5.4 Fase 3 — Custos e ficha técnica

- Tabelas `insumos` (unidade de compra, unidade de uso, fator de conversão, último preço, preço médio), `compras_insumo` (data, fornecedor, quantidade, valor), `ficha_tecnica` (produto, insumo, quantidade usada, rendimento, perda).
- Cada compra lançada atualiza o custo do insumo e gera saída no financeiro. Mostrar último preço e média ponderada lado a lado; histórico de preço com alerta de alta.
- Custo por garrafa e margem por oferta (unidade, combo 3, 5 ou mais), preço sugerido por margem-alvo, alerta de margem mínima. `itens_pedido.custo_unitario` já existe e deve receber o custo vigente quando o pedido for pago, para o lucro histórico não mudar.
- Não confundir com tabela nutricional oficial de rótulo (exige nutricionista); isso fica fora do sistema por enquanto.

### 5.5 Fase 4 — Extras

Brinde de aniversário, mensagens automáticas (exige API oficial do WhatsApp com modelos aprovados, consentimento e custo por conversa, avaliar antes), indicação de amigos, relatórios (mais pedidos, horários, bairros, recompra), mais de um usuário no painel com permissões.

### 5.6 Melhorias do site (antes da pausa do projeto)

- [ ] URL do feed do Instagram (Behold) no lugar de `INSTAGRAM_FEED_URL`.
- [ ] IDs de GA4 e Meta Pixel em `window.TQR_TRACKING` (o aviso de cookies só aparece quando há ID).
- [x] SEO: `og:image` com URL absoluta, canonical, `sitemap.xml` e `robots.txt` no domínio final; Google Business Profile. *(og:image absoluto, canonical, og:url e twitter:card feitos com a URL do GitHub Pages; trocar quando houver domínio próprio. Google Business Profile é com o dono.)*
- [ ] Domínio próprio (tqracai.com.br) e ajuste das URLs.
- [ ] Comprimir os JPGs restantes em `img/`.
- [ ] Corrigir o rótulo "CONGEADO" no material do produto; conferir avisos de alérgenos e lactose.
- [ ] Novas fotos de pessoas tomando o açaí (geradas por IA) e avaliações reais na seção "Quem toma, volta" (hoje está sem avaliações).
- [ ] Decidir se mantém os rótulos pequenos acima dos 12 títulos e o espaçamento apertado da seção do problema.
- [ ] Alinhar `DESIGN.md` e CSS (muitos valores de cor fixos no CSS em vez de tokens).
- [ ] Teste do WhatsApp em celular real (Android e iPhone). Em alguns navegadores, `window.open` depois de uma chamada assíncrona é bloqueado; o código já cai para `location.href`, mas confirmar na prática.
- [ ] Atualizar o documento do projeto `claude/landing-page-decisoes.md` (está na versão de 08/10).

### 5.7 Novos requisitos (pedido do dono em 11/10/2026) e etapas de implementação

O dono pediu para fazer tudo na mesma rodada. Estes itens entram no projeto existente (fases 1 a 4) e a ordem abaixo respeita as dependências. Cada etapa termina com teste e commit; migrações de banco só são aplicadas no Supabase com autorização do dono.

Requisitos novos:

1. Endereços múltiplos por cliente, com histórico, escolha no pedido e exclusão pelo cliente.
2. Cadastro de produtos e precificação no painel; o site passa a montar a vitrine e o formulário a partir do banco.
3. Promoções configuráveis: faixa por quantidade (regra atual), combo/kit, leve X pague Y, casadinha (A dá desconto em B), desconto em % ou R$, cupom (código, validade, limite de usos), desconto no primeiro pedido, frete grátis por valor ou quantidade, brinde, preço por dia/horário, desconto por forma de pagamento. Campos comuns: nome, tipo, regra, validade, limite de uso, prioridade, acumula ou não (desligado).
4. Popup de confirmação a cada mudança de status de pedido (inclui cancelar, que hoje usa `confirm`).
5. Botão "Abrir site" no painel e link "Ir para o site" na tela de login.
6. Contador de vendidos automático (regra na seção 4), com base e ajuste editáveis no painel.
7. Configurações no painel que o site lê do banco: preços, combos, formas de pagamento (com taxa e desconto), taxas de entrega por bairro, frete grátis, WhatsApp de recebimento (hoje `TQR_FONE` fixo), horário de atendimento, mínimo e máximo por pedido, aviso temporário no site, pontos (`pontos_por_real`, `pontos_por_brinde`).
8. Módulo de usuários com perfis e permissões por módulo (pedidos: ver, mudar status, cancelar; clientes; produtos; promoções; configurações; financeiro; usuários). Perfis iniciais sugeridos: Dono (tudo), Gerente (tudo menos usuários), Atendente (pedidos e clientes, sem financeiro nem preços), Entregador (só ver pedidos de entrega e marcar saiu/entregue). Criar usuário exige a chave de serviço, por isso vai por função de borda `admin-usuarios`, nunca pelo navegador.

Etapas:

- **Etapa 1 — Painel, só front (sem banco):** popup de confirmação de status, botão "Abrir site", link no login. Sem risco para os dados.
- **Etapa 2 — Fundação de dados (migrações):** perfis e permissões (substituir `is_admin()` por checagem de permissão mantendo o admin atual como Dono, para ninguém ficar sem acesso); `formas_pagamento`; `bairros_entrega`; novas chaves em `configuracoes` (contador_base, contador_ajuste, horário, aviso, mínimo/máximo, WhatsApp); colunas novas em `produtos` (preço, foto, descrição, ordem, categoria); `taxa_entrega` e modalidade no pedido; funções públicas de leitura (`obter_config_publica`, `obter_contador`, `obter_vitrine`).
- **Etapa 3 — Usuários e permissões:** módulo no painel + função de borda `admin-usuarios` (criar, desativar, trocar perfil, redefinir senha). Todas as telas seguintes já nascem respeitando as permissões. Maior risco da entrega (RLS): testar bloqueio e liberação por perfil antes de seguir.
- **Etapa 4 — Configurações no painel + site lendo do banco:** telas de pagamento, entrega por bairro, horário, aviso, contador (base e ajuste), WhatsApp. O site passa a usar `obter_config_publica` e `obter_contador`; `TQR_FONE` fica só como reserva se a leitura falhar.
- **Etapa 5 — Produtos, promoções e motor de preço:** CRUD de produtos com foto (Supabase Storage); `promocoes` com regras em JSON validado; função `calcular_pedido` no servidor (itens, cupom, bairro, pagamento) que é a única fonte do total; `criar_pedido` passa a aceitar vários itens e a taxa de entrega (atualizar também a função de borda `criar-pedido` do Turnstile); site monta vitrine, oferta e formulário a partir do banco e mostra a promoção aplicada. Os textos fixos de oferta no HTML são substituídos por dados.
- **Etapa 6 — Verificação por código + endereços múltiplos:** `codigos_verificacao` (hash, validade, no máximo 5 tentativas), `solicitar_codigo`/`verificar_codigo`; código aparece no painel para o dono enviar pelo WhatsApp (mesma base do saldo de pontos); `enderecos_cliente` com apelido, padrão e exclusão lógica; site lista, escolhe, adiciona e apaga endereços após verificação; painel mostra e edita na ficha do cliente. Sem verificação o site segue só com "lembrar neste aparelho".
- **Etapa 7 — Fase 2 (pontos e financeiro):** como na seção 5.3, agora com `formas_pagamento.taxa` alimentando as taxas, e "marcar como pago" no servidor também atualizando o contador de vendidos.
- **Etapa 8 — Fase 3 (custos) e Fase 4 (extras):** seções 5.4 e 5.5. Usuários com permissões já cobertos pela etapa 3.
- **Fechamento de cada etapa:** testes com respostas simuladas, verificação dos alertas de segurança do Supabase, atualização deste arquivo e aviso ao dono do que precisa ser aplicado, publicado ou testado em celular real.

Pontos de atenção:

- Taxa de entrega por bairro muda o total do pedido (hoje não entra no total) e a mensagem do WhatsApp; entrega por aplicativo não soma taxa.
- Trocar `is_admin()` por permissões mexe em todas as políticas de segurança; preservar o acesso do admin atual e testar antes de aplicar.
- Promoção e preço nunca vêm do navegador: só `calcular_pedido` calcula; o site apenas exibe.
- Contador: se a base de 1.000 deixar de ser real, ajustar o texto; hoje é real segundo o dono.

Status em 12/10/2026 (código na branch `claude/bold-lovelace-25ml91`; **migrações 03 a 06 e a função `admin-usuarios` aplicadas no Supabase em 12/10**, site e painel ainda NÃO publicados no GitHub Pages; ver `supabase/LEIA-ME.md`):

- [x] Etapa 1: popup de confirmação de status (inclui cancelar), botão "Abrir site" no painel e link "Ir para o site" no login.
- [x] Etapa 2: migração 04 (perfis dono/gerente/atendente/entregador, formas de pagamento, bairros, configurações, contador, RLS por permissão).
- [x] Etapa 3: módulo Usuários no painel + função de borda `admin-usuarios`; interface do painel respeita as permissões.
- [x] Etapa 4: aba Configurações (loja, horário, aviso, limites, contador, pontos, formas de pagamento, bairros); o site lê tudo do banco.
- [x] Etapa 5: migração 05 (promoções de 8 tipos, motor `motor_pedido`, `simular_pedido`, `criar_pedido_v2`, fotos no Storage); abas Produtos e Promoções; pedido manual com itens, bairro e cupom; o site monta ofertas, extras, bairro com taxa, cupom e total a partir do servidor.
- [x] Etapa 6: migração 06 (código de verificação, sessão do cliente, `enderecos_cliente`); site com "Usar um endereço salvo"; painel com códigos pendentes (botão de WhatsApp) e endereços na ficha do cliente.
- [x] Etapa 7 (fase 2): migrações 07 e 08 **aplicadas em produção em 12/10**. Pedido que chega a "pago" (ou além) gera, uma vez só, a entrada no caixa (com a taxa da forma de pagamento) e os pontos; cancelar pedido pago estorna (valor e pontos); pedido cancelado não volta. Resgate (170 pontos), ajuste manual e brinde de aniversário (premissa: 170 pontos, editável em Configurações, uma vez por ano no mês) são funções do banco, com o saldo nunca ficando negativo. Painel: aba Financeiro (resultado do mês, fluxo de 12 meses, lançamentos, a pagar/receber, ponto de equilíbrio, CSV) e pontos na ficha do cliente. Site: seção "Programa de pontos" com consulta do saldo por código. Permissão nova: `financeiro.gerir` (perfil Gerente já recebeu).
- [ ] Etapa 8 (fases 3 e 4: custos/ficha técnica e extras): não iniciada. Decisões pendentes na seção 8 (margem-alvo, insumos, quantas compras entram na média, custo de entrega).

Regras do motor de preço: uma promoção por pedido (a mais vantajosa para o cliente); cupom só vale digitado; desempate por prioridade; frete grátis de uma promoção só vale quando a regra dela se aplica; brinde conta como benefício e não entra no contador de vendidos; limite de usos é reservado com trava na criação do pedido.

Pendências conhecidas desta rodada: textos fixos de marketing no HTML (hero, textos de SEO, mensagens de WhatsApp dos botões "Combo"/"Kit") ainda citam R$ 16,99/R$ 42/R$ 14 e não mudam sozinhos; entrega por aplicativo não tem taxa no sistema (combinada no WhatsApp); o código de verificação é enviado manualmente pelo dono (guardado em texto por até 10 min no banco, ver comentário da migração 06); `cliente_cadastrado` continua permitindo testar números.

## 6. Especificação resumida das fases (modelo de dados completo)

A especificação completa está no documento "TQR Açaí — Especificação do sistema de gestão e fidelidade" (Claude Docs, no projeto do dono). Tabelas planejadas além das da fase 1: `livro_pontos`, `lancamentos`, `insumos`, `compras_insumo`, `ficha_tecnica`, `codigos_verificacao` (a criar). `configuracoes` guarda regras editáveis: `preco_unitario`, `preco_combo3`, `preco_5mais`, `pontos_por_real`, `pontos_por_brinde`, `whatsapp_loja`.

Critérios de aceite importantes (resumo): pedido do site aparece no painel como pendente em até 5 s com código único; o mesmo WhatsApp digitado de formas diferentes é o mesmo cliente; marcar pago duas vezes não duplica entrada nem pontos; cancelar pedido pago estorna; resgatar 170 pontos baixa o saldo sem ficar negativo; sem login nenhum dado do painel é acessível; painel utilizável no celular sem rolagem horizontal.

## 7. Armadilhas conhecidas (aprendidas na sessão anterior)

- **DELETE pela ferramenta do Supabase trava** (expira após 180 s e não executa). Para apagar dados, o dono precisa rodar o comando no SQL Editor do painel do Supabase. Leituras, INSERT e migrações funcionam normalmente.
- Em CSS, `display:flex` em `.fld` ganha do atributo `hidden`; existe a regra global `[hidden]{display:none!important}` no `index.html` e no painel por causa disso. Não remover.
- O ambiente de testes da sessão anterior **não alcança** o GitHub Pages, as fontes do Google nem a jsDelivr no navegador; os testes foram feitos com Playwright e respostas simuladas do Supabase. Um teste real precisa do dono ou de um ambiente com internet liberada.
- Os comandos de exclusão e o push ao GitHub dependem de autorização do ambiente; se aparecer "not in this session's authorized repository set", o repositório não está nas fontes da sessão.
- Os alertas de segurança do Supabase para as funções `SECURITY DEFINER` chamáveis por usuários anônimos são **intencionais** (são as funções públicas do pedido). Não revogar sem substituir a forma de pedido.
- Ao testar localmente a página de pedido, bloqueie a rede para o Supabase ou use respostas simuladas; senão cada teste cria cliente e pedido reais no banco do dono.

## 8. Decisões em aberto (perguntar ao dono antes de construir)

- O que é o brinde de aniversário (uma garrafa, desconto, outro) e a validade dentro do mês.
- Custo da entrega entra no custo por garrafa ou fica como despesa separada.
- Quantas compras recentes entram na média ponderada do custo.
- Margem-alvo e margem mínima para os alertas.
- Quem mais terá acesso ao painel e com que permissão.
- Código de verificação do saldo: manual na fase 2 ou pela API oficial do WhatsApp desde o início.
- Lista de insumos, quantidade por garrafa e preços atuais; taxas reais de Pix e cartão; categorias de despesa.
- Se o projeto Supabase novo for pago, plano e orçamento.
- **(novos, 11/10)** Perfis e permissões exatos de cada nível (a lista da 5.7 é sugestão). Quais tipos de promoção entram ativos já na primeira versão (hipótese atual: todos os da lista, uma por pedido). Valor da taxa por bairro e lista de bairros atendidos. Se o endereço salvo só aparece depois do código ou se basta o WhatsApp (hipótese atual: depois do código). Formas de pagamento além de Pix e cartão e suas taxas.

## 9. Como começar a nova sessão

1. Confirmar com o dono o que quer fazer primeiro (sugestão: itens 5.1 e 5.2, depois fase 2).
2. Ler `index.html` (trecho do formulário e o bloco `window.TQR_FONE`), `admin/index.html` e `supabase/migrations/`.
3. Antes de mexer no banco, listar as tabelas e funções atuais e conferir se batem com as migrações.
4. Mudanças de banco entram como novos arquivos em `supabase/migrations/` (e aplicadas no projeto), nunca só no painel.
5. Testar cada mudança de tela com respostas simuladas e, quando possível, confirmar com o dono em um pedido real.

Mensagem sugerida para colar na primeira mensagem da nova sessão:

> Leia o arquivo `HANDOFF.md` na raiz do repositório e continue o projeto TQR Açaí a partir da seção 5. Comece pelas pendências 5.2 (proteção contra robôs, MFA no painel, preços lidos do banco) e me diga o que precisa de mim antes de construir. Não coloque chaves secretas no código e não envie pedidos de teste ao WhatsApp real.

## Produto como assinatura (roteiro)
Decisão do dono: servir a outros tipos de delivery. Caminho escolhido: **uma instância por cliente** (um projeto Supabase, um site e um painel por cliente, a partir deste modelo); multiempresa único só depois dos primeiros clientes.
1. **Pacote de marca** (feito no painel: `admin/marca.js`, ver `admin/MARCA.md`): nome, logo, cores, fonte de destaque, textos e vocabulário do produto.
2. Levar o pacote de marca e o vocabulário também ao site público e às mensagens de WhatsApp.
3. Generalizar o que é específico de açaí: unidade "garrafa", "Montagem" (grupos de opções), pontos por garrafa, textos da Ajuda. Módulos ligáveis por segmento (custos e estoque, montagem, CRM).
4. **Assistente de implantação:** criar projeto Supabase, aplicar `supabase/migrations`, criar o usuário dono e o primeiro catálogo; script único.
5. **Cobrança recorrente** (Asaas assinatura) com bloqueio gentil por atraso; termos de uso, contrato de serviço e LGPD (a empresa do dono é *operadora* dos dados do cliente).
6. Suporte e documentação por cliente (a Central de Ajuda já é a base).
