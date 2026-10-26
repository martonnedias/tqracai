#!/usr/bin/env python3
"""Gera a página inicial (index.html), a página de pedido (pedido.html) e o tema.css a partir de um tema + os dados da loja.

Uso:  python3 temas/gerar_site.py                  (usa loja.json da raiz; o tema vem de "tema" nele)
      python3 temas/gerar_site.py --tema pizzaria  (força outro tema)
      python3 temas/gerar_site.py --saida /tmp/x   (escreve em outra pasta, sem tocar no site)

Um tema é a pasta temas/<id>/ com tema.json e blocos/<secao>.html. Seção que o tema não traz vem de temas/_comum/blocos/.
Nos blocos e no esqueleto (temas/base/index.tpl.html), {{loja.x}} e {{tema.x}} viram os valores dos dois JSON.
"""
import argparse, colorsys, json, os, re, sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VAR = re.compile(r"\{\{([a-z0-9_]+(?:\.[a-z0-9_]+)?)\}\}")


def ler(caminho):
    with open(caminho, encoding="utf-8") as f:
        return f.read()


def carregar_json(caminho):
    return json.loads(ler(caminho))


def resolve(texto, ctx, onde):
    """Troca {{loja.x}} / {{tema.x}}; valores podem conter outras variáveis (até 3 níveis)."""
    for _ in range(3):
        def troca(m):
            chave = m.group(1)
            if "." not in chave:
                return m.group(0)
            grupo, nome = chave.split(".")
            if grupo not in ctx or nome not in ctx[grupo]:
                sys.exit(f"ERRO: variável {{{{{chave}}}}} sem valor ({onde})")
            return str(ctx[grupo][nome])
        novo = VAR.sub(troca, texto)
        if novo == texto:
            break
        texto = novo
    return texto


def hex_ok(c):
    return bool(re.fullmatch(r"#[0-9a-fA-F]{6}", c or ""))


def rgb(c):
    return [int(c[1:3], 16), int(c[3:5], 16), int(c[5:7], 16)]


def mix(a, b, t):
    x, y = rgb(a), rgb(b)
    return "#" + "".join("%02x" % max(0, min(255, round(x[i] + (y[i] - x[i]) * t))) for i in range(3))


def roxos_padrao():
    """Lê do site.css os roxos decorativos (--puN) com os valores padrão."""
    css = ler(os.path.join(RAIZ, "site.css"))
    raiz = css[:css.index("}\n") + 2]
    return {n: v.strip() for n, v in re.findall(r"(--(?:pu|go)\d+):([^;]+);", raiz)}


def tinge(a, matiz):
    """Troca só o matiz (mesma conta do marca-site.js): o roxo decorativo acompanha a cor de destaque."""
    h, l, s = colorsys.rgb_to_hls(a[0] / 255, a[1] / 255, a[2] / 255)
    r, g, b = colorsys.hls_to_rgb(matiz, l, s)
    return [round(r * 255), round(g * 255), round(b * 255)]


def css_cores(c):
    """Mesmas contas do marca-site.js, para o tema valer já na primeira pintura e igual ao painel."""
    if not c:
        return "/* tema sem cores próprias: vale o visual padrão do site.css */\n"
    v = {}
    d, d2, f, f2 = c.get("destaque"), c.get("destaque2"), c.get("fundo"), c.get("fundo2")
    for k, x in (("destaque", d), ("destaque2", d2), ("fundo", f), ("fundo2", f2)):
        if x and not hex_ok(x):
            sys.exit(f"ERRO: cor inválida em tema.cores.{k}: {x}")
    if d:
        d2 = d2 or mix(d, "#ffffff", .55)
        v.update({"--gold": d, "--gold2": d2, "--gold3": mix(d, "#000000", .22), "--gold4": mix(d, d2, .55),
                  "--gold5": mix(d, d2, .62), "--gold-rgb": ",".join(map(str, rgb(d)))})
        matiz = colorsys.rgb_to_hls(*[x / 255 for x in rgb(d)])[0]
        for nome, base in roxos_padrao().items():
            a = rgb(base) if base.startswith("#") else [int(x) for x in base.split(",")]
            t = tinge(a, matiz)
            v[nome] = ("#" + "".join("%02x" % x for x in t)) if base.startswith("#") else ",".join(map(str, t))
    if f:
        f2 = f2 or mix(f, "#ffffff", .04)
        v.update({"--bg": f, "--bg2": f2, "--bg3": mix(f2, "#ffffff", .04), "--bg4": mix(f, "#ffffff", .12),
                  "--card": mix(f2, "#ffffff", .05), "--bg-rgb": ",".join(map(str, rgb(f)))})
    return ":root{" + ";".join(f"{k}:{x}" for k, x in v.items()) + "}\n"


