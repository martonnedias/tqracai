# Gera as páginas do blog da TQR Açaí. Rode: python gerar_blog.py
import json, os, html
D = os.path.dirname(os.path.abspath(__file__))
WA = "https://wa.me/5586995884770?text="
from urllib.parse import quote
WA_MSG = WA + quote("Olá, TQR Açaí! 💜 Vim pelo blog e tenho uma dúvida.")
WA_ICON = '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M17.47 14.38c-.3-.15-1.75-.86-2.02-.96-.27-.1-.47-.15-.67.15-.2.3-.77.96-.94 1.16-.17.2-.35.22-.64.07-.3-.15-1.26-.46-2.39-1.47-.88-.79-1.48-1.76-1.65-2.06-.17-.3-.02-.46.13-.6.13-.13.3-.35.45-.52.15-.17.2-.3.3-.5.1-.2.05-.37-.02-.52-.08-.15-.67-1.62-.92-2.22-.24-.58-.49-.5-.67-.51h-.57c-.2 0-.52.07-.79.37-.27.3-1.04 1.02-1.04 2.48s1.07 2.88 1.21 3.07c.15.2 2.1 3.2 5.08 4.49.71.31 1.26.49 1.69.63.71.22 1.36.19 1.87.12.57-.09 1.75-.72 2-1.41.25-.69.25-1.29.17-1.41-.07-.12-.27-.2-.57-.35zM12.05 21.5a9.4 9.4 0 0 1-4.8-1.31l-.34-.2-3.57.94.95-3.48-.22-.36a9.43 9.43 0 0 1-1.45-5.03c0-5.2 4.24-9.44 9.45-9.44 2.52 0 4.89.99 6.67 2.77a9.37 9.37 0 0 1 2.76 6.68c0 5.2-4.24 9.43-9.44 9.43zm8.04-17.47A11.3 11.3 0 0 0 12.05.7C5.79.7.69 5.8.69 12.06c0 2 .52 3.96 1.52 5.68L.6 23.6l6-1.57a11.33 11.33 0 0 0 5.43 1.38c6.26 0 11.36-5.1 11.36-11.36 0-3.03-1.18-5.89-3.32-8.03z"/></svg>'

