# Gera as páginas de políticas da TQR Açaí. Edite os DADOS abaixo e rode: python gerar_politicas.py
import os, html
D = os.path.dirname(os.path.abspath(__file__))

# ====== PREENCHA COM OS DADOS DO NEGÓCIO ======
DADOS = {
    "nome": "#TQR Açaí",
    "razao": "[PREENCHER: razão social ou nome completo do responsável]",
    "doc": "CNPJ 59.270.529/0001-78",
    "endereco": "[PREENCHER: endereço completo], Teresina – PI",
    "email": "[PREENCHER: e-mail de contato]",
    "whatsapp": "(86) 99588-4770",
    "whatsapp_link": "https://wa.me/5586995884770",
    "instagram": "@tqracai",
    "encarregado": "[PREENCHER: nome do responsável pelos dados pessoais]",
    "atualizado": "8 de outubro de 2026",
}
# ===============================================

def v(k):
    t = html.escape(DADOS[k])
    return f'<mark class="fill">{t}</mark>' if t.startswith("[PREENCHER") else t

WA = DADOS["whatsapp_link"]

PAGES = [
("privacidade", "Política de Privacidade", "Como a #TQR Açaí coleta, usa e protege os seus dados pessoais, de acordo com a LGPD.", lambda: f"""
<p class="lead">A sua privacidade importa para a gente. Esta política explica, em linguagem simples, quais dados pessoais tratamos quando você usa o site da {v('nome')} ou faz um pedido, por que tratamos e quais são os seus direitos, conforme a Lei Geral de Proteção de Dados (Lei nº 13.709/2018 – LGPD).</p>

<h2>1. Quem é o responsável pelos seus dados</h2>
<p>O controlador dos dados é {v('razao')}, inscrito(a) no {v('doc')}, com endereço em {v('endereco')}.</p>
<p>Encarregado pelo tratamento de dados pessoais: {v('encarregado')}. Contato: {v('email')} ou WhatsApp {v('whatsapp')}.</p>

<h2>2. Quais dados tratamos</h2>
<h3>2.1 Dados que você nos envia</h3>
<ul>
<li><strong>Pelo formulário “Monte seu pedido”:</strong> nome, endereço de entrega (rua, número, bairro, complemento e ponto de referência), quantidade de garrafas, forma de pagamento e observações.</li>
<li><strong>Endereços salvos:</strong> guardamos no nosso banco os endereços que você informa para facilitar os próximos pedidos. Para ver, usar ou apagar esses endereços, você confirma o número com um código enviado pelo WhatsApp. Você pode apagar os seus endereços a qualquer momento ou pedir a exclusão pelo WhatsApp.</li>
<li><strong>Programa de pontos:</strong> guardamos o histórico de pontos do seu número (ganhos por pedido pago, resgates, ajustes e brinde de aniversário) para calcular o seu saldo. Você consulta o saldo no site depois de confirmar o número por um código enviado pelo WhatsApp.</li>
<li><strong>Pelo WhatsApp:</strong> número de telefone, nome de perfil e o conteúdo das mensagens que você nos envia.</li>
</ul>
<p>O formulário do site <strong>não envia nem guarda os seus dados em servidores nossos</strong>. Ao tocar em “Enviar pedido pelo WhatsApp”, o texto do pedido é montado no seu próprio aparelho e aberto no WhatsApp. O pedido só chega até nós quando você envia a mensagem.</p>

<h3>2.2 Dados guardados no seu aparelho</h3>
<p>Se você marcar a opção “Lembrar meus dados neste aparelho”, o seu nome e endereço ficam salvos no armazenamento local do seu navegador, para agilizar o próximo pedido. Esses dados ficam somente no seu aparelho. Você pode apagá-los a qualquer momento desmarcando a opção ou limpando os dados do navegador.</p>
<h3>2.3 Aviso de pedidos recentes</h3>
<p>O site pode exibir um pequeno aviso com pedidos recentes de outros clientes. Nele aparecem apenas o primeiro nome (ou a inicial), o bairro e a quantidade, nunca telefone, endereço completo ou outros dados. Avisos marcados como “Exemplo” são ilustrativos e não representam pedidos reais.</p>

<h3>2.3 Dados de navegação</h3>
<p>Se você autorizar no aviso de cookies, usamos ferramentas de medição e publicidade (Google Analytics e Meta Pixel) que coletam dados como páginas visitadas, cliques nos botões de pedido, tipo de aparelho, navegador e localização aproximada. Veja a <a href="cookies.html">Política de Cookies</a>.</p>

<h2>3. Para que usamos os seus dados</h2>
<table>
<tr><th>Finalidade</th><th>Base legal (LGPD)</th></tr>
<tr><td>Receber, confirmar, preparar e entregar o seu pedido</td><td>Execução de contrato (art. 7º, V)</td></tr>
<tr><td>Atender dúvidas, trocas e reclamações</td><td>Execução de contrato e exercício regular de direitos (art. 7º, V e VI)</td></tr>
<tr><td>Emitir documentos fiscais e cumprir obrigações legais</td><td>Cumprimento de obrigação legal (art. 7º, II)</td></tr>
<tr><td>Medir visitas e o desempenho de anúncios</td><td>Consentimento (art. 7º, I), dado no aviso de cookies</td></tr>
<tr><td>Enviar novidades e promoções pelo WhatsApp</td><td>Consentimento (art. 7º, I). Você pode pedir para sair a qualquer momento</td></tr>
</table>
<p>Não vendemos os seus dados pessoais.</p>

<h2>4. Com quem compartilhamos</h2>
<ul>
<li><strong>Aplicativos e serviços de entrega</strong>, quando necessário para levar o pedido até você (nome, endereço e telefone).</li>
<li><strong>Meios de pagamento</strong> (bancos e operadoras de cartão), para processar o pagamento.</li>
<li><strong>WhatsApp (Meta)</strong>, plataforma por onde conversamos com você.</li>
<li><strong>Google e Meta</strong>, somente se você aceitar os cookies de medição e publicidade.</li>
<li><strong>Behold</strong>, serviço que exibe as publicações do nosso Instagram no site. As imagens são carregadas de servidores desse serviço e do Instagram.</li>
<li><strong>Cloudflare Turnstile</strong>, verificação que ajuda a impedir pedidos feitos por robôs. Ao preencher o formulário, o serviço pode processar dados técnicos do seu navegador, como o endereço IP.</li>
<li><strong>Autoridades públicas</strong>, quando exigido por lei ou ordem judicial.</li>
</ul>
<p>Alguns desses parceiros podem armazenar dados fora do Brasil. Nesses casos, a transferência segue as regras da LGPD.</p>

<h2>5. Por quanto tempo guardamos</h2>
<p>Guardamos os dados do pedido pelo tempo necessário para concluir a venda, atender eventuais reclamações e cumprir prazos legais e fiscais. Dados usados com base no consentimento são mantidos até você pedir a exclusão ou retirar o consentimento.</p>

<h2>6. Seus direitos</h2>
<p>Pela LGPD (art. 18), você pode, a qualquer momento:</p>
<ul>
<li>confirmar se tratamos os seus dados e ter acesso a eles;</li>
<li>corrigir dados incompletos, inexatos ou desatualizados;</li>
<li>pedir a anonimização, o bloqueio ou a eliminação de dados desnecessários;</li>
<li>pedir a portabilidade dos dados;</li>
<li>saber com quem compartilhamos os seus dados;</li>
<li>retirar o consentimento e pedir a eliminação dos dados tratados com base nele;</li>
<li>apresentar reclamação à Autoridade Nacional de Proteção de Dados (ANPD).</li>
</ul>
<p>Para exercer qualquer direito, fale com a gente pelo WhatsApp {v('whatsapp')} ou pelo e-mail {v('email')}. Respondemos o mais rápido possível, dentro dos prazos legais.</p>

<h2>7. Segurança</h2>
<p>Adotamos medidas razoáveis para proteger os seus dados, como acesso restrito às conversas de pedidos e uso de plataformas reconhecidas. Nenhum sistema é totalmente imune a falhas; se ocorrer um incidente relevante, comunicaremos os titulares e a ANPD conforme a lei.</p>

<h2>8. Crianças e adolescentes</h2>
<p>O site não é direcionado a menores de 18 anos para a realização de pedidos. Pedidos devem ser feitos por um adulto responsável.</p>

<h2>9. Alterações</h2>
<p>Podemos atualizar esta política. A data da última atualização fica no topo da página.</p>
"""),

("cookies", "Política de Cookies", "Quais cookies e tecnologias semelhantes o site da #TQR Açaí usa e como você controla as suas preferências.", lambda: f"""
<p class="lead">Cookies são pequenos arquivos que os sites guardam no seu navegador. Eles ajudam o site a funcionar e permitem medir visitas. Aqui explicamos quais usamos e como você decide.</p>

<h2>1. Tipos que usamos</h2>
<table>
<tr><th>Categoria</th><th>Para que serve</th><th>Precisa de autorização?</th></tr>
<tr><td><strong>Essenciais</strong></td><td>Guardar a sua escolha sobre cookies e, se você pedir, lembrar seus dados de entrega no próprio aparelho.</td><td>Não. São necessários para o site funcionar como você pediu.</td></tr>
<tr><td><strong>Medição</strong> (Google Analytics)</td><td>Contar visitas, ver quais páginas e botões são mais usados e melhorar o site.</td><td>Sim</td></tr>
<tr><td><strong>Publicidade</strong> (Meta Pixel)</td><td>Medir o resultado dos anúncios no Instagram e Facebook e mostrar anúncios mais relevantes.</td><td>Sim</td></tr>
</table>
<p>As ferramentas de medição e publicidade só são carregadas depois que você clica em “Aceitar todos” no aviso de cookies.</p>

<h2>2. Como mudar a sua escolha</h2>
<p>Use o link <strong>“Preferências de cookies”</strong> no rodapé da página inicial para abrir o aviso de novo e mudar a sua decisão. Você também pode apagar cookies e dados de sites nas configurações do seu navegador.</p>

<h2>3. Conteúdo de terceiros</h2>
<p>A seção do Instagram exibe imagens carregadas dos servidores do Behold e do Instagram. As fontes do site são carregadas do Google Fonts. Esses serviços podem registrar dados técnicos da sua visita, como o endereço IP, conforme as políticas de privacidade deles.</p>

<h2>4. Mais informações</h2>
<p>Veja também a nossa <a href="privacidade.html">Política de Privacidade</a>. Dúvidas: WhatsApp {v('whatsapp')} ou {v('email')}.</p>
"""),

("termos", "Termos de Uso e Condições de Venda", "Regras para pedidos, preços, pagamento, entrega e retirada do #TQR Açaí.", lambda: f"""
<p class="lead">Estes termos valem para quem usa o site e faz pedidos da {v('nome')}. Ao fazer um pedido, você concorda com as condições abaixo.</p>

<h2>1. Quem vende</h2>
<p>{v('razao')}, {v('doc')}, {v('endereco')}. Contato: WhatsApp {v('whatsapp')} · {v('email')} · Instagram {v('instagram')}.</p>

<h2>2. Produto</h2>
<ul>
<li>Açaí sabor Tradicional, garrafa de 300 ml, entregue <strong>gelado e pronto para consumo</strong>.</li>
<li>Ingredientes: açaí (200 g), leite (75 ml), leite em pó (20 g) e leite condensado (40 g).</li>
<li><strong>ALÉRGICOS: CONTÉM LEITE E DERIVADOS. CONTÉM LACTOSE.</strong></li>
<li>As fotos do site são ilustrativas. Algumas foram produzidas com auxílio de inteligência artificial para fins de divulgação. O produto entregue é a garrafa de 300 ml descrita acima.</li>
</ul>

<h2>3. Como funciona o pedido</h2>
<ol>
<li>Você monta o pedido pelo formulário do site ou chama a gente no WhatsApp.</li>
<li>Confirmamos pelo WhatsApp a disponibilidade, o valor total, a taxa de entrega (quando houver) e o prazo.</li>
<li><strong>O pedido só é considerado fechado depois da nossa confirmação e do pagamento.</strong></li>
</ol>
<p>Pedido mínimo: 1 garrafa. Atendimento todos os dias, das 8h às 2h.</p>

<h2>4. Preços e promoções</h2>
<table>
<tr><th>Opção</th><th>Preço</th></tr>
<tr><td>1 garrafa</td><td>R$ 16,99</td></tr>
<tr><td>Combo 3 garrafas</td><td>R$ 42,00</td></tr>
<tr><td>5 garrafas ou mais</td><td>R$ 14,00 cada, com entrega grátis</td></tr>
</table>
<p>Os preços podem mudar sem aviso prévio, mas o valor confirmado no WhatsApp no momento do pedido será respeitado. Promoções têm as condições e a validade informadas na divulgação e não são cumulativas, salvo aviso em contrário. Em caso de erro evidente de preço no site, informaremos você antes de concluir o pedido.</p>

<h2>5. Pagamento</h2>
<p>Aceitamos Pix e cartão. A forma de pagamento e os dados para Pix são confirmados no WhatsApp. Nunca pedimos senhas ou códigos de segurança do cartão por mensagem.</p>

<h2>6. Entrega e retirada</h2>
<ul>
<li>Entregamos em todos os bairros de Teresina – PI.</li>
<li>A taxa de entrega é a cobrada pelo aplicativo ou serviço de entrega e é informada antes da confirmação. Pedidos de 5 garrafas ou mais têm entrega grátis.</li>
<li>O prazo é combinado no WhatsApp e pode variar com a distância, o horário e o clima.</li>
<li>Confira o pedido no recebimento. Se algo estiver errado, avise na hora pelo WhatsApp.</li>
<li>Se ninguém estiver no endereço no horário combinado, entraremos em contato para reagendar. Uma nova taxa de entrega pode ser cobrada.</li>
<li>Retirada: o local e o horário são combinados pelo WhatsApp.</li>
</ul>

<h2>7. Conservação</h2>
<p>O produto é entregue gelado e pronto para consumo: agite bem e tome. Se for guardar, mantenha na geladeira e consuma em até 48 horas, ou guarde no freezer e retire um pouco antes de consumir. Não nos responsabilizamos por alterações causadas por conservação diferente da indicada após a entrega.</p>

<h2>8. Trocas e devoluções</h2>
<p>Veja a <a href="trocas-e-devolucoes.html">Política de Trocas, Devoluções e Reembolso</a>.</p>

<h2>9. Conteúdo do site</h2>
<p>A marca #TQR Açaí, o logotipo, os textos, as imagens e o layout do site pertencem à {v('nome')} e não podem ser copiados para uso comercial sem autorização. Os artigos do blog têm caráter informativo e não substituem orientação de nutricionista ou médico.</p>

<h2>10. Alterações e foro</h2>
<p>Estes termos podem ser atualizados, valendo a versão publicada na data do pedido. Aplicam-se as leis brasileiras, em especial o Código de Defesa do Consumidor. Fica eleito o foro do domicílio do consumidor para resolver eventuais conflitos.</p>
"""),

("trocas-e-devolucoes", "Trocas, Devoluções e Reembolso", "O que fazer se houver algum problema com o seu pedido de #TQR Açaí e como funciona o direito de arrependimento.", lambda: f"""
<p class="lead">Queremos que cada garrafa chegue do jeito certo. Se algo der errado, a gente resolve. Veja abaixo como funciona.</p>

<h2>1. Problema no produto ou no pedido</h2>
<p>Fale com a gente pelo WhatsApp {v('whatsapp')} se o pedido chegar:</p>
<ul>
<li>com quantidade ou produto diferente do combinado;</li>
<li>com garrafa violada, vazando, amassada ou com a tampa danificada;</li>
<li>quente ou fora do ponto na entrega;</li>
<li>com alteração de cheiro, cor ou sabor, ou dentro do prazo de consumo indicado e mesmo assim impróprio.</li>
</ul>
<p>Para agilizar, envie <strong>fotos do produto e do lacre</strong> e informe o nome usado no pedido. De preferência, avise <strong>no momento da entrega</strong> ou logo depois. Pelo Código de Defesa do Consumidor, o prazo para reclamar de problemas aparentes em produtos não duráveis é de 30 dias (art. 26, I).</p>
<p>Confirmado o problema, você escolhe entre:</p>
<ul>
<li>a troca por um produto novo, sem custo;</li>
<li>a devolução do valor pago; ou</li>
<li>um abatimento proporcional no preço.</li>
</ul>

<h2>2. Direito de arrependimento</h2>
<p>Compras feitas fora do estabelecimento, como pelo site ou WhatsApp, podem ser canceladas em até <strong>7 dias</strong> a partir do recebimento (art. 49 do CDC).</p>
<ul>
<li><strong>Antes da saída para entrega:</strong> cancele pelo WhatsApp e devolvemos 100% do valor.</li>
<li><strong>Depois da entrega:</strong> por se tratar de alimento perecível, pedimos que a garrafa esteja <strong>lacrada e mantida refrigerada</strong>, para que possa ser recolhida em segurança. Combine a coleta pelo WhatsApp. O valor pago, incluindo a entrega, é devolvido.</li>
</ul>

<h2>3. Quando não é possível trocar</h2>
<p>Por segurança alimentar, não aceitamos de volta produtos abertos, consumidos parcialmente ou conservados de forma diferente da indicada (na geladeira com consumo em até 48 horas, ou no freezer), exceto quando o problema for de fabricação ou de transporte.</p>

<h2>4. Como é feito o reembolso</h2>
<ul>
<li><strong>Pix:</strong> devolução por Pix para a mesma conta de origem, em até 7 dias úteis após a confirmação.</li>
<li><strong>Cartão:</strong> estorno solicitado à operadora em até 7 dias úteis. O crédito aparece na fatura conforme o prazo do banco emissor.</li>
</ul>

<h2>5. Atendimento</h2>
<p>WhatsApp {v('whatsapp')} · {v('email')} · todos os dias, das 8h às 2h.</p>
"""),
]

