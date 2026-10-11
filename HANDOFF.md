# TQR Açaí — Continuação do projeto (handoff)

Documento para uma nova sessão que não viu a conversa anterior. Leia tudo antes de agir. Data deste handoff: 11/10/2026. Dono do projeto: Martonne (martonnedias@gmail.com). Idioma de trabalho: português do Brasil.

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

## 9. Como começar a nova sessão

1. Confirmar com o dono o que quer fazer primeiro (sugestão: itens 5.1 e 5.2, depois fase 2).
2. Ler `index.html` (trecho do formulário e o bloco `window.TQR_FONE`), `admin/index.html` e `supabase/migrations/`.
3. Antes de mexer no banco, listar as tabelas e funções atuais e conferir se batem com as migrações.
4. Mudanças de banco entram como novos arquivos em `supabase/migrations/` (e aplicadas no projeto), nunca só no painel.
5. Testar cada mudança de tela com respostas simuladas e, quando possível, confirmar com o dono em um pedido real.

Mensagem sugerida para colar na primeira mensagem da nova sessão:

> Leia o arquivo `HANDOFF.md` na raiz do repositório e continue o projeto TQR Açaí a partir da seção 5. Comece pelas pendências 5.2 (proteção contra robôs, MFA no painel, preços lidos do banco) e me diga o que precisa de mim antes de construir. Não coloque chaves secretas no código e não envie pedidos de teste ao WhatsApp real.