ARTICLES = [
{
"slug": "como-tomar-e-guardar-acai-na-garrafa",
"tag": "Guia rápido",
"title": "Como tomar e guardar o seu açaí na garrafa",
"desc": "O #TQR Açaí chega gelado e no ponto. Veja como aproveitar na hora e como guardar se for tomar depois.",
"img": "../img/foto-ea51.webp", "img_alt": "Garrafa de #TQR Açaí sobre o balcão",
"read": "3 min",
"body": """
<p class="lead">O #TQR Açaí chega até você gelado e no ponto de tomar. Não precisa esperar nada. Este guia mostra como aproveitar na hora e o que fazer se quiser guardar uma garrafa para depois.</p>

<h2>1. Recebeu? Agite e tome</h2>
<p>Com a tampa fechada, agite a garrafa por uns 10 segundos. Isso deixa a textura uniforme e bem cremosa. Depois é só abrir e aproveitar, direto da garrafa ou com canudo.</p>

<h2>2. Vai tomar mais tarde? Guarde na geladeira</h2>
<p>Se a garrafa for para o lanche da tarde ou para a noite, deixe na geladeira. Refrigerada, consuma em até 48 horas.</p>
<div class="box"><p><strong>Dica:</strong> comprou o combo de 3 ou o kit de 5? Deixe as garrafas dos próximos dias no freezer e uma na geladeira para tomar logo.</p></div>

<h2>3. Quer guardar por mais tempo? Use o freezer</h2>
<p>No freezer o açaí fica guardado até você querer. Na hora de tomar, tire a garrafa um pouco antes, agite e pronto.</p>

<h2>4. Levando para a rua</h2>
<p>A garrafa fechada de 300 ml cabe na bolsa e na mochila. Em dias quentes, uma bolsa térmica mantém o açaí gelado por mais tempo.</p>

<h2>Perguntas rápidas</h2>
<h3>Preciso esperar descongelar quando chega?</h3>
<p>Não. Ele chega gelado e no ponto de tomar.</p>
<h3>Posso deixar a garrafa fora da geladeira?</h3>
<p>Evite deixar muitas horas fora do frio. Em Teresina a temperatura passa fácil dos 30 graus, e o açaí perde o ponto e a segurança.</p>
<h3>Gosto mais firme, tipo raspadinha. Dá?</h3>
<p>Dá. Leve a garrafa da geladeira ao freezer por uns 30 a 40 minutos antes de tomar.</p>
""",
},
{
"slug": "acai-no-pos-treino",
"tag": "Energia",
"title": "Açaí no pós-treino: o que uma garrafa de 300 ml entrega",
"desc": "Calorias, carboidratos e proteínas do #TQR Açaí Tradicional, com dicas para encaixar a garrafa na rotina de treino.",
"img": "../img/hf-lifestyle.webp", "img_alt": "Mão segurando uma garrafa de #TQR Açaí ao ar livre depois do treino",
"read": "5 min",
"body": """
<p class="lead">Açaí e academia andam juntos há muito tempo no Brasil. Mas o que exatamente tem dentro de uma garrafa de #TQR Açaí? Abrimos a tabela nutricional para você decidir como e quando encaixar na sua rotina.</p>

<h2>O que tem em uma garrafa</h2>
<p>A receita do Tradicional leva <strong>200 g de açaí, 75 ml de leite, 20 g de leite em pó e 40 g de leite condensado</strong>. Por garrafa de 300 ml, isso dá:</p>
<table>
  <tr><th>Nutriente</th><th>Por garrafa</th><th>%VD*</th></tr>
  <tr><td>Valor energético</td><td>372 kcal</td><td>19%</td></tr>
  <tr><td>Carboidratos</td><td>59 g</td><td>20%</td></tr>
  <tr><td>Açúcares totais</td><td>52 g</td><td>–</td></tr>
  <tr><td>Proteínas</td><td>6,4 g</td><td>13%</td></tr>
  <tr><td>Gorduras totais</td><td>9,2 g</td><td>14%</td></tr>
  <tr><td>Fibras</td><td>2,7 g</td><td>11%</td></tr>
  <tr><td>Sódio</td><td>76 mg</td><td>4%</td></tr>
</table>
<p style="font-size:.85rem;color:var(--muted)">*Valores diários com base em uma dieta de 2.000 kcal.</p>

<h2>Por que ele combina com o pós-treino</h2>
<p>Depois de um treino puxado, o corpo pede energia. Os 59 g de carboidratos da garrafa ajudam a repor essa energia de um jeito prático, e as proteínas do leite somam 6,4 g. Por ser gelado e cremoso, também é uma boa pedida para quem treina no calor.</p>
<p>O açaí em si é conhecido pela cor roxa intensa, que vem das antocianinas, um tipo de antioxidante presente na fruta.</p>

<h2>Seja honesto com o seu objetivo</h2>
<p>O Tradicional é uma receita doce, com leite condensado, e isso aparece nos 52 g de açúcares. Para quem está ganhando massa ou precisa de energia rápida, ele cai bem. Para quem está controlando açúcar ou calorias, vale tratar a garrafa como um lanche completo, e não como um complemento.</p>
<div class="box"><p>Cada corpo e cada treino pedem uma estratégia diferente. Se você segue uma dieta com metas específicas, converse com um nutricionista sobre a melhor forma de encaixar o açaí.</p></div>

<h2>Como encaixar na rotina</h2>
<ul>
  <li><strong>Treino à tarde ou à noite:</strong> tire a garrafa do freezer pela manhã e leve gelada para a academia.</li>
  <li><strong>Treino de manhã cedo:</strong> deixe uma garrafa na geladeira desde a noite anterior e tome ao voltar para casa.</li>
  <li><strong>Semana cheia de treinos:</strong> o kit de 5 garrafas sai por R$ 14 cada e a entrega é grátis.</li>
</ul>
""",
},
{
"slug": "acai-para-o-calor-de-teresina",
"tag": "Teresina",
"title": "Calor de Teresina: 5 momentos para ter açaí gelado no freezer",
"desc": "Do B-R-O-Bró ao lanche da criançada, veja quando um açaí na garrafa salva o dia e como montar o seu estoque gastando menos.",
"img": "../img/hf-combo.webp", "img_alt": "Três garrafas de #TQR Açaí sobre mesa de madeira com frutos de açaí",
"read": "4 min",
"body": """
<p class="lead">Quem mora em Teresina sabe: tem época em que o calor não dá trégua. Ter açaí gelado no freezer resolve muita coisa. Separamos cinco momentos em que a garrafa de #TQR Açaí faz diferença.</p>

<h2>1. A tarde mais quente do B-R-O-Bró</h2>
<p>Entre setembro e dezembro, o termômetro sobe e a vontade de algo gelado aparece todo dia às três da tarde. Com uma garrafa gelada na geladeira, é só agitar e tomar.</p>

<h2>2. Saída da academia</h2>
<p>Treinar no calor cansa em dobro. Uma garrafa gelada na mochila térmica vira o lanche do caminho de volta para casa.</p>

<h2>3. Lanche da criançada</h2>
<p>Cada um com a sua garrafa fechada de 300 ml. Ninguém briga pelo último copo e não tem bagunça de pote e colher.</p>

<h2>4. Visita chegando de surpresa</h2>
<p>Com algumas garrafas guardadas, você tem uma sobremesa pronta para servir. É só agitar e entregar uma para cada um.</p>

<h2>5. Aquela fome da madrugada</h2>
<p>A gente atende até as 2h. E se a vontade bater mais tarde, a garrafa que está na sua geladeira resolve.</p>

<h2>Como montar o estoque gastando menos</h2>
<p>Quanto mais garrafas você leva, menos paga por cada uma:</p>
<table>
  <tr><th>Pedido</th><th>Preço por garrafa</th><th>Total</th></tr>
  <tr><td>1 garrafa</td><td>R$ 16,99</td><td>R$ 16,99</td></tr>
  <tr><td>Combo 3</td><td>R$ 14,00</td><td>R$ 42,00</td></tr>
  <tr><td>5 garrafas</td><td>R$ 14,00 + entrega grátis</td><td>R$ 70,00</td></tr>
</table>
<p>Com o kit de 5, você garante uma garrafa por dia útil e não paga a entrega. É o jeito mais econômico de manter o freezer abastecido.</p>
""",
},
]