def schema(loja, tema):
    d = {"@context": "https://schema.org", "@type": tema.get("tipo_schema", "FoodEstablishment"), "name": loja["nome"],
         "servesCuisine": tema["cozinha"], "telephone": loja["telefone_e164"], "priceRange": tema["faixa_preco"],
         "address": {"@type": "PostalAddress", "addressLocality": loja["cidade"], "addressRegion": loja["uf"], "addressCountry": "BR"},
         "areaServed": loja["cidade"], "openingHours": loja["horario_schema"], "paymentAccepted": loja["pagamentos"],
         "taxID": loja["cnpj"], "sameAs": [loja["instagram_url"]], "image": loja["url"] + "img/og-image.jpg"}
    return json.dumps(d, ensure_ascii=False, separators=(",", ":"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--loja", default=os.path.join(RAIZ, "loja.json"))
    ap.add_argument("--tema")
    ap.add_argument("--saida", default=RAIZ)
    a = ap.parse_args()
    loja = carregar_json(a.loja)
    loja.setdefault("prefixo_pedido", "PED")
    loja.setdefault("blog_nome", loja["nome"])
    tid = a.tema or loja["tema"]
    pasta = os.path.join(RAIZ, "temas", tid)
    if not os.path.isdir(pasta):
        sys.exit(f"ERRO: tema '{tid}' não existe em temas/")
    tema = carregar_json(os.path.join(pasta, "tema.json"))
    ctx = {"loja": loja, "tema": tema}

    paginas = tema.get("paginas", {})

    def monta(secoes, pag, arquivo):
        partes = []
        for s in secoes:
            for base in (pasta, os.path.join(RAIZ, "temas", "_comum")):
                cam = os.path.join(base, "blocos", s + ".html")
                if os.path.exists(cam):
                    partes.append(resolve(ler(cam), {**ctx, "pag": pag}, f"bloco {s}").rstrip("\n"))
                    break
            else:
                sys.exit(f"ERRO: seção '{s}' não existe no tema nem em _comum")
        if pag.get("classe_main") == "pagina":
            # página extra: o primeiro título da página vira o h1 (uma página precisa de um h1)
            corpo = "\n".join(partes)
            corpo = re.sub(r"<h2(\b[^>]*)>(.*?)</h2>", r'<h1\1>\2</h1>', corpo, count=1, flags=re.S)
            partes = [corpo]
        modelo = ler(os.path.join(RAIZ, "temas", "base", "index.tpl.html"))
        html = modelo.replace("{{secoes}}", "\n".join(partes)).replace("{{schema}}", schema(loja, tema))
        html = resolve(html, {**ctx, "pag": pag}, f"esqueleto de {arquivo}")
        sobra = re.findall(r"\{\{[^}]*\}\}", html)
        if sobra:
            sys.exit(f"ERRO: variáveis sem resolver em {arquivo}: " + ", ".join(sorted(set(sobra))))
        os.makedirs(a.saida, exist_ok=True)
        with open(os.path.join(a.saida, arquivo), "w", encoding="utf-8", newline="\n") as f:
            f.write(html)

    # Páginas extras do tema (ex.: pontos.html, revenda.html). O que o tema não move para fora continua na página inicial.
    redir = {"#" + k: v["arquivo"] for k, v in paginas.items()}
    for k in paginas:
        for sec in paginas[k]["secoes"]:
            if sec != "final":
                redir["#" + sec] = paginas[k]["arquivo"]
    script_hash = ("<script>(function(){var m=" + json.dumps(redir) + ",d=m[location.hash];if(d)location.replace(d);})();</script>") if redir else ""
    comum = {"inicio": "#topo", "link_pontos": paginas["pontos"]["arquivo"] if "pontos" in paginas else "#pontos",
             "rodape_links": tema.get("rodape_links", ""), "classe_main": "", "local": "inicio",
             "titulo": tema["titulo"], "descricao": tema["descricao"], "og_titulo": tema["og_titulo"],
             "og_descricao": tema["og_descricao"], "url": loja["url"], "script_hash": script_hash}
    monta(tema["secoes"], comum, "index.html")
    for k, pg in paginas.items():
        pag = {**comum, "inicio": "index.html", "classe_main": "pagina", "local": k, "script_hash": "",
               "titulo": pg["titulo"], "descricao": pg["descricao"], "og_titulo": pg["titulo"],
               "og_descricao": pg["descricao"], "url": loja["url"] + pg["arquivo"]}
        monta(pg["secoes"], pag, pg["arquivo"])
    ped = resolve(ler(os.path.join(RAIZ, "temas", "base", "pedido.tpl.html")), ctx, "pedido")
    sobra = re.findall(r"\{\{[^}]*\}\}", ped)
    if sobra:
        sys.exit("ERRO: variáveis sem resolver em pedido.html: " + ", ".join(sorted(set(sobra))))
    with open(os.path.join(a.saida, "pedido.html"), "w", encoding="utf-8", newline="\n") as f:
        f.write(ped)
    with open(os.path.join(a.saida, "tema.css"), "w", encoding="utf-8", newline="\n") as f:
        f.write(css_cores(tema.get("cores")))
    print(f"Site gerado: tema '{tid}' ({len(tema['secoes'])} seções, {len(paginas)} páginas extras) -> {a.saida}")


if __name__ == "__main__":
    main()
