# Sistema de design: Central TQR

Referência do painel administrativo (`admin/index.html`). Método: auditoria de tokens e componentes, depois documentação. Linhas citadas são aproximadas e se referem ao bloco `<style>` (linhas 11 a 487 de `admin/index.html`). Para trocar a identidade para outro cliente, veja `admin/MARCA.md`; aqui está o porquê e o como detalhado.

## 1. Princípios

1. **Balcão.** O painel é um quadro de operação ao vivo, usado em pé, no celular, com pressa. O que está parado ou atrasado aparece primeiro; a próxima ação é um toque.
2. **Rótulo.** A identidade vem do rótulo do produto: casca (menu e topo) em berinjela, fio de ouro, fundo lilás claro, títulos de marca em fonte script. Ouro só marca foco, seleção e o "agora".
3. **Pulso.** O sinal de assinatura é o "Pulso do dia": linha de 24 h com horário de funcionamento sombreado e pedidos como marcas coloridas por estado.
4. **Operar rápido.** Poucas variantes, rótulos curtos, ação principal destacada (uma `.btn.go` por área), listas compactas, painéis laterais fixos para não perder o contexto, estados por cor mais texto.
5. **Marca trocável.** Cor, logo, fonte de destaque, vocabulário e frases vêm de `marca.js`. O HTML e o CSS nunca são editados por cliente.
6. **Consistência antes de criatividade.** Antes de criar uma classe, procure uma existente (seção 4).

## 2. Tokens

Legenda: **[M]** vem do pacote de marca (`marca.js`, aplicado por `aplicaMarca()` com `setProperty` na raiz). **[F]** fixo no CSS. **[D]** derivado: calculado a partir de um token [M] com `color-mix`, então acompanha a marca.

### 2.1 Cores

| Token | Valor padrão | Papel | Origem |
|---|---|---|---|
| `--casca` | `#1a0a2b` | Menu lateral e topo | [M] `cores.casca` |
| `--casca-2` | `#2a1245` | Realces da casca | [M] `cores.casca2` |
| `--brand` | `#59298a` | Botão primário, seleção, links, títulos de destaque | [M] `cores.marca` |
| `--brand-hover` | `#491f73` | Hover do primário | [M] `cores.marcaHover` |
| `--ouro` | `#e8be62` | Foco, item ativo do menu, selo de contagem, "agora" do pulso | [M] `cores.destaque` |
| `--ouro-2` | `#fbe2a0` | Nome da marca no topo | [M] `cores.destaque2` |
| `--fundo` / `--bg` | `#f5f1f9` | Fundo da área de trabalho | [M] `cores.fundo` |
| `--brand-soft`, `--brand-line` | 10% / 26% da marca sobre branco | Fundo e borda de seleção, chips, banner | [D] |
| `--line`, `--line-strong` | 12% / 22% da marca | Bordas de cartão e de campo | [D] |
| `--casca-3`, `--casca-glow`, `--ouro-fio`, `--ouro-forte`, `--side-muted` | misturas da casca e do ouro | Gradiente do topo, fio de ouro, texto apagado do menu | [D] |
| `--surface` / `--surface-2` | `#fff` / `#faf9fc` | Cartão / cartão aninhado, campo de produto | [F] |
| `--text` / `--muted` | `#1d1726` / `#655d72` | Texto / texto secundário | [F] |
| `--ok` + `--ok-soft` | `#14703f` / `#e4f4eb` | Pago, aberto, sucesso | [F] semântico |
| `--warn` + `--warn-soft` (+ `--warn-dot` `#d98c10`) | `#7d5200` / `#fcf0d4` | Pendente, atenção | [F] semântico |
| `--info` + `--info-soft` | `#1b57a6` / `#e3edfa` | Confirmado | [F] semântico |
| `--bad` + `--bad-soft` | `#b0222a` / `#fbe6e7` | Atrasado, cancelado, erro, sair | [F] semântico |
| `--wa` | `#12823f` | Botão de WhatsApp | [F] |

Cores de estado do pedido (use sempre `.tag.<estado>` e `COR_ST`): pendente = âmbar, confirmado = azul, pago = verde, saiu_entrega = marca, entregue = cinza, cancelado = vermelho. Estado nunca é só cor: sempre há o texto do estado na tag.

