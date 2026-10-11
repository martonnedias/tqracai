---
name: TQR Açaí
description: Açaí tradicional na garrafa de 300 ml, pronto para tomar, com pedido pelo WhatsApp em Teresina.
colors:
  bg: "#16051f"
  bg-2: "#1f0a2c"
  bg-3: "#2a0f3b"
  card: "#2b1040"
  gold: "#e8be62"
  gold-light: "#fbe2a0"
  gold-deep: "#b8862e"
  text: "#f6eefa"
  muted: "#cdb9d8"
  wa: "#25d366"
  wa-deep: "#1aa851"
  red: "#e0262b"
typography:
  display:
    fontFamily: "'Kaushan Script', cursive"
    fontWeight: 400
    lineHeight: 1.1
  headline:
    fontFamily: "Poppins, system-ui, sans-serif"
    fontSize: "clamp(1.8rem, 4.6vw, 2.7rem)"
    fontWeight: 800
    lineHeight: 1.15
  body:
    fontFamily: "Poppins, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.6
  label:
    fontFamily: "Poppins, system-ui, sans-serif"
    fontSize: "0.78rem"
    fontWeight: 600
    letterSpacing: "0.18em"
rounded:
  card: "20px"
  pill: "999px"
  field: "12px"
spacing:
  section: "84px"
  gutter: "20px"
components:
  button-whatsapp:
    backgroundColor: "{colors.wa}"
    textColor: "{colors.text}"
    rounded: "{rounded.pill}"
    padding: "17px 30px"
  button-whatsapp-hover:
    backgroundColor: "{colors.wa-deep}"
  button-gold:
    backgroundColor: "{colors.gold}"
    textColor: "#2a0838"
    rounded: "{rounded.pill}"
    padding: "17px 30px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.gold-light}"
    rounded: "{rounded.pill}"
    padding: "17px 30px"
  card:
    backgroundColor: "{colors.card}"
    rounded: "{rounded.card}"
    padding: "28px 22px"
---

<!-- Gerado por /impeccable document (modo scan). Tokens extraídos de index.html. -->

# Design System: TQR Açaí

## Overview

**Creative North Star: "The Midnight Garrafa"**

A página vive numa noite roxa profunda, como um fim de tarde em Teresina depois do calor, e a garrafa é a única coisa iluminada. O dourado não decora: ele aponta para preço, oferta e ação. O roxo é o fundo que faz o açaí parecer mais cremoso por contraste.

A densidade é de landing de venda: seções longas, uma ideia por bloco, e o pedido aparece cedo. O tom é direto e caloroso, sem ornamento que atrase a compra.

**Key Characteristics:**
- Fundo escuro roxo em camadas, com um único acento dourado.
- Tipografia dupla: script para a voz da marca, sans geométrica para leitura e preço.
- Superfícies planas em repouso; profundidade aparece como resposta a estado.
- Verde do WhatsApp reservado para a ação de envio.

## Colors

Paleta de noite roxa com um acento dourado e um verde de ação. O dourado é raro por design.