TITLES = {s: t for s, t, _, _ in PAGES}

def page(slug, title, desc, body):
    links = "".join(f'<a href="{s}.html"{" class=on" if s==slug else ""}>{t}</a>' for s, t in TITLES.items())
    return f"""<!doctype html>
<html lang="pt-BR"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)} | #TQR Açaí</title>
<meta name="description" content="{html.escape(desc)}">
<meta name="robots" content="index, follow">
<meta name="theme-color" content="#1a0624">
<link rel="icon" href="../img/rotulo.webp">
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="../blog/blog.css?v=3">
<style>
.pol-nav{{display:flex;flex-wrap:wrap;gap:8px;margin:18px 0 6px}}
.pol-nav a{{font-size:.82rem;text-decoration:none;color:var(--muted);border:1px solid var(--line);border-radius:999px;padding:6px 12px}}
.pol-nav a.on{{background:var(--gold-grad);color:#2a0838;border-color:transparent;font-weight:600}}
mark.fill{{background:#f3cf7f;color:#2a0838;padding:0 4px;border-radius:4px;font-weight:600}}
.content{{padding-bottom:70px}}
</style>
</head><body>
<header class="top"><div class="wrap">
  <a class="brand" href="../index.html"><img src="../img/rotulo.webp" alt="" width="42" height="42"><span>#TQR Açaí</span></a>
  <nav class="nav" id="menuNav" aria-label="Menu"><a href="../index.html#sabores">Cardápio</a><a href="../index.html#como">Como funciona</a><a href="../sobre.html">Sobre</a><a href="../blog/index.html">Blog</a><a class="nav-extra" href="../pontos.html">Meus pontos</a></nav>
  <a class="top-pts" href="../pontos.html" aria-label="Consultar meus pontos" title="Meus pontos"><svg class="i-star" viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M12 2.8l2.7 5.9 6.4.7-4.8 4.3 1.4 6.3L12 16.8 6.3 20l1.4-6.3L2.9 9.4l6.4-.7L12 2.8z"/></svg></a>
  <a class="btn btn-gold" href="../pedido.html">Fazer pedido</a>
  <button type="button" class="menu-btn" id="menuBtn" aria-expanded="false" aria-controls="menuNav" aria-label="Abrir menu"><span></span><span></span><span></span></button>
</div></header>
<main class="narrow">
  <div class="crumbs"><a href="../index.html">Início</a> › Políticas</div>
  <nav class="pol-nav" aria-label="Políticas">{links}</nav>
  <div class="a-head"><h1>{title}</h1><div class="meta">Última atualização: {DADOS['atualizado']}</div></div>
  <article class="content">{body}</article>
</main>
<footer><div class="wrap">
<div><strong style="color:#fff">{v('nome')}</strong> · {v('razao')} · {v('doc')}<br>{v('endereco')}</div>
<div>WhatsApp: <a href="{WA}" target="_blank" rel="noopener">{v('whatsapp')}</a> · {v('email')}<br>{" · ".join(f'<a href="{s}.html">{t}</a>' for s, t in TITLES.items())}</div>
</div></footer>
<script src="../marca-site.js?v=1" defer></script>
<script src="../blog/menu.js" defer></script>
<script src="../prova-social.js" data-local="politicas" defer></script>
</body></html>"""

for slug, title, desc, body in PAGES:
    open(os.path.join(D, slug + ".html"), "w", encoding="utf-8").write(page(slug, title, desc, body()))
print("Políticas geradas:", ", ".join(s + ".html" for s, *_ in PAGES))
faltando = [k for k, x in DADOS.items() if x.startswith("[PREENCHER")]
if faltando: print("ATENÇÃO: ainda falta preencher:", ", ".join(faltando))