Série de gráficos (`PAL`, ~linha 2666): 8 cores fixas, a primeira é a cor da marca. Ordem estável por categoria.

### 2.2 Tipografia

| Token | Valor | Uso | Origem |
|---|---|---|---|
| `--f-ui` | Poppins (500/600/700, Google Fonts) com sistema como reserva | Títulos `h2`/`h3`, números de `.stat b`, data do início | [F] |
| `--font` | Inter, depois fontes do sistema | Corpo e controles | [F] |
| `--f-destaque` | `'TQRDestaque'`, família do pacote, cursive | Saudação, nome da marca, telas vazias, login (`.script-h`, `.pulso-vazio`, `.fila-vazia`) | [M] `fonteDestaque` |

Escala usada: corpo `.9375rem`/1.5; campo `.875rem`; rótulo `.78rem`; cabeçalho de seção de formulário `.78rem` caixa alta com `letter-spacing:.08em`; `h2` 1.45rem (1.3 no celular); `h3` .95rem; indicador `.stat b` 1.55rem (1.25 compacto); saudação 2.1rem (1.7 no celular). Números sempre com `tabular-nums` (definido no `body`).

### 2.3 Espaçamento, raios, sombras, motion

- **Espaçamento** (sem tokens; valores recorrentes): 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 28, 32 px. Prefira 8, 12, 16, 20 em código novo. Gaps de grade: 10 a 14 px entre campos, 12 a 18 px entre cartões. Gutter da área de trabalho: 32 px (14 no celular).
- **Raios**: `--r` 12px (cartão, faixa, banner), `--r-sm` 8px (botão, campo de produto), 7px (campos e `.ptools`, valor fixo), 999px (tag, chip, pílula), 14 a 18px (diálogos e login), 50% (avatar, `.info`).
- **Sombras**: `--sh1` (repouso do cartão), `--sh2` (hover de `.ped`, login), sombra de diálogo `0 24px 60px -20px`, toast `0 10px 30px -10px`.
- **Motion**: 150 a 200 ms em fundo, borda e sombra; `gira` .7s no botão de atualizar. `prefers-reduced-motion` zera transições (nota: não zera animação `gira`, veja dívidas).

### 2.4 Layout e alvos de toque

| Token | Valor | Obs. |
|---|---|---|
| `--top` | 60px (56 no celular) | Altura do topo [F] |
| `--side` | 244px | Largura do menu [F] |
| Largura de conteúdo | `.wrap` 1080px; formulário `form.card` 760px; `cfg-card` 900px | [F] |
| Painel lateral fixo | 300 a 340px (`.fin-grid`, `.ini-grid2`, `.np-grid` 320px), `top:76px` | [F] |

**Breakpoints** (todos max-width, de fora para dentro): 1100px (painéis laterais empilham), 1000px (pedido manual: resumo vira barra fixa embaixo), **959px (celular e tablet: menu vira faixa horizontal, alvos 44px)**, 700px (grids viram uma coluna), 520px (oculta site e atualizar).

**Alvos de toque**: desktop 32 a 40 px (compacto, ver dívidas); a partir de 959px todo `.btn`, `.hbtn`, campo e item de menu tem mínimo de **44px**. Botão de ação da fila (`.fi-bt`) 40 desktop, 44 celular, largura mínima 140px.

## 3. Princípios de composição

- Um primário (`.btn.go`) por cartão ou barra. Demais ações usam `.btn` neutro ou `.sm`.
- Ação destrutiva sempre `.btn.danger` e com confirmação em `dialog#dlg`.
- Texto auxiliar `.muted`; ajuda contextual no `.info` (ponto de interrogação) em vez de parágrafos longos.
- Tela vazia: frase curta da marca (`marca.js > textos`), em fonte de destaque ou em `.empty`.

## 4. Inventário de componentes

Estados: **H** hover, **F** foco, **D** desabilitado, **E** erro, **V** vazio, **C** carregando. "—" = não existe hoje.