def head(title, desc, canonical_rel, img, schema):
    return f"""<!doctype html>
<html lang="pt-BR"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
<meta name="description" content="{html.escape(desc)}">
<meta name="theme-color" content="#1a0624">
<meta property="og:type" content="article"><meta property="og:title" content="{html.escape(title)}">
<meta property="og:description" content="{html.escape(desc)}"><meta property="og:image" content="{img}">
<link rel="icon" href="../img/rotulo.webp">
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="blog.css">
<script type="application/ld+json">{json.dumps(schema, ensure_ascii=False)}</script>
</head><body>
<header class="top"><div class="wrap">
  <a class="brand" href="../index.html"><img src="../img/rotulo.webp" alt="" width="42" height="42"><span>#TQR Açaí</span></a>
  <nav class="nav"><a href="../index.html#ofertas">Ofertas</a><a class="nav-pts" href="../pontos.html"><svg class="i-star" viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M12 2.8l2.7 5.9 6.4.7-4.8 4.3 1.4 6.3L12 16.8 6.3 20l1.4-6.3L2.9 9.4l6.4-.7L12 2.8z"/></svg>Meus pontos</a><a href="../pedido.html">Fazer pedido</a><a href="index.html">Blog</a></nav>
  <a class="btn btn-gold" href="../pedido.html">Fazer pedido</a>
</div></header>
"""