### Primary
- **Gold Ember** (#e8be62): acento principal, preço, rótulos de seção e bordas de destaque. Aparece em no máximo uma área de destaque por tela.
- **Gold Gradient** (linear de #fbe2a0 a #b8862e): preenchimento de botão principal, preço no selo e números de total. Usado como superfície, nunca como texto corrido.

### Secondary
- **Gold Light** (#fbe2a0): texto de destaque sobre fundo escuro, como nome de oferta e valores secundários.

### Tertiary
- **WhatsApp Green** (#25d366, hover #1aa851): exclusivo para o envio do pedido e o botão flutuante. Não usar para decoração.
- **Alert Red** (#e0262b): selo "mais pedido" do combo e nada mais.

### Neutral
- **Midnight Ground** (#16051f): fundo do corpo da página.
- **Violet Depth** (#1f0a2c, #2a0f3b): faixas de seção alternadas.
- **Card Violet** (#2b1040): superfície de cards e formulário.
- **Soft Lilac** (#cdb9d8): texto de apoio, a cor de leitura secundária.
- **Ink Lilac** (#f6eefa): texto principal.

### Named Rules
**The One Gold Rule.** O dourado ocupa no máximo uma área de destaque por tela. Sua raridade é o que faz o preço ser lido primeiro.

**The Green Is An Action Rule.** O verde do WhatsApp só aparece onde o visitante vai enviar uma mensagem.

## Typography

**Display Font:** Kaushan Script (com cursive). Usada só em trechos curtos da marca, como "pronto na garrafa.".
**Body Font:** Poppins (com system-ui, sans-serif).
**Label Font:** Poppins em caixa alta, com espaçamento largo.

**Character:** Script calorosa de ponto de venda contra uma sans geométrica de leitura limpa. O contraste entre as duas é a voz da marca.

### Hierarchy
- **Display** (Kaushan Script, 400, cerca de 1,08em do H1): só dentro do H1 e do título da história.
- **Headline** (Poppins 800, clamp de 1,8rem a 2,7rem, line-height 1,15): títulos de seção.
- **Title** (Poppins 700, 1,05rem a 1,6rem): nomes de cards, planos e passos.
- **Body** (Poppins 400, 0,9rem a 1rem, line-height 1,6): texto corrido, com máximo de cerca de 65ch.
- **Label** (Poppins 600, 0,78rem, letter-spacing 0,18em, caixa alta): rótulos de seção acima dos títulos.

### Named Rules
**The Script Is A Whisper Rule.** A fonte script aparece em uma frase por seção, nunca em parágrafos.

## Layout

Coluna única centralizada, com largura máxima de 1120px e 1240px em telas grandes. Margem lateral de 20px, reduzida para 16px no celular. Seções com 84px de respiro vertical, reduzidas para 64px no celular.

Grids de 2 e 3 colunas viram uma coluna abaixo de 760px. O formulário de pedido fica em duas colunas acima de 900px e empilhado abaixo. A barra fixa de pedido no celular ocupa a base da tela.

## Elevation & Depth

Sistema plano por padrão. Superfícies em repouso não têm sombra; a profundidade vem da troca de tom entre faixas roxas. Sombras aparecem como resposta a estado: hover de botão, foco e o selo de preço. O brilho dourado do hero é decorativo e fica restrito a essa área.

### Shadow Vocabulary
- **Button Lift** (`box-shadow: 0 10px 30px -8px rgba(37,211,102,.6)`): botão WhatsApp em repouso.
- **Gold Glow** (`box-shadow: 0 12px 28px -10px rgba(232,190,98,.6)`): selo de preço e botão dourado.
- **Card Hover** (`transform: translateY(-4px)`, sem sombra extra): cards de benefício ao passar o mouse.

### Named Rules
**The Flat-By-Default Rule.** Superfícies são planas em repouso. Sombra só responde a estado.

## Shapes

Formas arredondadas e macias: pílulas para botões e selos, cantos de 20px para cards e painéis, 12px a 16px para campos. Círculos para ícones e o botão flutuante. Não há cantos retos nem bordas duras.

## Components

### Buttons
- **Shape:** pílula (999px).
- **WhatsApp (primário de envio):** fundo verde #25d366, texto claro, padding 17px 30px, sombra verde suave. Hover escurece para #1aa851 e sobe 2px.
- **Gold (primário de navegação):** gradiente dourado, texto escuro #2a0838. Hover sobe 2px.
- **Ghost (secundário):** borda dourada de 1,5px, texto dourado claro, fundo transparente. Hover com leve preenchimento dourado.
- **Focus:** precisa de anel visível de foco. Hoje o foco vem do navegador; revisar.

### Cards / Containers
- **Corner Style:** 20px.
- **Background:** #2b1040 sobre fundo roxo, com borda de 1px em dourado a 18% de opacidade.
- **Shadow Strategy:** sem sombra em repouso; hover sobe 4px e acende a borda.
- **Internal Padding:** 22px a 28px.

### Inputs / Fields
- **Style:** fundo #1a0724, borda de 1px a 15% de branco, raio 12px, texto claro.
- **Focus:** borda dourada e anel de 3px a 18% de dourado.
- **Error:** borda #ff6b6b com mensagem em #ff9b9b.

### Navigation
- **Style:** barra fixa com fundo roxo a 82% e desfoque. Texto em lilás, hover dourado claro.
- **Mobile:** menu some abaixo de 900px; o botão de pedido permanece no topo.

### Quick Order Box
Caixa de pedido no hero, com borda dourada de 1,5px, quantidade em campo central e total em gradiente dourado. Assinatura do site.

## Do's and Don'ts

### Do:
- **Do** usar o dourado para preço e oferta, e o verde só para enviar pedido.
- **Do** manter o script em uma frase curta por seção.
- **Do** deixar superfícies planas em repouso e usar sombra só como estado.
- **Do** usar a terminologia "pronto na garrafa" e "chega gelado e no ponto".

### Don't:
- **Don't** usar dourado em parágrafos corridos ou em mais de uma área de destaque por tela.
- **Don't** usar verde do WhatsApp como decoração ou fundo de seção.
- **Don't** introduzir sombras pesadas em repouso nem cards com contorno duro.
- **Don't** usar "descongelar" ou "congelado" em nenhum texto para o consumidor.