| Componente | Classes / variantes | Quando usar | Estados |
|---|---|---|---|
| Botão | `.btn` (neutro), `.go` (primário), `.wa` (WhatsApp; `.feito` após enviar), `.danger`, `.sm`, `.on` (selecionado) | Neutro para ação comum; `.go` para a ação principal da área; `.wa` só para abrir conversa; `.danger` para excluir/cancelar | H sim; F `:focus-visible`; D `[disabled]` (opacidade .5); C: sem estado (sem spinner, veja dívidas); E: —|
| Botão de topo | `.hbtn` (`.out` = sair), `#btnAlert.on` (alerta sonoro ativo) | Ações globais no cabeçalho, sobre a casca escura | H, F; ativo = bolinha verde |
| Campo | `.fld` (rótulo + `input/select/textarea`), `.fld.inl` (linha), `.row` (campo + botão), `.chk`, `.perms` | Todo formulário. `<small>` dentro do rótulo para dica | H borda; F borda marca + anel 3px; D: —; E: —; placeholder `#8a8296` |
| Busca e filtros | `.filters` (barra branca com borda), `.filtros-det` (recolhe no celular), `.seg` (segmentado), `.cfg-seg` | Filtro acima de lista. `.seg` para 2 a 4 opções exclusivas | `.seg .btn.on` preenche com marca |
| Cartão de pedido | `.ped` (+ `.top`, `.cod`, `.acts`, `.hist`) | Um pedido ou registro com ações | H sombra `--sh2` e borda de marca |
| Cartão de formulário | `form.card` / `div.card` (título `b` em caixa alta de marca) | Agrupar campos; `form.card .card` é o subcartão | — |
| Indicadores | `.cards` + `.stat` (`.cards-6` compacto) | Faixa de números no topo da página | — |
| Cartão de relatório | `.rel-card`, `.rel-grid`, `.rel-note`, `.leg` | Gráficos e tabelas de análise | V: `.rel-note` |
| Tag de estado | `.tag.pendente/.confirmado/.pago/.saiu_entrega/.entregue/.cancelado` | Estado do pedido; sempre com texto | — |
| Chip / contador | `.chip`, `.chip.alerta`, `.nbadge` (selo no menu) | Contagem curta ao lado de título ou item | `[hidden]` quando 0 |
| Menu lateral | `nav#tabs .btn`, `.nav-g` (rótulo de grupo), `.btn.on` | Navegação principal. No celular vira faixa rolável com máscara | H fundo claro 7%; ativo = gradiente ouro + ícone ouro |
| Cabeçalho | `header.top`, `.brand`, `.bname`, `.hact`, `.uchip` + `.avatar` | Identidade, ações globais e usuário | — |
| Quadro (kanban) | `.kanban`, `.kcol` (`.over` ao arrastar), `.kcard` (`.drag`), `.kvazio` | Pedidos por etapa; arrastar ou botão | V `.kvazio`; atraso `.late` |
| Pulso e fila | `.pulso` (+ `.pulso-svg`, `.pulso-leg`, `.pulso-vazio`), `.fila` (`.fila-i`, `.atraso`, `.novo`, `.fi-bt`, `.fila-vazia`, `.fila-mais`) | Início: ritmo do dia e fila ao vivo com a próxima ação | V frases da marca; atraso = fundo vermelho; novo = fundo âmbar |
| Alertas e faixas | `.alerta.atencao/.ruim`, `.banner`, `.primeiro` + `.passo`, `.novaversao` | Aviso acionável; banner informativo; onboarding; nova versão | `.passo.ok` riscado |
| Ajuda | `.info` + `.info-pop`, `.helpbtn`, `.aj` (acordeão `details`) | Explicação sob demanda | `aria-expanded` |
| Diálogos | `dialog#dlg` (confirmar, 440px), `#dlgFicha` (ficha, 640px), `#dlgImprimir` (560px) | Confirmação e fichas; ações em `.da` alinhadas à direita | backdrop 50% |
| Toast | `#toast`, `#toast.err` | Confirmação rápida e erro leve | E fundo vermelho |
| Pedido manual | `.np-grid`, `.np-card` + `.np-n` (passo numerado), `.np-prod` (`.sel`), `.np-st`/`.np-b` (quantidade), `.np-sum`, `.np-go`, `.nm-*` (opções) | Montar pedido em passos com resumo fixo | `.sel` borda marca; `.nm-op.off` |
| Gráficos | `.chart` (SVG), `.pz` (rosca + `.pz-leg`), `.hb` (barra horizontal), `.fid-bar` | Série temporal, composição, ranking, progresso | V: `.empty` |
| Documento impresso | `.doc*`, `.doc-head`, `.doc-tbl`, `#printArea`, `.fmt-80`/`.fmt-a4` | Comanda (80 mm) e relatório (A4) | Cores fixas (papel) |
| Vazio | `.empty` (tracejado), `.kvazio`, `.fila-vazia`, `.pulso-vazio` | Sempre que uma lista pode vir sem itens | — |