FOOT = """<footer><div class="wrap">
<div><strong style="color:#fff">#TQR Açaí</strong> · Sabor que refresca e energiza<br>Teresina – PI · Todos os dias, das 8h às 2h</div>
<div>WhatsApp: <a href="{wa}" target="_blank" rel="noopener">(86) 99588-4770</a><br>Instagram: <a href="https://instagram.com/tqracai" target="_blank" rel="noopener">@tqracai</a></div>
</div><div class="wrap" style="margin-top:16px;font-size:.8rem;gap:8px 18px;justify-content:flex-start"><a href="../politicas/termos.html">Termos de Uso</a><a href="../politicas/privacidade.html">Privacidade</a><a href="../politicas/cookies.html">Cookies</a><a href="../politicas/trocas-e-devolucoes.html">Trocas e devoluções</a></div></footer>
<script src="../marca-site.js?v=1" defer></script>
<script src="../prova-social.js" data-local="blog" defer></script>
</body></html>""".format(wa=WA_MSG)

def card(a):
    return f"""<a class="card" href="{a['slug']}.html">
  <div class="thumb"><img src="{a['img']}" alt="{html.escape(a['img_alt'])}" loading="lazy"></div>
  <div class="body"><span class="tag">{a['tag']} · {a['read']}</span><h2>{a['title']}</h2><p>{a['desc']}</p><span class="more">Ler artigo →</span></div>
</a>"""

DATE = "2026-10-08"
for a in ARTICLES:
    schema = {"@context":"https://schema.org","@type":"BlogPosting","headline":a["title"],"description":a["desc"],
              "datePublished":DATE,"dateModified":DATE,"inLanguage":"pt-BR","image":a["img"],
              "author":{"@type":"Organization","name":"#TQR Açaí"},"publisher":{"@type":"Organization","name":"#TQR Açaí"}}
    rel = [x for x in ARTICLES if x is not a]
    page = head(a["title"] + " | Blog #TQR Açaí", a["desc"], a["slug"], a["img"], schema) + f"""
<main class="narrow">
  <div class="crumbs"><a href="../index.html">Início</a> › <a href="index.html">Blog</a> › {a['tag']}</div>
  <div class="a-head"><span class="eyebrow">{a['tag']}</span><h1>{a['title']}</h1>
  <div class="meta">Equipe #TQR Açaí · 8 de outubro de 2026 · {a['read']} de leitura</div></div>
  <div class="a-cover"><img src="{a['img']}" alt="{html.escape(a['img_alt'])}"></div>
  <article class="content">{a['body']}</article>
  <div class="cta">
    <img src="../img/rotulo.webp" alt="" width="110" height="110">
    <div><h3>Bateu a vontade? <span class="gold">Tem #TQR no seu bairro.</span></h3>
    <p>300 ml por R$ 16,99 · Combo 3 por R$ 42 · 5 ou mais a R$ 14 cada com entrega grátis. Delivery em toda Teresina, das 8h às 2h.</p>
    <div class="btns"><a class="btn btn-gold" href="../pedido.html">Montar meu pedido</a></div></div>
  </div>
</main>
<section class="related"><div class="wrap"><h2>Leia também</h2><div class="cards">{''.join(card(x) for x in rel)}</div></div></section>
""" + FOOT
    open(os.path.join(D, a["slug"] + ".html"), "w", encoding="utf-8").write(page)

schema = {"@context":"https://schema.org","@type":"Blog","name":"Blog #TQR Açaí","inLanguage":"pt-BR",
          "blogPost":[{"@type":"BlogPosting","headline":a["title"],"url":a["slug"]+".html","datePublished":DATE} for a in ARTICLES]}
idx = head("Blog #TQR Açaí | Dicas de açaí na garrafa em Teresina",
           "Dicas para tomar, guardar e aproveitar o açaí na garrafa #TQR Açaí, direto de Teresina.", "", "../img/og-image.jpg", schema) + f"""
<section class="b-hero"><div class="wrap"><span class="eyebrow">Blog #TQR</span>
<h1>Dicas para aproveitar <span class="script gold">cada garrafa</span></h1>
<p>Como conservar, quando tomar e como economizar no seu açaí de todo dia.</p></div></section>
<main class="wrap"><div class="cards">{''.join(card(a) for a in ARTICLES)}</div></main>
""" + FOOT
open(os.path.join(D, "index.html"), "w", encoding="utf-8").write(idx)
print("Blog gerado:", len(ARTICLES), "artigos")
