# Temas do site

Cada cliente tem o seu site (uma instalação por cliente). O **tema** decide os textos e a estrutura da página inicial e da página de
pedido; os **dados da loja** (nome, cidade, telefone, CNPJ, Instagram…) ficam em `loja.json`. O gerador junta os dois.

```
python3 temas/gerar_site.py                              # usa loja.json (o tema vem do campo "tema")
python3 temas/gerar_site.py --tema pizzaria              # força outro tema
python3 temas/gerar_site.py --loja temas/exemplo-loja.json --saida /tmp/prévia   # prévia sem tocar no site
```

Escreve `index.html`, `pedido.html`, as páginas extras do tema (se houver) e `tema.css` (cores do tema). Páginas geradas não devem ser editadas à mão: mude o tema ou o `loja.json` e rode de novo.

## Temas que existem
| Tema | Para quê | Cardápio |
|---|---|---|
| `acai` | A loja de açaí (#TQR). É o "tema de referência": os blocos são os textos atuais da loja. | `garrafa` |
| `hamburgueria` | Hambúrguer e lanches (ponto da carne, adicionais, "sem cebola"). | `carrinho` |
| `pizzaria` | Pizza e restaurante (sabor, borda, adicionais). | `carrinho` |

Os temas `hamburgueria` e `pizzaria` usam os blocos genéricos de `_comum/` e só trazem textos em `tema.json`. Sem fotos de produto: o topo usa um emoji
(`hero_emoji`) e os cartões de categoria também. Para usar fotos, troque o bloco `hero`/`ofertas` do tema por um próprio.

## Páginas extras (`paginas` no `tema.json`)
Um tema pode tirar seções da página inicial e colocá-las em páginas próprias, para a home ficar curta. Cada entrada de `paginas` tem
`arquivo` (ex.: `pontos.html`), `secoes` (blocos, na ordem), `titulo` e `descricao` (SEO). O gerador usa o mesmo esqueleto (menu, rodapé, botão de pedir).
`rodape_links` (HTML) acrescenta links no rodapé. Links antigos como `index.html#pontos` continuam valendo: a home redireciona a âncora para a página nova.
O tema `acai` usa: home com `hero`, `cardapio`, `como`, `porque`, `faq`, `final`; páginas `pontos.html`, `revenda.html` e `sobre.html` (história, ingredientes e tabela nutricional, fotos reais, Instagram).
Os temas `hamburgueria` e `pizzaria` não declaram `paginas` e seguem com tudo na página inicial.

## Como criar um tema novo
1. `temas/<id>/tema.json`: copie o de `hamburgueria` e troque os textos. Campos principais: `secoes` (ordem), `cores` (`destaque`, `fundo`; o roxo decorativo acompanha o tom do destaque),
   `modo_cardapio` (`garrafa` ou `carrinho`), `unidade`/`unidades`, `brinde`, `pontos_prox`, `pontos_resgate`, SEO (`titulo`, `descricao`, `og_*`, `cozinha`, `faixa_preco`) e os textos de cada bloco.
2. Se precisar de uma seção diferente, crie `temas/<id>/blocos/<secao>.html` (vale no lugar do bloco de `_comum`). Dentro de qualquer bloco, `{{loja.x}}` e `{{tema.x}}` viram os valores; variável sem valor **quebra a geração** (de propósito).
3. Rode `python3 temas/gerar_site.py --tema <id> --loja temas/exemplo-loja.json --saida /tmp/prévia` e olhe o resultado.

## Para um cliente novo (resumo; o instalador automático é a Fase 3)
1. Copie o projeto, preencha `loja.json` (o exemplo está em `temas/exemplo-loja.json`) e escolha o `tema`.
2. `python3 temas/gerar_site.py`, depois `python3 blog/gerar_blog.py` e `python3 politicas/gerar_politicas.py`.
3. No banco do cliente: aplicar as migrações, `modo_cardapio` igual ao do tema e, em Personalização > Site, o nome, logo e cores.
4. O prefixo do código do pedido (`TQR-0007`) é definido no banco; o `prefixo_pedido` do `loja.json` só controla os exemplos mostrados no site.

## Cuidados
- O teste `test44` (suíte de testes) exige que o tema `acai` gere **exatamente** o `index.html`, `pedido.html` e `tema.css` publicados.
- Textos que citam fatos (números de clientes, prêmios, história) não entram nos temas genéricos: só frases que valem para qualquer loja do segmento.
- Blog e políticas ainda são do açaí (geradores próprios); os textos deles precisam ser adaptados por cliente.

## Etapas do pedido
`pedido.html` mostra o pedido em 3 abas (Pedido, Entrega e dados, Pagamento) com botões Continuar/Voltar; o resumo fica sempre visível. As abas são montadas por `site.js` sobre os painéis `#pnl1..3` do modelo; sem JavaScript os três painéis aparecem juntos. Ao enviar com algum campo vazio, o site abre a etapa do campo e foca nele.

## Sabores
O tema `acai` tem o bloco `sabores` (cartões com as fotos em `img/sabor-*.webp`, links `pedido.html?sabor=...`). No pedido, os sabores são produtos da mesma "Família" (campo em Produtos): viram cartões com foto e contador, a soma é a quantidade e Combo 3 / 5+ valem para qualquer mistura. Para outro cliente, cadastre um produto por sabor com a mesma família e o mesmo preço, e troque as imagens do bloco.