**Lacunas de estado**: não há estilo de erro de campo (borda vermelha + mensagem), nem estado de carregando (esqueleto ou spinner) em listas e botões. Proposta para estender (classes sugeridas, ainda inexistentes): `.fld.err` com borda `--bad` e `small` em `--bad`; `.btn.load` com `aria-busy` e spinner reaproveitando `gira`.

## 5. Padrões de página

1. **Cabeçalho de módulo**: `.phead` com `h2` à esquerda e `.ptools` (seletores `min-height:32px`) à direita, quebra em linha no celular. Uma linha `.muted` explicativa abaixo do `h2` (máx. 72ch). No Início o equivalente é `.ini-top` (data em caixa alta, saudação script, selo "aberto").
2. **Barra de ferramentas**: `.filters` (busca flexível `min-width:180px` + selects + `.seg`). No celular, vira `details.filtros-det` recolhido.
3. **Faixa de indicadores**: `.cards` antes da lista, 4 a 6 números.
4. **Grade de formulário**: `form.card` (máx. 760px) com `.grid2` / `.grid3` (alinhadas por `align-items:end`) ou `.row2`; secções separadas por `b` em caixa alta. Em configurações, `.cfg-card` com abas `.cfg-seg`, painéis `.cfg-pane` e **`.cfg-bar` fixa na base** com Salvar. Colunas viram uma abaixo de 700px.
5. **Lista compacta**: `.list.lcompact` com `.ped` em linha (código, tag, dados e `.acts` à direita, `margin-left:auto`). Lista densa de 1 coluna, gap 5px. Sem `lcompact`, `.list` tem 2 colunas a partir de 900px.
6. **Painel lateral fixo**: conteúdo + coluna de 300 a 340px com `position:sticky; top:76px` (`.fin-side`, `.ini-side`, `.np-side`). Abaixo de 1100px empilha; no pedido manual o resumo vira barra fixa no rodapé (`bottom:0`).
7. **Quadro**: `.kanban` rola na horizontal com `scroll-snap`.

## 6. Acessibilidade

- **Contraste (meta WCAG AA)**: texto 4.5:1, componentes 3:1. Pares de estado já usam texto escuro sobre fundo suave (ex.: `--warn` sobre `--warn-soft`). Verifique em cada novo pacote: `marca` com texto branco no `.btn.go`; `destaque` sobre `casca` (selo, item ativo); `fundo` com `--muted`.
- **Foco**: `:focus-visible` com contorno 2px em `--ouro` mais halo da marca. Campos usam borda da marca e anel de 3px. Nunca remova o contorno sem substituto visível. Ouro sobre fundo claro tem pouco contraste: o halo da marca é o que garante a visibilidade (veja dívidas).
- **Toque 44px** no celular e tablet (<=959px) para botões, itens de menu, campos e botões do topo. Não crie controle clicável menor que 44px nesse modo; no desktop o mínimo de 32px é exceção a ser reavaliada.
- **Semântica**: `dialog` com `aria-labelledby`, ícones decorativos sem texto exigem `aria-label`, classe `.sr-only` para texto só de leitor de tela, gráficos SVG precisam de texto alternativo ou tabela equivalente.
- **Cor nunca sozinha**: estado = cor + texto (tag), atraso = cor + "atrasado" na meta.
- **Movimento**: respeite `prefers-reduced-motion`.
- **Viewport e zoom**: não bloquear zoom; `-webkit-text-size-adjust:100%` já está definido.

## 7. Criar um pacote de marca para outro cliente

Checklist:

1. Copie `admin/marca.js` para o novo cliente e altere `nome`, `empresa`, `subtitulo`.
2. Entregue o logo (quadrado, ~64px ou mais, `.webp`/`.png`) e aponte `logo`.
3. Defina `cores`: `casca` (escura, texto claro precisa ter 4.5:1), `casca2`, `marca` (branco sobre ela >= 4.5:1), `marcaHover` (mais escura), `destaque` e `destaque2` (clara; é usada como foco e item ativo), `fundo` (clara, quase neutra).
4. Escolha a fonte de destaque: arquivo `.ttf`/`.woff2` com licença, caminho em `fonteDestaque.arquivo` e `familia` genérica de reserva. Use só em saudação, nome e telas vazias, nunca em corpo.
5. Ajuste `vocabulario` (`unidade`/`unidades`) para a palavra do produto (pizza, marmita).
6. Reescreva `saudacao` e `textos` (`filaVazia`, `pulsoVazio`, `montagemTitulo`, `exemploCompra`, `loginSub`) no tom do cliente.
7. No painel (banco): horário de funcionamento, catálogo, bairros, formas de pagamento, preços.
8. Teste: login, Início (com e sem pedidos), uma lista, um formulário, mobile 375px. Confira contraste dos pares do item 3 e que o foco aparece.

**NUNCA mexer, por cliente**: o HTML do painel, o bloco `<style>`, nomes de classes e ids, os tokens semânticos de estado (`--ok`, `--warn`, `--info`, `--bad`: significado igual em todos os clientes), a lógica em JS. Também não escreva cores em `style=""` nem `#hex` no CSS: todo valor visual novo entra como token (via pacote ou derivado com `color-mix`).

Limitação atual: o pacote só alcança 7 cores, a fonte de destaque e textos. Identidade que exija outra tipografia de interface (Poppins/Inter são fixas) ou outro raio exige evolução do núcleo, não do pacote.

## 8. Dívidas e inconsistências (auditoria)

Pontuação informal: tokens de cor 7/10, componentes 6/10, estados 4/10. Prioridade em ordem de impacto.

