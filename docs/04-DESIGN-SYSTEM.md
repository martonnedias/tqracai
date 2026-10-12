# 04 · Design System

Duas superfícies, uma identidade: **site público** (escuro, vitrine) e **painel Central TQR** (claro com casca berinjela). Detalhes finos: `DESIGN.md` (site), `admin/SISTEMA-DE-DESIGN.md` (painel, 177 linhas, com 18 dívidas), `admin/MARCA.md` (trocar marca).

## 1. Princípios
1. **Balcão primeiro:** o que se usa a cada minuto (fila, pulso, pedido manual) fica à vista.
2. **Marca com personalidade, não genérico:** berinjela + fio de ouro + letra manuscrita só em títulos de marca.
3. **Compacto e legível:** campos médios, tabelas densas, números em destaque.
4. **Cor com significado:** cor de estado nunca é só decoração; sempre acompanhada de texto/forma.
5. **Acessível por padrão:** contraste AA, foco visível, toque ≥ 44 px, alternativa em tabela para gráficos.
6. **Trocável:** tudo que é marca vem de variáveis/`marca.js`.

## 2. Tokens

### 2.1 Site público
| Token | Valor |
|---|---|
| bg / bg-2 / bg-3 / card | #16051f / #1f0a2c / #2a0f3b / #2b1040 |
| gold / gold-light / gold-deep | #e8be62 / #fbe2a0 / #b8862e |
| text / muted | #f6eefa / #cdb9d8 |
| wa / wa-deep (WhatsApp) | #25d366 / #1aa851 (texto sobre verde: #0f7a40 no blog) |
| red | #e0262b |
| Raios | card 20 px · campo 12 px · pílula 999 px |

### 2.2 Painel
| Token (CSS) | Valor | Uso |
|---|---|---|
| `--casca` / `--casca2` | #1a0a2b / derivado | cabeçalho, menu lateral |
| `--brand` | #59298a | ações primárias |
| `--ouro` | #e8be62 | fio de destaque, pico em gráficos (`--ouro-forte`) |
| `--fundo` | #f5f1f9 | fundo do conteúdo |
| `--serie-marca` | #7a4bb8 | série da marca em gráficos |
| `--f-destaque` | Kaushan Script | só marca/títulos de destaque |
| Texto/UI | Poppins | tudo mais |

### 2.3 Cores de estado do pedido
| Estado | Cor |
|---|---|
| pendente | #b25e00 |
| confirmado | #1b57a6 |
| pago | #14703f |
| saiu_entrega | #7a4bb8 |
| entregue | #6b7a73 |
| cancelado | #b0222a |

### 2.4 Paleta de dados (validada)
Claro: `--s1..--s8` = #2a78d6 · #eb6834 · #1baf7a · #eda100 · #e87ba4 · #008300 · #6250d6 · #e34948
Escuro: #3987e5 · #d95926 · #199e70 · #c98500 · #d55181 · #008300 · #9085e9 · #e66767
Regras: máx. 6–8 séries; rotular direto; nunca depender só de cor.

## 3. Tipografia
- Poppins 400/600/800; rótulos em caixa-alta com `letter-spacing` 0.18em (0.78 rem).
- Título de seção: `clamp(1.8rem, 4.6vw, 2.7rem)` no site; painel usa escala menor e compacta.
- Kaushan Script: marca, nunca corpo de texto.

## 4. Componentes (painel)
Cabeçalho com marca + nome do painel · menu lateral agrupado (Operação, Clientes e marketing, Gestão, Catálogo, Sistema) · **barra inferior** no celular (Início, Pedidos, Novo pedido, Clientes, Mais) · cartões (`.card`) · botões (`.btn`, `.go`, `.sm`) · menu "⋯" (`details.mais-acoes`) · campos (`campo()`) · diálogos (`confirmar`) · toasts · abas internas (Configurações) · Kanban com limite e "Mostrar mais" · KPI com variação vs. período · tabelas com alternativa (`.tbl-alt`) · estados vazios com ação.

## 5. Gráficos
Barras, linhas, pizza, barras horizontais e **Pulso do dia** (SVG sem biblioteca). Tooltip próprio (`tip`/`ativaTip`), pico destacado em ouro, redesenho ao girar a tela, formas de estado (`marcaEstado`) para daltonismo.

## 6. Padrões de tela
- **Início:** Pulso + fila ao vivo.
- **Lista + formulário lateral:** Financeiro, Custos.
- **Formulário em blocos numerados:** Novo pedido.
- **Relatório:** período, modelo (resumido/analítico), exportar PDF.

## 7. Acessibilidade
Skip link, `aria-label` em ícones, foco visível, contraste AA, `prefers-reduced-motion` (pendente para `gira`), gráficos com tabela equivalente, toque ≥ 44 px.

## 8. Pacote de marca para outro cliente (checklist)
1. Copiar `admin/marca.js` e ajustar `nome`, `empresa`, `logo`, `cores`, `fonteDestaque`.
2. Definir `vocabulario` (`unidade/unidades`: garrafa → pizza, marmita…).
3. Ajustar `textos` (montagem, filas vazias, login).
4. Trocar `PRODUCT.md`/`DESIGN.md` do site público.
5. Verificar contraste AA com as novas cores (`marca` sobre `casca`, `destaque` sobre `fundo`).
6. Revisar copy do site (ex.: "freezer", "100% natural") e imagens.

## 9. Dívidas
Self-host de fontes; estados `.fld.err`/`.btn.load`; `prefers-reduced-motion`; textos fixos de marca no site; achados do relatório de acessibilidade; demais itens em `admin/SISTEMA-DE-DESIGN.md`.
