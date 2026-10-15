/* Aviso de pedidos recentes ("prova social") do site #TQR Açaí.
   Ligado e configurado em Central TQR → Prova social. O site só consulta a função pública obter_prova_social,
   que devolve dados já saneados: primeiro nome (ou inicial), bairro e quantidade; nunca telefone nem endereço.
   Itens de exemplo aparecem SEMPRE com a marca "Exemplo" (não é possível esconder). Uso: <script src="prova-social.js" data-local="inicio" defer></script>
   data-local: inicio | blog | politicas. Para desativar numa visita: ?ps=off */
(function () {
  'use strict';
  var S = document.currentScript || document.querySelector('script[data-local][src*="prova-social"]');
  var LOCAL = (S && S.getAttribute('data-local')) || 'inicio';
  var SB = { url: 'https://elaczoriyaejkixkubxn.supabase.co', key: 'sb_publishable_NscsoGdrovVNuBol72Rh3Q_ov8i8lGv' };
  if (/[?&]ps=off\b/.test(location.search)) return;
  try { if (sessionStorage.getItem('tqr_ps_off') === '1') return; } catch (e) {}

  var cfg = null, fila = [], vistos = {}, mostrados = 0, noAr = false, pausado = false, caixa = null, tmrCiclo = null, tmrFim = null, tmrPoll = null;

  function rpc(fn) {
    var ac = window.AbortController ? new AbortController() : null, t = ac && setTimeout(function () { ac.abort(); }, 7000);
    return fetch(SB.url + '/rest/v1/rpc/' + fn, { method: 'POST', headers: { apikey: SB.key, 'Content-Type': 'application/json' }, body: '{}', signal: ac ? ac.signal : undefined })
      .then(function (r) { clearTimeout(t); if (!r.ok) throw new Error('http' + r.status); return r.json(); }, function (e) { clearTimeout(t); throw e; });
  }
  function ehMobile() { return window.matchMedia ? window.matchMedia('(max-width:700px)').matches : window.innerWidth <= 700; }
  function elegivel(c) {
    if (!c || !c.itens || !c.itens.length) return false;
    if ((c.locais || []).indexOf(LOCAL) < 0) return false;
    return (c.dispositivos || []).indexOf(ehMobile() ? 'mobile' : 'desktop') >= 0;
  }

  function estilo() {
    if (document.getElementById('psEstilo')) return;
    var st = document.createElement('style'); st.id = 'psEstilo';
    st.textContent =
      '.ps{position:fixed;z-index:70;display:flex;gap:12px;align-items:center;max-width:min(360px,calc(100vw - 24px));padding:12px 36px 12px 12px;border-radius:16px;' +
      'background:#2b1040;color:#f6eefa;border:1px solid rgba(232,190,98,.45);box-shadow:0 18px 40px -16px rgba(0,0,0,.6);font:500 .875rem/1.35 Poppins,system-ui,sans-serif;' +
      'opacity:0;transform:translateY(10px);transition:opacity .35s ease,transform .35s ease;pointer-events:none}' +
      '.ps.ps-on{opacity:1;transform:none;pointer-events:auto}' +
      '.ps-il{bottom:18px;left:18px}.ps-ir{bottom:18px;right:96px}.ps-sc{top:14px;left:50%;margin-left:min(-180px,calc(-50vw + 12px));width:calc(100vw - 24px);max-width:360px;transform:translateY(-10px)}' +
      '.ps-sc.ps-on{transform:none}' +
      '@media(max-width:700px){.ps-il,.ps-ir{left:12px;right:auto;bottom:84px}}' +
      '.ps-ic{flex:none;width:38px;height:38px;border-radius:50%;display:grid;place-items:center;background:linear-gradient(135deg,#e8be62,#b8862e);color:#2a0838}' +
      '.ps-ic svg{width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round}' +
      '.ps-t{min-width:0}.ps-t b{display:block;font-weight:700;color:#fff}.ps-t span{display:block;color:#cdb9d8;font-size:.78rem;margin-top:1px}' +
      '.ps-ex{display:inline-block;margin-left:6px;padding:1px 8px;border-radius:999px;background:rgba(232,190,98,.18);color:#fbe2a0;font-size:.68rem;font-weight:700;letter-spacing:.04em;text-transform:uppercase;vertical-align:1px}' +
      '.ps-x{position:absolute;top:6px;right:6px;width:28px;height:28px;border:0;border-radius:50%;background:transparent;color:#cdb9d8;font-size:1.1rem;line-height:1;cursor:pointer}' +
      '.ps-x:hover,.ps-x:focus-visible{background:rgba(255,255,255,.12);color:#fff;outline:none}' +
      '@media(prefers-reduced-motion:reduce){.ps{transition:none;transform:none}}';
    document.head.appendChild(st);
  }

  function montaCaixa() {
    if (caixa) return caixa;
    estilo();
    caixa = document.createElement('div');
    caixa.className = 'ps ' + ({ inferior_direita: 'ps-ir', superior_centro: 'ps-sc' }[cfg.posicao] || 'ps-il');
    caixa.setAttribute('role', 'status'); caixa.setAttribute('aria-live', 'polite'); caixa.setAttribute('aria-atomic', 'true');
    caixa.innerHTML = '<span class="ps-ic" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M6 7h12l-1 12H7L6 7Z"/><path d="M9 7a3 3 0 0 1 6 0"/></svg></span><div class="ps-t"><b></b><span></span></div>' +
      '<button type="button" class="ps-x" aria-label="Fechar aviso de pedidos">&times;</button>';
    caixa.querySelector('.ps-x').addEventListener('click', function () { try { sessionStorage.setItem('tqr_ps_off', '1'); } catch (e) {} parar(); });
    caixa.addEventListener('mouseenter', function () { pausado = true; });
    caixa.addEventListener('mouseleave', function () { pausado = false; });
    caixa.addEventListener('focusin', function () { pausado = true; });
    caixa.addEventListener('focusout', function () { pausado = false; });
    document.body.appendChild(caixa);
    return caixa;
  }

  function quando(m) { return m < 1 ? 'agora mesmo' : m < 60 ? 'há ' + m + ' min' : 'há ' + Math.floor(m / 60) + ' h'; }
  function mostra(it) {
    var c = montaCaixa(), b = c.querySelector('b'), sp = c.querySelector('span:not(.ps-ic)');
    var n = it.quantidade ? it.quantidade + (it.quantidade === 1 ? ' garrafa' : ' garrafas') : null;
    b.textContent = it.nome + (n ? ' pediu ' + n : ' fez um pedido');
    var ex = c.querySelector('.ps-ex'); if (ex) ex.remove();
    if (it.tipo === 'exemplo') {
      var tag = document.createElement('i'); tag.className = 'ps-ex'; tag.textContent = 'Exemplo'; b.appendChild(tag);
      sp.textContent = (it.bairro ? it.bairro + ' · ' : '') + 'exemplo ilustrativo';
    } else {
      sp.textContent = (it.bairro ? it.bairro + ' · ' : '') + quando(it.minutos || 0);
    }
    c.classList.add('ps-on'); noAr = true;
  }
  function esconde() { if (caixa) caixa.classList.remove('ps-on'); noAr = false; }

  function ordena(itens) {
    var reais = itens.filter(function (i) { return i.tipo === 'real'; }), exs = itens.filter(function (i) { return i.tipo === 'exemplo'; }), out = [], k;
    if (exs.length > 1) { k = Math.floor(Math.random() * exs.length); exs = exs.slice(k).concat(exs.slice(0, k)); }
    while (reais.length || exs.length) { if (reais.length) out.push(reais.shift()); if (exs.length) out.push(exs.shift()); }
    return out;
  }
  function abastece(itens, naFrente) {
    var novos = itens.filter(function (i) { return !vistos[i.id] && !fila.some(function (f) { return f.id === i.id; }); });
    if (!novos.length) return;
    novos = ordena(novos);
    fila = naFrente ? novos.concat(fila) : fila.concat(novos);
  }

  function parar() { esconde(); clearTimeout(tmrCiclo); clearTimeout(tmrFim); clearInterval(tmrPoll); mostrados = cfg ? cfg.max_por_visita : 0; }

  function ciclo() {
    if (mostrados >= cfg.max_por_visita) { return; }
    var dlg = document.querySelector('dialog[open]');
    if (document.hidden || pausado || dlg || !fila.length) { tmrCiclo = setTimeout(ciclo, 3000); return; }
    var it = fila.shift(); vistos[it.id] = 1; mostrados++;
    mostra(it);
    tmrFim = setTimeout(function () { esconde(); tmrCiclo = setTimeout(ciclo, cfg.intervalo_s * 1000); }, cfg.duracao_s * 1000);
  }

  function inicia(c) {
    if (!elegivel(c)) return;
    cfg = c; abastece(c.itens, false);
    tmrCiclo = setTimeout(ciclo, Math.max(0, c.atraso_s || 0) * 1000);
    // quase em tempo real: confere de novo a cada 45 s e põe pedidos reais novos na frente da fila
    if (c.modo !== 'ficticio') {
      tmrPoll = setInterval(function () {
        if (document.hidden || mostrados >= cfg.max_por_visita) return;
        rpc('obter_prova_social').then(function (n) { if (n && n.itens) abastece(n.itens.filter(function (i) { return i.tipo === 'real'; }), true); }).catch(function () {});
      }, 45000);
    }
  }

  function start() { rpc('obter_prova_social').then(function (c) { if (c) inicia(c); }).catch(function () {}); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start); else start();
})();