| # | Problema | Onde (aprox.) | Sugestão |
|---|---|---|---|
| 1 | Três `:root` e três camadas de CSS (base, "visual premium", "Central TQR") redefinem os mesmos tokens e regras; vale a última. | 12, 250, 369 | Consolidar em um `:root` e remover o que foi sobrescrito |
| 2 | Tokens duplicados: `--side-bg` (#1a0a2b) igual a `--casca`; `--gold` (usado em `.novaversao`, com reserva) igual a `--ouro`; `--r`, `--r-sm`, `--top`, `--side` definidos 2 vezes; `--brand-soft`/`--brand-line`/`--line`/`--line-strong` redefinidos; `--side-muted` 3 vezes; `--casca-2` definido e não usado. | 13 a 18, 250, 369 a 370 | Manter só `--casca`/`--ouro`; `.novaversao` e `.nbadge` passarem a usar `--ouro` |
| 3 | `--side-bg` e `#240f3b` (fim do gradiente do menu) não acompanham a marca; `.side` acaba sobrescrito por `var(--casca)`. | 269, 387 | Remover o gradiente morto |
| 4 | Regras repetidas e sobrescritas: `.btn` (min-height 40, depois 36, depois 44 no celular), `.btn.go` (3x), `.nbadge` (3x), `.login`/`.login form` (3x), `.bar`, `.fld input` (min-height 40, 34, 42), `h2` (4x). Estilos de `.cfg-card`/`.lcompact` usam `!important`. | 54, 282, 284, 395; 397; 335 a 340 | Ficar com uma definição por componente; trocar `!important` por especificidade |
| 5 | Cor da marca escrita à mão: `rgba(89,41,138,...)` no foco, halo de campo e sombra da logo; `#59298a` em `.doc-head`/`.doc-tbl`; `PAL[0]` fixo. Não trocam com o pacote. | 256, 288 a 289 (foco), 396, 355, 2666 | Usar `color-mix(in srgb,var(--brand) 16%,transparent)`; `PAL[0]` ler `--brand` |
| 6 | Cores fixas fora dos tokens: `#efedf4`/`#efecf6` (kcol), `#bdb5ca` (hover de borda), `#e6b9bc`, `#ecd49a`, `#bfe3cd`, `#9a90a8`, `#8c9a94` (entregue), `#8a8296` (placeholder), `#4a4256`, `#463f52`/`#eeecf2` (tag neutra), `#fbf9fd`/`#f6f2fa` (fila), `#b9b2c6`, `#d9cdea`, `#b9a6d0`, `#9be8b8`, `#ffb0b5`, `#6ed696` (topo escuro) | 60, 91, 208, 218, 303, 378 a 385, 420, 453 | Criar tokens neutros (`--neutral-soft`, `--line-hover`) e de estado sobre escuro |
| 7 | Cor de série de gráfico (8 hex) e estado "entregue" cinza em JS divergem da `.tag.entregue` do CSS (`#8c9a94` vs `#463f52`). | 2666, 3213 | Fonte única de cores de estado |
| 8 | Estilos em linha (`style="..."` ~22 usos) no HTML. | espalhados, ex.: 1115 | Mover para classes utilitárias |
| 9 | Alvos de toque no desktop abaixo de 44px: `.btn` 36, `.sm` 32, `.kcard .btn.sm` 32, campos 34, `.hbtn` 34, `.seg .btn` 32, `.np-b` 34, `.info` 18, `.helpbtn` 24. Em celular está coberto por `.btn`/`.hbtn`/campos, mas **não** por `.np-b`, `.info`, `.helpbtn`, `.kcard .btn.sm` (a regra `.kcard .btn.sm` tem mais especificidade) nem `.seg .btn`. | 282 a 286, 304, 451 a 453, 474, 191, 195, 227 | Estender a regra mobile ou aumentar a área clicável |
| 10 | Foco: `:focus-visible` em ouro sobre fundo claro tem contraste baixo (~1.7:1); o halo é só 25% de marca. Campos usam `:focus{outline:none}` (ok, há borda), mas botões do topo sobre fundo escuro dependem do ouro. | 396 | Anel duplo (claro + escuro) ou contorno na cor da marca em fundo claro |
| 11 | Placeholder `#8a8296` abaixo de 4.5:1 sobre branco (~3.5:1). `.muted` em `.72rem`/`.75rem` no limite. | 55, 405 | Escurecer para ~`#6f6780` e subir o corpo mínimo |
| 12 | Sem estados padronizados de erro de campo e de carregando (listas e botões). `.btn[disabled]` só reduz opacidade. | 50, 354 | Ver proposta na seção 4 |
| 13 | Tipografia: `Inter` é declarada mas não carregada (vira fonte do sistema); Poppins carrega só 500/600/700 e há uso de pesos 750 e 650 que não existem (sintetizados). Fonte externa (Google Fonts) é dependência de rede e de privacidade. | 10, 22, 257, 294 | Carregar Inter ou remover; usar pesos reais; hospedar localmente |
| 14 | Escala de espaçamento e de tamanhos de fonte sem tokens (muitos valores únicos: .66, .68, .72, .75, .78, .8, .82, .84, .85, .875 rem). | todo o bloco | Definir `--fs-1..5` e `--sp-1..6` |
| 15 | `prefers-reduced-motion` zera `transition`, mas não a animação `gira` (nem as de `transition` em `.aj summary::before`, que usam seletor mais específico). | 247, 354 | Incluir `animation:none!important` |
| 16 | Dois padrões de cartão com quase o mesmo CSS: `form.card`, `div.card`, `.np-card`, `.np-sum`, `.rel-card`, `.pulso`, `.fila`. | 160 a 175, 412, 464, 485 | Extrair `.surface-card` base |
| 17 | Tela de impressão e documento usam cores e fonte fixas por necessidade, mas `.rel-print` reaproveita classes de tela. | 179 a 188, 355 a 362 | Isolar tokens de impressão (`--print-*`) |
| 18 | Temas: apenas claro (`color-scheme:light`); o pacote de marca só admite uma paleta. | 12 | Fora de escopo agora; registrar |

### Próximos passos recomendados
1. Consolidar tokens e remover duplicatas (itens 1 a 4), sem mudar o visual.
2. Substituir cores da marca fixas por derivados (item 5) para o pacote funcionar de verdade em outro cliente.
3. Padronizar alvos de toque, foco e estados de erro/carregando (itens 9, 10, 12).
