function br(t){return window.TQR_br?window.TQR_br(t):t;}
var UN1=document.documentElement.dataset.unid||'garrafa',UNS=document.documentElement.dataset.unids||'garrafas',PROX=document.documentElement.dataset.prox||'a próxima garrafa grátis',RESG=document.documentElement.dataset.resg||'minha garrafa grátis',PFX=document.documentElement.dataset.prefixo||'TQR';
window.TQR_DEV=(function(){
  // aparelho reconhecido: chave secreta guardada neste aparelho (liberada no primeiro pedido), abre pontos e endereços salvos
  var K='tqr_dev';
  function n(w){w=String(w||'').replace(/\D/g,'');return w.length>11?w.replace(/^55/,''):w;}
  return {
    get:function(w){try{var o=JSON.parse(localStorage.getItem(K)||'null');if(o&&o.t&&o.w&&o.e>Date.now()&&(w===undefined||n(o.w)===n(w)))return o;}catch(e){}return null;},
    set:function(w,t,dias){try{localStorage.setItem(K,JSON.stringify({w:n(w),t:t,e:Date.now()+(dias||90)*864e5}));}catch(e){}},
    clear:function(){try{localStorage.removeItem(K);}catch(e){}}
  };
})();
(function(){
  var MSG={
    padrao:'Olá, TQR Açaí! 💜 Vim pelo site e quero fazer meu pedido.\n\n🥤 Quantidade: __ garrafa(s) de 300 ml\n🛵 Entrega ou retirada: __\n📍 Bairro: __\n💳 Pagamento: Pix ou cartão\n\nPode me confirmar o total?',
    combo:'Olá, TQR Açaí! 💜 Vim pelo site e quero o *Combo 3 por R$ 42*.\n\n🛵 Entrega ou retirada: __\n📍 Bairro: __\n💳 Pagamento: Pix ou cartão',
    kit:'Olá, TQR Açaí! 💜 Vim pelo site e quero *5 ou mais garrafas* (R$ 14 cada + entrega grátis).\n\n🥤 Quantidade: __\n📍 Bairro: __\n💳 Pagamento: Pix ou cartão',
    contato:'Olá, TQR Açaí! 💜 Vim pelo site e tenho uma dúvida.',
    revenda:'Olá, TQR Açaí! Vim pelo site e quero saber como revender o #TQR Açaí no meu negócio.\n\n🏪 Tipo de negócio: __\n📍 Bairro: __\n📦 Quantidade estimada por semana: __'
  };
  // Os links usam o número vigente (window.TQR_FONE); o painel pode trocá-lo, então os links são refeitos quando a configuração chega.
  window.TQR_relink=function(){document.querySelectorAll('[data-wa]').forEach(function(a){
    a.href='https://wa.me/'+window.TQR_FONE+'?text='+encodeURIComponent(br(MSG[a.dataset.wa]||MSG.contato));});};
  window.TQR_relink();
  document.querySelectorAll('[data-wa]').forEach(function(a){
    a.target='_blank'; a.rel='noopener';
    a.addEventListener('click',function(){
      var p={oferta:a.dataset.wa,posicao:a.dataset.src};
      try{window.dataLayer=window.dataLayer||[];dataLayer.push(Object.assign({event:'whatsapp_click'},p));}catch(e){}
      try{if(window.gtag)gtag('event','whatsapp_click',p);}catch(e){}
      try{if(window.fbq)fbq('track','Contact',p);}catch(e){}
    });
  });
  document.querySelectorAll('[data-cta]').forEach(function(a){a.addEventListener('click',function(){var p={posicao:a.dataset.cta};
    try{window.dataLayer=window.dataLayer||[];dataLayer.push(Object.assign({event:'pedido_cta'},p));}catch(e){}
    try{if(window.gtag)gtag('event','pedido_cta',p);}catch(e){}});});
  // Animação ao rolar
  var io='IntersectionObserver' in window?new IntersectionObserver(function(es){es.forEach(function(e){if(e.isIntersecting){e.target.classList.add('in');io.unobserve(e.target);}});},{threshold:.12}):null;
  document.querySelectorAll('.rv').forEach(function(el){io?io.observe(el):el.classList.add('in');});

  // Contadores animados
  var cio='IntersectionObserver' in window?new IntersectionObserver(function(es){es.forEach(function(e){if(!e.isIntersecting)return;var el=e.target,n=+el.dataset.count,p=el.dataset.prefix||'',x=el.dataset.suffix||'',t0=null;cio.unobserve(el);
    if(matchMedia('(prefers-reduced-motion: reduce)').matches)return;
    function f(t){if(!t0)t0=t;var k=Math.min(1,(t-t0)/1400),v=Math.round(n*(1-Math.pow(1-k,3)));el.textContent=p+v.toLocaleString('pt-BR')+x;if(k<1)requestAnimationFrame(f);}requestAnimationFrame(f);});},{threshold:.6}):null;
  document.querySelectorAll('[data-count]').forEach(function(el){cio&&cio.observe(el);});
  // Inclinação 3D da foto do topo (só com mouse)
  var hp=document.getElementById('heroPhoto');
  if(hp&&matchMedia('(hover:hover) and (pointer:fine)').matches&&!matchMedia('(prefers-reduced-motion: reduce)').matches){
    var hv=hp.parentElement;
    hv.addEventListener('mousemove',function(e){var r=hv.getBoundingClientRect(),x=(e.clientX-r.left)/r.width-.5,y=(e.clientY-r.top)/r.height-.5;hp.style.animation='none';hp.style.transform='perspective(900px) rotateY('+(x*10)+'deg) rotateX('+(-y*8)+'deg) translateY(-6px)';});
    hv.addEventListener('mouseleave',function(){hp.style.transform='';hp.style.animation='';});
  }

  // ===== INSTAGRAM (feed automático) =====
  // Cole aqui a URL do seu feed JSON do Behold (behold.so). Ex.: 'https://feeds.behold.so/XXXXXXXX'
  var INSTAGRAM_FEED_URL = '';
  (function(){
    var grid=document.getElementById('instaGrid'); if(!grid||!INSTAGRAM_FEED_URL) return;
    fetch(INSTAGRAM_FEED_URL).then(function(r){if(!r.ok)throw 0;return r.json();}).then(function(d){
      var posts=(d&&d.posts)||(Array.isArray(d)?d:[]); if(!posts.length) return;
      if(d.profilePictureUrl){document.getElementById('instaAvatar').src=d.profilePictureUrl;}
      if(d.biography){document.getElementById('instaBio').textContent=d.biography.split('\n')[0];}
      grid.innerHTML='';
      posts.slice(0,6).forEach(function(p){
        var src=(p.sizes&&p.sizes.medium&&p.sizes.medium.mediaUrl)||p.thumbnailUrl||p.mediaUrl;
        var a=document.createElement('a'); a.href=p.permalink; a.target='_blank'; a.rel='noopener';
        var img=document.createElement('img'); img.src=src; img.loading='lazy'; img.alt=(p.altText||p.prunedCaption||'Post do Instagram @tqracai').slice(0,120);
        if(p.colorPalette&&p.colorPalette.dominant){a.style.background='rgb('+p.colorPalette.dominant+')';}
        a.appendChild(img);
        if(p.mediaType==='VIDEO'){var v=document.createElement('span');v.className='vid';v.textContent='▶';a.appendChild(v);}
        grid.appendChild(a);
      });
    }).catch(function(){/* mantém as imagens padrão */});
  })();

  // ===== PÁGINA INICIAL: ofertas, pedido rápido e configuração (o formulário de pedido fica em pedido.html) =====
  (function(){
    if(document.getElementById('orderForm')) return;
    var SB={url:'https://elaczoriyaejkixkubxn.supabase.co',key:'sb_publishable_NscsoGdrovVNuBol72Rh3Q_ov8i8lGv'};
    var UN=16.99, COMBO={q:3,preco:42}, FAIXA={min:5,preco:14,frete:true}, QMIN=1, QMAX=99;
    function rpc(fn,args,ms){
      var ac=window.AbortController?new AbortController():null, t=ac&&setTimeout(function(){ac.abort();},ms||7000);
      return fetch(SB.url+'/rest/v1/rpc/'+fn,{method:'POST',headers:{apikey:SB.key,'Content-Type':'application/json'},body:JSON.stringify(args),signal:ac?ac.signal:undefined})
        .then(function(r){clearTimeout(t);if(!r.ok)throw new Error('http'+r.status);return r.json();},function(e){clearTimeout(t);throw e;});
    }
    function brl(v){return 'R$ '+Number(v).toFixed(2).replace('.',',').replace(/\B(?=(\d{3})+(?!\d))/g,'.');}
    function rs(v){return brl(v).replace(',00','');}
    function so(v){return Number(v)%1===0?String(Number(v)):Number(v).toFixed(2).replace('.',',');}
    function imgOk(u){return typeof u==='string'&&(/^img\/[\w.\-\/]+$/.test(u)||/^https:\/\/[^\s"'<>]+$/.test(u));}
    function mk(tag,cls,txt){var e=document.createElement(tag);if(cls)e.className=cls;if(txt!=null)e.textContent=txt;return e;}
    function calc(q){
      var total;
      if(FAIXA&&q>=FAIXA.min)total=q*FAIXA.preco;
      else if(COMBO){var c=Math.floor(q/COMBO.q),r=q%COMBO.q;total=c*COMBO.preco+r*UN;}
      else total=q*UN;
      return Math.round(total*100)/100;
    }
    function dica(q){
      var cq=COMBO&&COMBO.q, fm=FAIXA&&FAIXA.min;
      if(fm&&q>=fm)return 'Você ganhou '+rs(FAIXA.preco)+' por garrafa'+(FAIXA.frete?' e entrega grátis':'')+'.';
      if(fm&&q===fm-1)return 'Leve '+fm+' e pague '+rs(FAIXA.preco)+' cada'+(FAIXA.frete?', com entrega grátis':'')+'.';
      if(cq&&q<cq)return 'Leve '+cq+' por '+rs(COMBO.preco)+' e economize '+brl(cq*UN-COMBO.preco)+'.';
      if(cq&&q>=cq)return 'Combo '+cq+' aplicado: '+rs(COMBO.preco/cq)+' cada.';
      return '';
    }
    // vai para a página de pedido levando a quantidade (e os itens de kit) pela sessão
    function irPedido(q,itens){try{sessionStorage.setItem('tqr_cart',JSON.stringify({q:q||1,itens:itens||null}));}catch(e){}}
    function cardOferta(o){
      var d=mk('div','plan rv in'+(o.destaque?' best':''));
      if(o.rotulo)d.appendChild(mk('span','ribbon',o.rotulo));
      var pi=mk('div','pimg cover'),im=document.createElement('img');im.src=imgOk(o.img)?o.img:'img/hf-hero.webp';im.alt=o.titulo;im.loading='lazy';pi.appendChild(im);d.appendChild(pi);
      d.appendChild(mk('h3',null,o.titulo));d.appendChild(mk('div','qty',o.qtd));
      var v=mk('div','val');if(o.prefixo){v.appendChild(mk('small',null,o.prefixo));}v.appendChild(document.createTextNode(o.valor));if(o.sufixo){var sf=mk('small',null,o.sufixo);sf.style.cssText='font-size:.9rem;margin-left:4px';v.appendChild(sf);}d.appendChild(v);
      var u=mk('div','unit');if(o.unidade)u.appendChild(document.createTextNode(o.unidade));
      if(o.frete){if(o.unidade)u.appendChild(document.createTextNode(' '));u.appendChild(document.createTextNode('+ '));u.appendChild(mk('b',null,'entrega grátis'));}
      if(o.economia){u.appendChild(document.createElement('br'));u.appendChild(mk('span','save',o.economia));}
      d.appendChild(u);
      if(o.notas&&o.notas.length){var ul=mk('ul');o.notas.forEach(function(n){ul.appendChild(mk('li',null,n));});d.appendChild(ul);}
      var a=mk('a','btn '+(o.destaque?'btn-gold':'btn-ghost'),o.cta);a.href='pedido.html?q='+(o.qtdSug||1);
      a.addEventListener('click',function(){irPedido(o.qtdSug,o.itensKit);});d.appendChild(a);
      return d;
    }
    function ofertasDe(V){
      var porId={};V.produtos.forEach(function(p){porId[p.id]=p;});
      var out=[];
      V.produtos.forEach(function(p,i){
        out.push({titulo:p.nome,qtd:'1 unidade'+(p.volume_ml?' de '+p.volume_ml+' ml':''),valor:so(p.preco),prefixo:'R$',unidade:p.descricao||'',
          img:p.foto_url||(i===0?'img/hf-hero.webp':''),cta:'Pedir 1',qtdSug:1,itensKit:i===0?null:[{produto_id:p.id,qtd:1}],notas:i===0?['Pedido mínimo de 1 garrafa','Delivery ou retirada']:[]});
      });
      V.promocoes.forEach(function(x){
        var r=x.regra||{},o={titulo:x.titulo||x.nome,qtd:x.qtd_label||'',rotulo:x.rotulo,notas:x.notas||[],img:x.imagem_url,cta:x.cta||'Pedir agora',qtdSug:x.qtd_sugerida||1,destaque:x.destaque,frete:x.frete_gratis,prefixo:'R$'};
        if(x.tipo==='combo'){
          var qt=0,base=0;(r.itens||[]).forEach(function(it){qt+=it.qtd;base+=it.qtd*((porId[it.produto_id]||{}).preco||0);});
          o.valor=so(r.preco);o.unidade=qt?rs(r.preco/qt)+' cada':'';o.economia=base>r.preco?'Economize '+brl(base-r.preco):'';
          o.itensKit=r.itens;o.qtdSug=qt||o.qtdSug;if(!o.qtd)o.qtd=qt+' unidades';
        }else if(x.tipo==='faixa_quantidade'){
          o.valor=so(r.preco_unit);o.sufixo='/cada';o.economia=r.min+' garrafas por '+rs(r.min*r.preco_unit);o.qtdSug=r.min;if(!o.qtd)o.qtd='a partir de '+r.min+' unidades';
        }else if(x.tipo==='leve_pague'){o.prefixo='';o.valor='Leve '+r.leve+', pague '+r.pague;
        }else if(x.tipo==='casadinha'){o.prefixo='';o.valor=so(r.desconto_percentual)+'% off';o.unidade='na segunda unidade da casadinha';
        }else if(x.tipo==='desconto_percentual'){o.prefixo='';o.valor=so(r.percentual)+'%';o.sufixo='de desconto';
        }else if(x.tipo==='desconto_valor'){o.valor=so(r.valor);o.sufixo='de desconto';
        }else if(x.tipo==='frete_gratis'){o.prefixo='';o.valor='Frete grátis';o.frete=false;
        }else if(x.tipo==='brinde'){o.prefixo='';o.valor='Ganhe brinde';
          var pb=porId[r.produto_id];o.unidade=pb?r.qtd+'× '+pb.nome:'';}
        out.push(o);
      });
      return out;
    }
    // pedido rápido do topo
    var qq=document.getElementById('qQty');
    function qset(n){
      n=Math.max(QMIN,Math.min(QMAX,parseInt(n,10)||QMIN));qq.value=n;
      document.getElementById('qTotal').textContent=brl(calc(n));
      document.getElementById('qHint').textContent=dica(n);
    }
    if(qq){
      document.querySelectorAll('[data-qstep]').forEach(function(b){b.addEventListener('click',function(){qset((parseInt(qq.value,10)||1)+(+b.dataset.qstep));});});
      qq.addEventListener('input',function(){if(qq.value!=='')qset(qq.value);});
      qq.addEventListener('blur',function(){qset(qq.value);});
      var go=document.getElementById('quickGo');
      if(go)go.addEventListener('click',function(e){e.preventDefault();qset(qq.value);irPedido(+qq.value,null);location.href='pedido.html?q='+qq.value;});
      qset(qq.value);
    }
    document.querySelectorAll('a[data-qty]').forEach(function(a){a.addEventListener('click',function(){irPedido(+a.dataset.qty,null);});});
    function aplicaVitrine(V){
      if(!V||!V.produtos||!V.produtos.length)return;
      var MAIN=V.produtos[0];UN=+MAIN.preco;COMBO=null;FAIXA=null;
      V.promocoes.forEach(function(x){
        var r=x.regra||{};
        if(x.tipo==='combo'&&r.itens&&r.itens.length===1&&r.itens[0].produto_id===MAIN.id){var c={q:r.itens[0].qtd,preco:+r.preco};if(!COMBO||c.preco/c.q<COMBO.preco/COMBO.q)COMBO=c;}
        if(x.tipo==='faixa_quantidade'&&r.produto_id===MAIN.id){var fx={min:+r.min,preco:+r.preco_unit,frete:!!x.frete_gratis};if(!FAIXA||fx.preco<FAIXA.preco)FAIXA=fx;}
      });
      var plans=document.querySelector('#ofertas .plans');
      if(plans){plans.textContent='';ofertasDe(V).forEach(function(o){plans.appendChild(cardOferta(o));});}
      var qt=document.querySelector('.q-head .q-tab');
      if(qt){qt.textContent=rs(UN)+' cada';if(COMBO){var bb=document.createElement('b');bb.textContent=COMBO.q+' por '+rs(COMBO.preco);qt.appendChild(document.createTextNode(' · '));qt.appendChild(bb);}}
      var mb=document.querySelector('.mbar .p b');
      if(mb&&!mb.parentNode.dataset.fixo){var mn=UN;if(COMBO)mn=Math.min(mn,COMBO.preco/COMBO.q);if(FAIXA)mn=Math.min(mn,FAIXA.preco);mb.textContent=rs(mn);}
      if(qq)qset(qq.value);
    }
    rpc('obter_vitrine',{},6000).then(aplicaVitrine).catch(function(){});
    rpc('obter_config_publica',{},5000).then(function(c){
      if(!c||typeof c!=='object')return;
      window.TQR_CFG=c;try{document.dispatchEvent(new CustomEvent('tqr:config',{detail:c}));}catch(e){}
      if(/^55\d{10,11}$/.test(c.whatsapp||'')){window.TQR_FONE=c.whatsapp;if(window.TQR_relink)window.TQR_relink();}
      if(c.aviso){var av=document.createElement('div');av.className='aviso';av.setAttribute('role','status');av.textContent=c.aviso;document.body.insertBefore(av,document.body.firstChild);}
      var ct=document.getElementById('statCount');
      if(ct&&c.contador>0){ct.textContent='+'+Number(c.contador).toLocaleString('pt-BR');}
      if(c.pedido_min>0&&c.pedido_max>=c.pedido_min){QMIN=c.pedido_min;QMAX=c.pedido_max;if(qq){qq.min=QMIN;qq.max=QMAX;qset(qq.value);}}
    }).catch(function(){});
  })();

  // ===== FORMULÁRIO DE PEDIDO =====
  (function(){
    var f=document.getElementById('orderForm'); if(!f) return;
    // Valores padrão (prévia local) usados só se o servidor não responder. O total oficial vem de simular_pedido.
    var UN=16.99, QMIN=1, QMAX=99, COMBO={q:3,preco:42}, FAIXA={min:5,preco:14,frete:true};
    var PRODS=[], MAIN=null, EXTRA={}, BAIRROS=[], SIM=null, simTmr=null, simCache={}, GRUPOS=[], MONT=[];
    // Modo "carrinho" (cardápio por categoria, vários produtos, cada um com as suas opções). O padrão é "garrafa".
    var CARRINHO=false, CART=[], VIT=null, CATSEL=null;
    try{if(localStorage.getItem('tqr_modo')==='carrinho'){CARRINHO=true;f.classList.add('modo-carrinho');}}catch(e){}
    var qty=f.querySelector('#qty'), addr=document.getElementById('addrBox');
    function brl(v){return 'R$ '+Number(v).toFixed(2).replace('.',',').replace(/\B(?=(\d{3})+(?!\d))/g,'.');}
    function rs(v){return brl(v).replace(',00','');}  // "R$ 14" ou "R$ 16,99"
    function nome1(){return MAIN?MAIN.nome:'Açaí tradicional 300 ml';}
    function calc(q){
      var full=q*UN, total, label, free=false;
      if(FAIXA&&q>=FAIXA.min){total=q*FAIXA.preco;label=rs(FAIXA.preco)+' cada'+(FAIXA.frete?' + entrega grátis':'');free=!!FAIXA.frete;}
      else if(COMBO){var c=Math.floor(q/COMBO.q),r=q%COMBO.q;total=c*COMBO.preco+r*UN;label=c?(c+'× combo '+COMBO.q+(r?' + '+r+' avulsa'+(r>1?'s':''):'')):'preço unitário';}
      else{total=full;label='preço unitário';}
      return {full:full,total:Math.round(total*100)/100,label:label,free:free};
    }
    function dicaQtd(q){
      var cq=COMBO&&COMBO.q, fm=FAIXA&&FAIXA.min;
      if(fm&&q>=fm)return 'Você ganhou '+rs(FAIXA.preco)+' por garrafa'+(FAIXA.frete?' e entrega grátis':'')+'.';
      if(fm&&q===fm-1)return 'Leve '+fm+' e pague '+rs(FAIXA.preco)+' cada'+(FAIXA.frete?', com entrega grátis':'')+'.';
      if(cq&&q<cq)return 'Leve '+cq+' por '+rs(COMBO.preco)+' e economize '+brl(cq*UN-COMBO.preco)+'.';
      if(cq&&q>=cq)return 'Combo '+cq+' aplicado: '+rs(COMBO.preco/cq)+' cada.';
      return '';
    }
    function tipo(){return f.querySelector('input[name=tipo]:checked').value;}
    function cupomVal(){return (f.elements.cupom.value||'').trim();}
    function pagId(){var p=f.querySelector('input[name=pag]:checked');return p?p.value:null;}
    function bsel(){var fl=document.getElementById('bairroSelFld');return fl&&!fl.hidden?document.getElementById('bairroSel').value:'';}
    function modalidade(){if(tipo()==='retirada')return 'retirada';var b=bsel();return (b&&b!=='outro')?'entrega_bairro':'entrega_app';}
    function bairroId(){var b=bsel();return (b&&b!=='outro')?b:null;}
    function bairroNome(){var s=document.getElementById('bairroSel');if(modalidade()==='entrega_bairro'){var o=s.options[s.selectedIndex];return o?o.dataset.nome:'';}return (f.elements.bairro.value||'').trim();}
    function itens(){
      if(CARRINHO){
        var por={},ids=[];CART.forEach(function(l){if(!por[l.pid]){por[l.pid]=0;ids.push(l.pid);}por[l.pid]+=l.q;});
        return ids.length?ids.map(function(id){return {produto_id:id,quantidade:por[id]};}):null;
      }
      if(!MAIN)return null;
      var a=[{produto_id:MAIN.id,quantidade:+qty.value}];
      Object.keys(EXTRA).forEach(function(id){if(EXTRA[id]>0)a.push({produto_id:id,quantidade:EXTRA[id]});});
      return a;
    }
    // ===== Monte o seu açaí: opções por garrafa (o preço oficial vem do servidor) =====
    function gruposDe(pid){return GRUPOS.filter(function(g){return !g.produtos||g.produtos.indexOf(pid)>=0;});}
    function qtdProduto(pid){return MAIN&&pid===MAIN.id?(+qty.value||0):(EXTRA[pid]||0);}
    function usadoMont(pid,exceto){var u=0;MONT.forEach(function(m){if(m!==exceto&&m.pid===pid)u+=m.q;});return u;}
    function selIds(m){return Object.keys(m.sel).filter(function(k){return m.sel[k];});}
    function montagens(){if(CARRINHO)return CART.filter(function(l){return selIds(l).length>0;}).map(function(l){return {produto_id:l.pid,quantidade:l.q,opcoes:selIds(l)};});
      return MONT.filter(function(m){return m.q>0&&selIds(m).length>0;}).map(function(m){return {produto_id:m.pid,quantidade:m.q,opcoes:selIds(m)};});}
    function extraUnit(m){
      var t=0;gruposDe(m.pid).forEach(function(g){
        var ps=g.opcoes.filter(function(o){return m.sel[o.id];}).map(function(o){return +o.preco;}).sort(function(a,b){return b-a;});
        ps.forEach(function(p,i){if(i>=g.gratis_ate)t+=p;});});
      return Math.round(t*100)/100;
    }
    function erroMont(m){
      var e='';gruposDe(m.pid).forEach(function(g){var n=g.opcoes.filter(function(o){return m.sel[o.id];}).length;if(!e&&n<g.minimo)e='Escolha ao menos '+g.minimo+' em "'+g.nome+'".';});
      return e;
    }
    function montErro(){for(var i=0;i<MONT.length;i++){var e=erroMont(MONT[i]);if(e)return e;}return '';}
    function montSync(){
      var mudou=false;
      PRODS.forEach(function(p){var ex=usadoMont(p.id)-qtdProduto(p.id);
        for(var i=MONT.length-1;i>=0&&ex>0;i--){if(MONT[i].pid!==p.id)continue;var t=Math.min(ex,MONT[i].q);MONT[i].q-=t;ex-=t;mudou=true;}});
      var n=MONT.length;MONT=MONT.filter(function(m){return m.q>0;});if(MONT.length!==n)mudou=true;
      if(mudou)renderMont();
    }
    function renderMont(){
      var box=document.getElementById('montBox'),list=document.getElementById('montList'),temP=PRODS.some(function(p){return gruposDe(p.id).length;});
      box.hidden=!(GRUPOS.length&&temP);list.textContent='';
      MONT.forEach(function(m){
        var card=document.createElement('div');card.className='mont-card';
        var top=document.createElement('div');top.className='mont-top';
        var sel=document.createElement('select');sel.setAttribute('aria-label','Produto');
        PRODS.filter(function(p){return gruposDe(p.id).length;}).forEach(function(p){var o=document.createElement('option');o.value=p.id;o.textContent=p.nome;if(p.id===m.pid)o.selected=true;sel.appendChild(o);});
        sel.addEventListener('change',function(){m.pid=sel.value;m.sel={};m.q=Math.min(m.q,Math.max(1,qtdProduto(m.pid)-usadoMont(m.pid,m)));renderMont();update();});
        var st=document.createElement('div');st.className='xs';
        var mi=document.createElement('button'),pl=document.createElement('button'),b=document.createElement('b');mi.type=pl.type='button';mi.textContent='−';pl.textContent='+';b.textContent=m.q+(m.q===1?' garrafa':' garrafas');
        mi.setAttribute('aria-label','Menos garrafas nesta montagem');pl.setAttribute('aria-label','Mais garrafas nesta montagem');
        mi.addEventListener('click',function(){m.q=Math.max(1,m.q-1);renderMont();update();});
        pl.addEventListener('click',function(){if(usadoMont(m.pid,m)+m.q<qtdProduto(m.pid)){m.q++;renderMont();update();}});
        st.appendChild(mi);st.appendChild(b);st.appendChild(pl);top.appendChild(sel);top.appendChild(st);card.appendChild(top);
        gruposDe(m.pid).forEach(function(g){
          var gd=document.createElement('div');gd.className='mont-g';
          var t=document.createElement('b');t.textContent=g.nome;var sm=document.createElement('small');
          sm.textContent=(g.minimo>0?'Escolha de '+g.minimo+' a '+g.maximo:'Até '+g.maximo)+(g.gratis_ate>0?' · '+g.gratis_ate+' grátis':'');
          gd.appendChild(t);gd.appendChild(sm);
          var ops=document.createElement('div');ops.className='mont-ops';
          var n=g.opcoes.filter(function(o){return m.sel[o.id];}).length;
          g.opcoes.forEach(function(o){
            var lb=document.createElement('label'),cb=document.createElement('input');cb.type='checkbox';cb.checked=!!m.sel[o.id];
            var lock=o.esgotado||(!cb.checked&&n>=g.maximo);cb.disabled=lock;lb.className='mont-op'+(lock?' off':'');
            lb.appendChild(cb);lb.appendChild(document.createTextNode(o.nome+(o.esgotado?' (esgotado)':(+o.preco>0?' +'+rs(+o.preco):''))));
            cb.addEventListener('change',function(){if(cb.checked)m.sel[o.id]=true;else delete m.sel[o.id];renderMont();update();});
            ops.appendChild(lb);});
          gd.appendChild(ops);card.appendChild(gd);});
        var eu=extraUnit(m),er=erroMont(m);
        var s2=document.createElement('div');s2.className=er?'mont-err':'mont-sum';s2.textContent=er||(selIds(m).length?('Adicional: '+brl(eu)+' por garrafa'+(m.q>1?' ('+brl(eu*m.q)+' no total)':'')):'Escolha as opções que quiser.');
        card.appendChild(s2);
        var rm=document.createElement('button');rm.type='button';rm.className='mont-rm';rm.textContent='Remover esta montagem';
        rm.addEventListener('click',function(){MONT=MONT.filter(function(x){return x!==m;});renderMont();update();});card.appendChild(rm);
        list.appendChild(card);});
    }
    document.getElementById('montAdd').addEventListener('click',function(){
      var p=PRODS.filter(function(x){return gruposDe(x.id).length&&qtdProduto(x.id)-usadoMont(x.id)>0;})[0];
      if(!p){var h=document.getElementById('qtyHint');h.textContent='Aumente a quantidade de garrafas para montar mais uma.';return;}
      MONT.push({pid:p.id,q:1,sel:{}});renderMont();update();
    });
    function montTexto(S){
      var ms=(S&&S.montagens)||[],L=[];
      ms.forEach(function(m){
        var com=[],sem=[];(m.opcoes||[]).forEach(function(o){(opRetirar(o.id)?sem:com).push(o.nome);});
        var t=m.quantidade+'× '+m.nome_produto+(com.length?' com '+com.join(', '):'')+(sem.length?' sem '+sem.join(', '):'');
        L.push(t+(+m.extra_unit>0?' (+'+brl(+m.extra_unit)+' cada)':''));});
      return L;
    }
    function linhasTexto(){
      if(CARRINHO)return CART.length?CART.map(textoLinha):['Nenhum item ainda'];
      var q=+qty.value, t=[q+'× '+nome1()];
      PRODS.slice(1).forEach(function(p){if(EXTRA[p.id]>0)t.push(EXTRA[p.id]+'× '+p.nome);});
      return t;
    }
    // atualiza as caixas do resumo (visão local ou a do servidor)
    function pinta(v){
      document.getElementById('sumQty').textContent=v.linhas;
      document.getElementById('sumSub').textContent=brl(v.sub);
      document.getElementById('sumDiscRow').style.display=v.desc>0.009?'':'none';
      document.getElementById('sumDisc').textContent='− '+brl(v.desc);
      var sp=document.getElementById('sumPromo');sp.textContent=v.promo||'';sp.hidden=!v.promo;
      document.getElementById('sumShip').textContent=v.ship;
      document.getElementById('sumTotal').textContent=brl(v.total);
      document.getElementById('sumNote').textContent=v.note;
    }
    function notaEntrega(mod,gratis,taxa){
      if(mod==='retirada')return 'Combine o horário e o local de retirada no WhatsApp.';
      if(mod==='entrega_bairro')return gratis?'Entrega grátis nesta promoção.':'Taxa de entrega fixa do bairro: '+brl(taxa)+'.';
      return gratis?'Entrega grátis nesta promoção.':'A taxa de entrega é a do aplicativo e é confirmada no WhatsApp.';
    }
    function visaoLocal(c){
      if(CARRINHO){var m0=modalidade(),e0=m0!=='retirada';
        return {linhas:linhasTexto().join(' · '),sub:c.full,desc:0,promo:'',ship:!e0?'retirada':'taxa do app',total:c.total,note:notaEntrega(m0,false,0)};}
      var q=+qty.value, mod=modalidade(), ent=mod!=='retirada', extra=0;
      PRODS.slice(1).forEach(function(p){extra+=(EXTRA[p.id]||0)*p.preco;});
      return {linhas:linhasTexto().join(' · ').replace(/× /g,'× '),sub:c.full+extra,desc:c.full-c.total,promo:'',
        ship:!ent?'retirada':(c.free?'grátis':'taxa do app'),total:c.total+extra,note:notaEntrega(mod,c.free&&ent,0)};
    }
    function visaoSim(S){
      var mod=S.modalidade, ent=mod!=='retirada', brindes=(S.brindes||[]).map(function(b){return '+ '+b.quantidade+'× '+b.nome+' (brinde)';});
      var promo=S.promocao?('Promoção aplicada: '+S.promocao.nome):'';
      if(brindes.length)promo=(promo?promo+' · ':'')+brindes.join(' · ');
      var ship=!ent?'retirada':(mod==='entrega_bairro'?(S.frete_gratis?'grátis':brl(S.taxa_entrega)):(S.frete_gratis?'grátis':'taxa do app'));
      var mt=montTexto(S);
      return {linhas:S.itens.map(function(l){return l.quantidade+'× '+l.nome;}).concat(mt).join(' · '),sub:+S.subtotal+(+S.extras||0),desc:+S.desconto,promo:promo,ship:ship,
        total:+S.total,note:notaEntrega(mod,S.frete_gratis,S.taxa_entrega)};
    }
    function pintaCupom(S){
      var m=document.getElementById('cupomMsg'), st=S&&S.cupom_status;
      if(!st||!cupomVal()){m.hidden=true;return;}
      m.hidden=false;
      m.textContent=st==='aplicado'?'✓ Cupom aplicado: '+S.promocao.nome:(st==='invalido'?'Cupom inválido ou expirado.':'Cupom válido, mas já aplicamos a melhor promoção disponível.');
    }
    function simKey(){var d=digits();return JSON.stringify([itens(),montagens(),cupomVal().toLowerCase(),modalidade(),bairroId(),pagId(),d.length>=10?d:null]);}
    function simular(){
      var it=itens(); if(!it)return Promise.resolve(null);
      var key=simKey(); if(simCache[key])return Promise.resolve(simCache[key]);
      var d=digits();
      var base={p_itens:it,p_cupom:cupomVal()||null,p_modalidade:modalidade(),p_bairro_id:bairroId(),p_forma:pagId(),p_whatsapp:d.length>=10?d:null};
      if(GRUPOS.length)base.p_montagens=montagens();
      return rpc(GRUPOS.length?'simular_pedido_v3':'simular_pedido',base,5000)
        .then(function(r){if(r&&r.total!=null){r._k=key;simCache[key]=r;return r;}return null;}).catch(function(){return null;});
    }
    function agendarSim(){
      clearTimeout(simTmr);
      simTmr=setTimeout(function(){var key=simKey();simular().then(function(r){if(key!==simKey())return;SIM=r;if(r){pinta(visaoSim(r));pintaCupom(r);if(qq&&!EXTRA_ATIVO())document.getElementById('qTotal').textContent=brl(r.total);}else pintaCupom(null);});},250);
    }
    function EXTRA_ATIVO(){return Object.keys(EXTRA).some(function(k){return EXTRA[k]>0;});}
    function syncBairro(){
      var fl=document.getElementById('bairroSelFld'), tf=document.getElementById('bairroTxtFld'), ti=f.elements.bairro, ent=tipo()==='entrega';
      var usaSel=BAIRROS.length>0&&!fl.hidden;
      var outro=!usaSel||document.getElementById('bairroSel').value==='outro';
      tf.hidden=!ent||!outro; ti.required=ent&&outro; if(!ent||!outro)ti.dataset.req=1;
      document.getElementById('bairroSel').required=ent&&usaSel;
    }
    function update(){
      var q=CARRINHO?unidades():Math.max(QMIN,Math.min(QMAX,parseInt(qty.value,10)||QMIN)); if(!CARRINHO)qty.value=q;
      var c=CARRINHO?calcCarrinho():calc(q), ent=tipo()==='entrega';
      if(CARRINHO)renderLinhas();else montSync();
      pinta(visaoLocal(c));
      if(!CARRINHO){
      document.getElementById('qtyHint').textContent=dicaQtd(q);
      f.querySelectorAll('.qchips button').forEach(function(b){var v=+b.dataset.set;b.classList.toggle('on',FAIXA&&v===FAIXA.min?q>=FAIXA.min:q===v);});
      }
      addr.hidden=!ent; addr.querySelectorAll('input[required],input[data-req],select').forEach(function(i){if(i.id==='bairroSel')return;if(ent){if(i.name!=='bairro')i.required=true;}else{i.dataset.req=1;i.required=false;}});
      syncBairro();
      if(SIM&&simKey()===SIM._k){pinta(visaoSim(SIM));}
      agendarSim();
      cartExtra(q,c);
      return c;
    }
    function setQty(n){qty.value=n;update();var q=document.getElementById('qQty');if(q){q.value=n;document.getElementById('qTotal').textContent=brl(calc(+n).total);}}
    // ===== Cardápio: atalhos de pacote, carrinho (frete grátis, pontos) e barra do celular =====
    var PACKIMG={1:'img/hf-hero.webp',3:'img/hf-combo.webp',5:'img/kit5.webp'};
    function renderPacks(){
      var box=document.getElementById('packs'); if(!box)return;
      var lista=[{q:1,t:'Unidade',d:'1 garrafa',p:rs(UN)}];
      if(COMBO)lista.push({q:COMBO.q,t:'Combo '+COMBO.q,d:rs(COMBO.preco/COMBO.q)+' cada',p:brl(COMBO.preco),sv:'Economize '+brl(COMBO.q*UN-COMBO.preco),best:true,img:3});
      if(FAIXA)lista.push({q:FAIXA.min,t:FAIXA.min+' ou mais',d:rs(FAIXA.preco)+' cada'+(FAIXA.frete?' · entrega grátis':''),p:brl(FAIXA.min*FAIXA.preco),sv:FAIXA.frete?'Frete por nossa conta':'',img:5});
      box.textContent='';
      lista.forEach(function(x){
        var b=document.createElement('button');b.type='button';b.className='pack';b.dataset.q=x.q;
        if(x.best){var be=document.createElement('i');be.className='best';be.textContent='Mais pedido';b.appendChild(be);}
        var im=document.createElement('img');im.src=PACKIMG[x.img||1];im.alt='';im.loading='lazy';b.appendChild(im);
        [['b',x.t],['span',x.d],['span',x.p,'pr'],['span',x.sv,'sv']].forEach(function(r){if(!r[1])return;var e=document.createElement(r[0]);e.textContent=r[1];if(r[2])e.className=r[2];b.appendChild(e);});
        b.addEventListener('click',function(){EXTRA={};renderExtras();setQty(x.q);});
        box.appendChild(b);
      });
      var pp=document.getElementById('pProdPreco'); if(pp)pp.textContent=rs(UN);
      var pn=document.getElementById('pProdNome'); if(pn&&MAIN)pn.textContent=MAIN.nome;
    }
    // ===== Acompanhamento do pedido: consulta o status no banco e atualiza a linha do tempo =====
    var TRK={code:null,zap:null,t:null,ent:true,fim:false};
    function hm(s){try{return new Date(s).toLocaleTimeString('pt-BR',{hour:'2-digit',minute:'2-digit'});}catch(e){return '';}}
    function trkRender(r){
      var ol=document.getElementById('trkList'),msg=document.getElementById('trkMsg'); if(!ol)return;
      var idx={pendente:0,confirmado:1,pago:1,saiu_entrega:2,entregue:3}[r.status];
      var ev={}; (r.eventos||[]).forEach(function(e){var k=e.status==='pago'?'confirmado':e.status; if(!ev[k]||e.em<ev[k])ev[k]=e.em; if(e.status==='pago')ev.pago=e.em;});
      var ret=!!r.retirada, canc=r.status==='cancelado';
      var steps=[['Pedido recebido','Obrigado!',r.criado_em],
        [ev.pago?'Confirmado e pago':'Confirmado','Valor, taxa e pagamento',ev.confirmado],
        [ret?'Pronto para retirar':'A caminho',ret?'Avisamos quando estiver pronto':'Avisamos quando sair',ev.saiu_entrega],
        [ret?'Retirado':'Entregue','Agite e tome',ev.entregue]];
      ol.textContent=''; ol.hidden=false;
      steps.forEach(function(s,i){
        var done=!canc&&idx>=i, now=!canc&&idx===i&&i<3, li=document.createElement('li');
        if(done)li.className='on'+(now?' now':'');
        var n=document.createElement('i'); n.textContent=done?'✓':String(i+1);
        var sp=document.createElement('span'),b=document.createElement('b'); b.textContent=s[0]; sp.appendChild(b);
        sp.appendChild(document.createTextNode(done&&s[2]?(i===0?'Hoje às ':'às ')+hm(s[2]):s[1]));
        li.appendChild(n); li.appendChild(sp); ol.appendChild(li);
      });
      var cc=document.getElementById('trkCode');
      if(cc){var tem=!!r.codigo_entrega; cc.hidden=!tem;
        if(tem){document.getElementById('trkCodeT').textContent=ret?'Seu código de retirada':'Seu código de entrega';document.getElementById('trkCodeV').textContent=r.codigo_entrega;document.getElementById('trkCodeD').textContent=ret?'Informe este código no balcão para receber o pedido.':'Informe este código ao entregador quando ele chegar.';}}
      TRK.fim=canc||r.status==='entregue';
      if(msg){msg.hidden=false;msg.textContent=canc?'Este pedido foi cancelado. Se foi um engano, fale com a gente no WhatsApp.':(r.status==='entregue'?'Pedido '+(ret?'retirado':'entregue')+'. Bom açaí! 💜':'Atualiza sozinho. Última checagem às '+hm(new Date())+'.');}
    }
    function trkTick(){
      if(!TRK.code||TRK.fim)return;
      rpc('acompanhar_pedido',{p_codigo:TRK.code,p_whatsapp:TRK.zap},8000).then(function(r){
        if(!r||!r.encontrado){var m=document.getElementById('trkMsg');if(m&&!TRK.ok){m.hidden=false;m.textContent='Não encontramos esse pedido para esse WhatsApp. Confira o número usado no pedido.';}return;}
        TRK.ok=true; trkRender(r); trkSchedule();
        if(TRK.fim)try{localStorage.setItem('tqr_last',JSON.stringify({c:TRK.code,w:TRK.zap,t:Date.now(),f:1}));}catch(e){}
      }).catch(function(){
        var m=document.getElementById('trkMsg'); if(m){m.hidden=false;m.textContent='Não consegui atualizar agora (conexão). Tentando de novo em instantes…';}
        trkSchedule();
      });
    }
    function trkSchedule(){clearTimeout(TRK.t); if(TRK.fim||!TRK.code)return; TRK.t=setTimeout(function(){if(document.hidden){trkSchedule();return;}trkTick();},20000);}
    function trkStart(code,zap){
      TRK.code=code; TRK.zap=zap; TRK.fim=false; TRK.ok=false;
      try{localStorage.setItem('tqr_last',JSON.stringify({c:code,w:zap,t:Date.now()}));}catch(e){}
      trkTick();
    }
    document.addEventListener('visibilitychange',function(){if(!document.hidden&&TRK.code&&!TRK.fim){clearTimeout(TRK.t);trkTick();}});
    window.addEventListener('pageshow',function(e){if(e.persisted&&TRK.code&&!TRK.fim){clearTimeout(TRK.t);trkTick();}});
    (function(){var b=document.getElementById('trkNow'); if(b)b.addEventListener('click',function(){var m=document.getElementById('trkMsg');if(m){m.hidden=false;m.textContent='Atualizando…';}clearTimeout(TRK.t);TRK.fim=false;trkTick();});})();
    // pedido recente ainda em andamento: aviso no topo da página de pedido (a confirmação some ao recarregar)
    (function(){
      if(/[?&]acompanhar=/.test(location.search)||!document.getElementById('orderForm'))return;
      var last=null;try{last=JSON.parse(localStorage.getItem('tqr_last')||'null');}catch(e){}
      var bx=document.getElementById('lastOrder'); if(!bx||!last||!last.c||last.f||!last.t||Date.now()-last.t>24*3600*1000)return;
      document.getElementById('lastOrderCod').textContent=last.c; document.getElementById('lastOrderLink').href='pedido.html?acompanhar='+encodeURIComponent(last.c); bx.hidden=false;
    })();
    function mostraConf(o){
      var conf=document.getElementById('conf'); if(!conf)return;
      var cod=document.getElementById('confCod'); cod.hidden=!o.code; cod.textContent=o.code?'Pedido '+o.code:'';
      document.getElementById('confMsg').textContent=o.code?(document.getElementById('confMsg').dataset.ok||'Já estamos separando o seu pedido. A mensagem do pedido abre no nosso WhatsApp para confirmarmos valor, taxa e pagamento.'):'A mensagem do pedido está pronta no WhatsApp. Envie para confirmarmos valor, taxa e pagamento.';
      var it=document.getElementById('confItens'); it.textContent='';
      o.itens.concat([o.ent?'🛵 Entrega'+(o.bn?' – '+o.bn:''):'🏠 Retirada','💳 '+o.pagn]).forEach(function(t){var d=document.createElement('div');d.className='l';d.textContent=t.replace(/^•\s*/,'');it.appendChild(d);});
      document.getElementById('confTotal').textContent=brl(o.tot);
      var wa=document.getElementById('confWa'); wa.href=o.url;
      f.hidden=true; conf.hidden=false;
      var cb=document.getElementById('cartBar'); if(cb)cb.hidden=true;
      var hh=document.querySelector('.p-head'); if(hh)hh.hidden=true;
      document.title=br('Pedido recebido | #TQR Açaí');
      var st=document.querySelector('.p-steps'); if(st)st.hidden=true;
      var lo=document.getElementById('lastOrder'); if(lo)lo.hidden=true;
      window.scrollTo(0,0); try{conf.focus({preventScroll:true});}catch(e){}
      if(o.code&&o.zap)trkStart(o.code,o.zap);
      if(o.code&&o.zap&&window.TQR_registraAparelho)window.TQR_registraAparelho(o.code,o.zap);
      try{if(window.TQR_confete)window.TQR_confete();}catch(e){}
    }
    (function(){
      var m=/[?&]acompanhar=([A-Za-z0-9-]{4,20})/.exec(location.search), conf=document.getElementById('conf'); if(!m||!conf)return;
      var code=m[1].toUpperCase(), last=null; try{last=JSON.parse(localStorage.getItem('tqr_last')||'null');}catch(e){}
      document.getElementById('confCod').hidden=false; document.getElementById('confCod').textContent='Pedido '+code;
      document.getElementById('confMsg').textContent='Veja em que etapa está o seu pedido.';
      conf.querySelector('h2').textContent='Acompanhe seu pedido';
      conf.querySelector('.cbox').hidden=true; document.getElementById('confWa').hidden=true;
      f.hidden=true; conf.hidden=false; document.title=br('Acompanhar pedido | #TQR Açaí');
      ['.p-head','.p-steps'].forEach(function(s){var e=document.querySelector(s);if(e)e.hidden=true;});
      var cb=document.getElementById('cartBar'); if(cb)cb.hidden=true;
      if(last&&last.c===code&&last.w){setTimeout(function(){trkStart(code,last.w);},0);return;}  // adiado: SB (banco) é definido mais abaixo neste arquivo
      var ask=document.getElementById('trkAsk'); ask.hidden=false; document.getElementById('trkList').hidden=true;
      ask.addEventListener('submit',function(e){e.preventDefault();var w=document.getElementById('trkZap').value.replace(/\D/g,''); if(w.length<10){var mm=document.getElementById('trkMsg');mm.hidden=false;mm.textContent='Informe o DDD e o número.';return;}
        ask.hidden=true; trkStart(code,w);});
    })();
    window.TQR_registraAparelho=function(code,zap){
      rpc('registrar_aparelho',{p_codigo:code,p_whatsapp:zap},8000).then(function(r){
        if(!r||!r.ok)return;
        SESS={w:zap,t:r.token};window.TQR_DEV.set(zap,r.token,180);
        var bx=document.getElementById('confAcesso'); if(!bx)return;
        document.getElementById('confAcessoCod').textContent=r.acesso; bx.hidden=false;
        var cp=document.getElementById('confAcessoCp'); if(cp)cp.onclick=function(){var b=this;(navigator.clipboard?navigator.clipboard.writeText(r.acesso):Promise.reject()).then(function(){b.textContent='Copiado!';},function(){b.textContent='Anote o código acima';});};
      }).catch(function(){});
    };
    function cartExtra(q,c){
      document.querySelectorAll('#packs .pack').forEach(function(b,i,all){
        var v=+b.dataset.q,next=all[i+1]?+all[i+1].dataset.q:Infinity;
        b.classList.toggle('on',q>=v&&q<next);
      });
      var fb=document.getElementById('freBox');
      if(fb){
        if(FAIXA&&FAIXA.frete){
          fb.hidden=false;var falta=FAIXA.min-q;
          document.getElementById('freTxt').textContent=falta>0?'Faltam '+falta+(falta===1?' garrafa':' garrafas')+' para entrega grátis.':'Entrega grátis garantida neste pedido.';
          document.getElementById('freBar').style.width=Math.min(100,Math.round(q/FAIXA.min*100))+'%';
        }else fb.hidden=true;
      }
      var tot=c?c.total:0, pt=document.getElementById('sumPts');
      if(pt){var pts=Math.floor(tot*((window.TQR_CFG&&+window.TQR_CFG.pontos_por_real)||1));pt.hidden=!(pts>0);pt.textContent='Você ganha '+pts+' pontos neste pedido';}
      var cb=document.getElementById('cartBar');
      if(cb){document.getElementById('cbQty').textContent=q+(CARRINHO?(q===1?' item':' itens'):(q===1?' garrafa':' garrafas'));document.getElementById('cbTotal').textContent=document.getElementById('sumTotal').textContent||brl(tot);}
    }
    var sT=document.getElementById('sumTotal'),cbT=document.getElementById('cbTotal');
    if(sT&&cbT&&window.MutationObserver)new MutationObserver(function(){cbT.textContent=sT.textContent;}).observe(sT,{childList:true,characterData:true,subtree:true});
    var pendente=null;
    (function(){
      try{var cr=JSON.parse(sessionStorage.getItem('tqr_cart')||'null');if(cr&&cr.q)pendente=cr;sessionStorage.removeItem('tqr_cart');}catch(e){}
      var m=/[?&]q=(\d+)/.exec(location.search); if(!pendente&&m)pendente={q:+m[1],itens:null};
    })();
    function aplicaPendente(){if(!pendente)return;var p=pendente;pendente=null;window.TQR_pedir(p.q,p.itens);}
    // some a barra do celular quando o resumo já está na tela
    if('IntersectionObserver' in window&&document.getElementById('sumBox')&&document.getElementById('cartBar')){
      new IntersectionObserver(function(es){document.getElementById('cartBar').classList.toggle('off',es[0].isIntersecting);}).observe(document.getElementById('sumBox'));
    }
    f.querySelectorAll('.qbtn').forEach(function(b){b.addEventListener('click',function(){qty.value=(parseInt(qty.value,10)||1)+(+b.dataset.step);update();});});
    f.querySelectorAll('.qchips button').forEach(function(b){b.addEventListener('click',function(){qty.value=b.dataset.set;update();});});
    qty.addEventListener('input',update); f.querySelectorAll('input[name=tipo]').forEach(function(r){r.addEventListener('change',update);});
    f.addEventListener('change',function(e){var n=e.target&&e.target.name;if(n==='pag'||e.target.id==='bairroSel')update();});
    f.elements.cupom.addEventListener('input',function(){clearTimeout(simTmr);document.getElementById('cupomMsg').hidden=true;agendarSim();});
    // "Pedir" nos cartões de oferta: define a quantidade (e os itens, no caso de kit com mais de um produto)
    window.TQR_pedir=function(qtd,itensKit){
      if(CARRINHO){(itensKit||[]).forEach(function(it){addLinha(it.produto_id,{},it.qtd);});update();return;}
      EXTRA={}; var q=qtd||1;
      if(itensKit&&itensKit.length){q=0;itensKit.forEach(function(it){if(MAIN&&it.produto_id===MAIN.id)q+=it.qtd;else EXTRA[it.produto_id]=(EXTRA[it.produto_id]||0)+it.qtd;});if(!q)q=1;}
      renderExtras(); setQty(q);
    };
    document.querySelectorAll('a[data-qty]').forEach(function(a){a.addEventListener('click',function(){window.TQR_pedir(+a.dataset.qty);});});
    function renderExtras(){
      var box=document.getElementById('extraProds'); box.textContent='';
      var outros=PRODS.slice(1); box.hidden=!outros.length; if(!outros.length)return;
      outros.forEach(function(p){
        var r=document.createElement('div'),n=document.createElement('div'),sm=document.createElement('small'),st=document.createElement('div'),m=document.createElement('button'),pl=document.createElement('button'),b=document.createElement('b');
        r.className='xrow';n.className='xn';n.textContent=p.nome;sm.textContent=rs(+p.preco)+' cada';n.appendChild(sm);
        st.className='xs';m.type=pl.type='button';m.textContent='−';pl.textContent='+';m.setAttribute('aria-label','Diminuir '+p.nome);pl.setAttribute('aria-label','Aumentar '+p.nome);
        b.textContent=EXTRA[p.id]||0;
        m.addEventListener('click',function(){EXTRA[p.id]=Math.max(0,(EXTRA[p.id]||0)-1);b.textContent=EXTRA[p.id];update();});
        pl.addEventListener('click',function(){EXTRA[p.id]=Math.min(QMAX,(EXTRA[p.id]||0)+1);b.textContent=EXTRA[p.id];update();});
        st.appendChild(m);st.appendChild(b);st.appendChild(pl);r.appendChild(n);r.appendChild(st);box.appendChild(r);
      });
    }
    // ===== Modo carrinho: cardápio por categoria, janela de opções e linhas do pedido =====
    function imgOk2(u){return typeof u==='string'&&(/^img\/[\w.\-\/]+$/.test(u)||/^https:\/\/[^\s"'<>]+$/.test(u));}
    function opRetirar(id){return GRUPOS.some(function(g){return g.tipo==='retirar'&&g.opcoes.some(function(o){return o.id===id;});});}
    function produtoPorId(id){return PRODS.filter(function(p){return p.id===id;})[0];}
    function descOpcoes(l){
      var com=[],sem=[];
      GRUPOS.forEach(function(g){g.opcoes.forEach(function(o){if(l.sel[o.id])(g.tipo==='retirar'?sem:com).push(o.nome);});});
      return (com.length?' com '+com.join(', '):'')+(sem.length?' sem '+sem.join(', '):'');
    }
    function textoLinha(l){var p=produtoPorId(l.pid);return l.q+'× '+(p?p.nome:'Item')+descOpcoes(l);}
    function unidades(){return CART.reduce(function(a,l){return a+l.q;},0);}
    function calcCarrinho(){
      var t=0;CART.forEach(function(l){var p=produtoPorId(l.pid);if(p)t+=l.q*(+p.preco+extraUnit(l));});
      t=Math.round(t*100)/100;return {full:t,total:t,label:'',free:false};
    }
    function addLinha(pid,sel,q){
      if(!produtoPorId(pid))return;
      var k=pid+'|'+Object.keys(sel).filter(function(i){return sel[i];}).sort().join(',');
      var l=CART.filter(function(x){return x.k===k;})[0];
      if(l)l.q=Math.min(QMAX,l.q+q);else CART.push({k:k,pid:pid,q:Math.min(QMAX,q),sel:JSON.parse(JSON.stringify(sel))});
    }
    function el2(tag,cls,txt){var e=document.createElement(tag);if(cls)e.className=cls;if(txt!=null)e.textContent=txt;return e;}
    function renderLinhas(){
      var box=document.getElementById('cardLinhas');if(!box)return;box.textContent='';
      var ch=document.getElementById('cardHint');if(CART.length&&ch)ch.hidden=true;
      if(!CART.length){box.appendChild(el2('p','hint','Seu pedido está vazio. Escolha acima o que quer pedir.'));return;}
      CART.forEach(function(l){
        var p=produtoPorId(l.pid),r=el2('div','xrow'),n=el2('div','xn',(p?p.nome:'Item')+descOpcoes(l)),
            un=(p?+p.preco:0)+extraUnit(l);
        n.appendChild(el2('small',null,rs(un)+' cada'));
        var st=el2('div','xs'),m=el2('button',null,'−'),pl=el2('button',null,'+'),b=el2('b',null,String(l.q));
        m.type=pl.type='button';m.setAttribute('aria-label','Menos '+(p?p.nome:'item'));pl.setAttribute('aria-label','Mais '+(p?p.nome:'item'));
        m.addEventListener('click',function(){l.q--;if(l.q<=0)CART=CART.filter(function(x){return x!==l;});update();});
        pl.addEventListener('click',function(){l.q=Math.min(QMAX,l.q+1);update();});
        st.appendChild(m);st.appendChild(b);st.appendChild(pl);r.appendChild(n);r.appendChild(st);box.appendChild(r);
      });
    }
    function montaCardapio(){
      var root=document.getElementById('cardapio'),lg=document.querySelector('#orderForm .f-group legend');
      if(!root)return;
      if(lg){if(!lg.dataset.orig)lg.dataset.orig=lg.textContent;lg.textContent=CARRINHO?'1. Escolha os seus itens':lg.dataset.orig;}
      root.hidden=!CARRINHO;
      if(!CARRINHO||!VIT)return;
      COMBO=null;FAIXA=null;
      var cats=(VIT.categorias||[]).slice(),prods=PRODS.slice(),grupos=[];
      cats.forEach(function(c){var ps=prods.filter(function(p){return p.categoria_id===c.id;});if(ps.length)grupos.push({id:c.id,nome:c.nome,ps:ps});});
      var sem=prods.filter(function(p){return !p.categoria_id||!cats.some(function(c){return c.id===p.categoria_id;});});
      if(sem.length)grupos.push({id:'_',nome:grupos.length?'Outros':'Cardápio',ps:sem});
      if(!grupos.some(function(g){return g.id===CATSEL;}))CATSEL=grupos.length?grupos[0].id:null;
      var tabs=document.getElementById('cardTabs'),grid=document.getElementById('cardGrid');tabs.textContent='';grid.textContent='';
      tabs.hidden=grupos.length<2;
      grupos.forEach(function(g){
        var b=el2('button','ctab'+(g.id===CATSEL?' on':''),g.nome);b.type='button';b.setAttribute('aria-pressed',g.id===CATSEL?'true':'false');
        b.addEventListener('click',function(){CATSEL=g.id;montaCardapio();});tabs.appendChild(b);
      });
      grupos.filter(function(g){return grupos.length<2||g.id===CATSEL;}).forEach(function(g){
        g.ps.forEach(function(p){
          var c=el2('article','cprod');
          if(imgOk2(p.foto_url)){var im=document.createElement('img');im.src=p.foto_url;im.alt='';im.loading='lazy';c.appendChild(im);}
          var tx=el2('div','cp-t');tx.appendChild(el2('h4',null,p.nome));if(p.descricao)tx.appendChild(el2('p',null,p.descricao));
          tx.appendChild(el2('b','cp-p',rs(+p.preco)));c.appendChild(tx);
          var bt=el2('button','btn btn-gold',gruposDe(p.id).length?'Escolher':'Adicionar');bt.type='button';
          bt.setAttribute('aria-label',(gruposDe(p.id).length?'Escolher opções de ':'Adicionar ')+p.nome);
          bt.addEventListener('click',function(){if(gruposDe(p.id).length)abrirOpcoes(p);else{addLinha(p.id,{},1);update();}});
          c.appendChild(bt);grid.appendChild(c);
        });
      });
    }
    function abrirOpcoes(p){
      var dlg=document.getElementById('optDlg');if(!dlg||!dlg.showModal)return;
      var m={pid:p.id,q:1,sel:{}};
      function pinta2(){
        dlg.textContent='';
        dlg.appendChild(el2('h3',null,p.nome));if(p.descricao)dlg.appendChild(el2('p','od-d',p.descricao));
        gruposDe(p.id).forEach(function(g){
          var gd=el2('div','mont-g'),ret=g.tipo==='retirar';
          gd.appendChild(el2('b',null,g.nome));
          gd.appendChild(el2('small',null,(ret?'Marque o que quer tirar':(g.minimo>0?'Escolha de '+g.minimo+' a '+g.maximo:'Até '+g.maximo))+(!ret&&g.gratis_ate>0?' · '+g.gratis_ate+' grátis':'')));
          var ops=el2('div','mont-ops'),n=g.opcoes.filter(function(o){return m.sel[o.id];}).length;
          g.opcoes.forEach(function(o){
            var lb=document.createElement('label'),cb=document.createElement('input');cb.type='checkbox';cb.checked=!!m.sel[o.id];
            var lock=o.esgotado||(!cb.checked&&n>=g.maximo&&g.maximo>1);cb.disabled=lock;lb.className='mont-op'+(lock?' off':'');
            lb.appendChild(cb);lb.appendChild(document.createTextNode((ret?'Sem ':'')+o.nome+(o.esgotado?' (esgotado)':(!ret&&+o.preco>0?' +'+rs(+o.preco):''))));
            cb.addEventListener('change',function(){
              if(cb.checked){if(g.maximo===1)g.opcoes.forEach(function(x){delete m.sel[x.id];});m.sel[o.id]=true;}else delete m.sel[o.id];
              pinta2();
            });
            ops.appendChild(lb);
          });
          gd.appendChild(ops);dlg.appendChild(gd);
        });
        var er=el2('p','mont-err');er.id='optErr';er.hidden=true;er.setAttribute('role','alert');dlg.appendChild(er);
        var ft=el2('div','od-ft'),st=el2('div','xs'),mi=el2('button',null,'−'),pl=el2('button',null,'+'),b=el2('b',null,String(m.q));
        mi.type=pl.type='button';mi.setAttribute('aria-label','Menos');pl.setAttribute('aria-label','Mais');
        mi.addEventListener('click',function(){m.q=Math.max(1,m.q-1);pinta2();});pl.addEventListener('click',function(){m.q=Math.min(QMAX,m.q+1);pinta2();});
        st.appendChild(mi);st.appendChild(b);st.appendChild(pl);ft.appendChild(st);
        var ca=el2('button','btn btn-ghost','Cancelar');ca.type='button';ca.addEventListener('click',function(){dlg.close();});
        var ok=el2('button','btn btn-gold','Adicionar · '+brl(m.q*(+p.preco+extraUnit(m))));ok.type='button';
        ok.addEventListener('click',function(){
          var e=erroMont(m);if(e){er.textContent=e;er.hidden=false;return;}
          addLinha(p.id,m.sel,m.q);dlg.close();update();
        });
        ft.appendChild(ca);ft.appendChild(ok);dlg.appendChild(ft);
      }
      pinta2();dlg.showModal();
    }
    // ===== Banco (Supabase): grava o pedido antes de abrir o WhatsApp =====
    var SB={url:'https://elaczoriyaejkixkubxn.supabase.co',key:'sb_publishable_NscsoGdrovVNuBol72Rh3Q_ov8i8lGv'}, known=false;
    function rpc(fn,args,ms){
      var ac=window.AbortController?new AbortController():null, t=ac&&setTimeout(function(){ac.abort();},ms||7000);
      return fetch(SB.url+'/rest/v1/rpc/'+fn,{method:'POST',headers:{apikey:SB.key,'Content-Type':'application/json'},body:JSON.stringify(args),signal:ac?ac.signal:undefined})
        .then(function(r){clearTimeout(t);if(!r.ok)throw new Error('http'+r.status);return r.json();},function(e){clearTimeout(t);throw e;});
    }
    function post(path,body,ms){
      var ac=window.AbortController?new AbortController():null, t=ac&&setTimeout(function(){ac.abort();},ms||7000);
      return fetch(SB.url+path,{method:'POST',headers:{apikey:SB.key,'Content-Type':'application/json'},body:JSON.stringify(body),signal:ac?ac.signal:undefined})
        .then(function(r){clearTimeout(t);if(!r.ok)throw new Error('http'+r.status);return r.json();},function(e){clearTimeout(t);throw e;});
    }
    // ===== Pix online (só aparece quando o gateway está ligado no painel; senão segue o fluxo do WhatsApp) =====
    function mostraPix(codigo,zap){
      return rpc('pagamento_publico',{p_codigo:codigo,p_whatsapp:zap,p_criar:true},9000).then(function(r){
        if(!r||!r.disponivel||!r.pix_copia_cola)return false;
        var d=document.getElementById('pixDlg');
        d.querySelector('[data-pix=cod]').textContent=codigo;
        d.querySelector('[data-pix=valor]').textContent=brl(+r.valor);
        d.querySelector('[data-pix=chave]').value=r.pix_copia_cola;
        d.querySelector('[data-pix=teste]').hidden=!r.teste;
        var img=d.querySelector('[data-pix=qr]');if(r.pix_qr){img.src='data:image/png;base64,'+r.pix_qr;img.hidden=false;}else img.hidden=true;
        var st=d.querySelector('[data-pix=status]');st.textContent='Aguardando o pagamento…';
        if(!d.open){if(d.showModal)d.showModal();else d.setAttribute('open','');}
        var n=0,t=setInterval(function(){
          if(!d.open||++n>180){clearInterval(t);return;}
          rpc('pagamento_publico',{p_codigo:codigo,p_whatsapp:zap,p_criar:false},6000).then(function(x){
            if(!x)return;
            if(x.status==='aprovado'){clearInterval(t);st.textContent='Pagamento confirmado! 💜 Seu pedido já está na produção.';st.className='pix-ok';}
            else if(x.status==='expirado'||x.status==='recusado'){clearInterval(t);st.textContent='Esse Pix expirou. Fale com a gente no WhatsApp para gerar outro.';}
          }).catch(function(){});
        },5000);
        return true;
      }).catch(function(){return false;});
    }
    // ===== Pix com o valor do pedido (BR Code estático com a chave da loja), quando não há gateway ligado =====
    function emv(id,v){v=String(v);return id+('0'+v.length).slice(-2)+v;}
    function crc16(s){var c=0xFFFF,i,k;for(i=0;i<s.length;i++){c^=s.charCodeAt(i)<<8;for(k=0;k<8;k++)c=(c&0x8000)?((c<<1)^0x1021)&0xFFFF:(c<<1)&0xFFFF;}return ('000'+c.toString(16).toUpperCase()).slice(-4);}
    function asc(t,n){return String(t||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/[^A-Za-z0-9 ]/g,'').toUpperCase().trim().slice(0,n);}
    function pixPayload(p,valor,txid){
      var s=emv('00','01')+emv('01','11')+emv('26',emv('00','br.gov.bcb.pix')+emv('01',p.chave))+emv('52','0000')+emv('53','986')+emv('54',valor.toFixed(2))+emv('58','BR')+emv('59',asc(p.nome,25)||'LOJA')+emv('60',asc(p.cidade,15)||'BRASIL')+emv('62',emv('05',asc(txid,25).replace(/ /g,'')||'***'))+'6304';
      return s+crc16(s);
    }
    // QR Code do Pix: biblioteca local (vendor/qrcode.js, MIT), carregada só quando precisa
    function qrImg(img,texto){
      function go(){try{var q=window.qrcode(0,'M');q.addData(texto);q.make();img.src='data:image/svg+xml;utf8,'+encodeURIComponent(q.createSvgTag({cellSize:4,margin:4,scalable:true}));img.hidden=false;}catch(e){img.hidden=true;}}
      if(window.qrcode){go();return;}
      var s=document.createElement('script');s.src='vendor/qrcode.js?v=1';s.onload=go;document.head.appendChild(s);
    }
    function pixEstatico(code,tot){
      var box=document.getElementById('confPix'); if(!box||!code||!(tot>0))return;
      rpc('obter_pix_publico',{},7000).then(function(p){
        if(!p||!p.chave)return;
        var s=pixPayload(p,+tot,code.replace(/[^A-Za-z0-9]/g,''));
        document.getElementById('confPixVal').textContent=brl(tot);
        var ta=document.getElementById('confPixCod'); ta.value=s; qrImg(document.getElementById('confPixQr'),s);
        document.getElementById('confPixCp').onclick=function(){var b=this;(navigator.clipboard?navigator.clipboard.writeText(s):Promise.reject()).then(function(){b.textContent='Código copiado! Cole no app do banco';},function(){ta.select();b.textContent='Selecione e copie o código';});};
        box.hidden=false;
      }).catch(function(){});
    }
    (function(){var d=document.getElementById('pixDlg');if(!d)return;
      d.querySelector('[data-pix=fechar]').addEventListener('click',function(){d.close();});
      d.querySelector('[data-pix=copiar]').addEventListener('click',function(){var i=d.querySelector('[data-pix=chave]');i.select();
        (navigator.clipboard?navigator.clipboard.writeText(i.value):Promise.reject()).then(function(){d.querySelector('[data-pix=status]').textContent='Pix copiado! Cole no app do seu banco.';},function(){try{document.execCommand('copy');}catch(e){}});});
    })();
    // ===== Proteção contra robôs (Cloudflare Turnstile), carregada só quando a pessoa começa a preencher =====
    var tsToken=null, tsId=null, tsLoading=false, tsBox=document.getElementById('tsBox');
    function tsRender(){
      if(tsId!==null||!window.turnstile)return;
      tsId=turnstile.render(tsBox,{sitekey:window.TQR_TURNSTILE,language:'pt-br',theme:'dark',
        callback:function(t){tsToken=t;},'expired-callback':function(){tsToken=null;},'error-callback':function(){tsToken=null;}});
    }
    function tsLoad(){
      if(!window.TQR_TURNSTILE||tsLoading)return; tsLoading=true;
      var sc=document.createElement('script');sc.src='https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit';sc.async=true;sc.onload=tsRender;document.head.appendChild(sc);
    }
    function resetTs(){tsToken=null;try{if(tsId!==null)turnstile.reset(tsId);}catch(e){}}
    f.addEventListener('focusin',tsLoad,{once:true});
    // Vitrine: produtos e promoções vêm do banco (painel). O total oficial é sempre o de simular_pedido/criar_pedido_v2;
    // os valores padrão no código servem só de prévia se o servidor não responder.
    function so(v){return Number(v)%1===0?String(Number(v)):Number(v).toFixed(2).replace('.',',');}
    function imgOk(u){return typeof u==='string'&&(/^img\/[\w.\-\/]+$/.test(u)||/^https:\/\/[^\s"'<>]+$/.test(u));}
    function mk(tag,cls,txt){var e=document.createElement(tag);if(cls)e.className=cls;if(txt!=null)e.textContent=txt;return e;}
    function cardOferta(o){
      var d=mk('div','plan rv in'+(o.destaque?' best':''));
      if(o.rotulo)d.appendChild(mk('span','ribbon',o.rotulo));
      var pi=mk('div','pimg cover'),im=document.createElement('img');im.src=imgOk(o.img)?o.img:'img/hf-hero.webp';im.alt=o.titulo;im.loading='lazy';pi.appendChild(im);d.appendChild(pi);
      d.appendChild(mk('h3',null,o.titulo));d.appendChild(mk('div','qty',o.qtd));
      var v=mk('div','val');if(o.prefixo){v.appendChild(mk('small',null,o.prefixo));}v.appendChild(document.createTextNode(o.valor));if(o.sufixo){var sf=mk('small',null,o.sufixo);sf.style.cssText='font-size:.9rem;margin-left:4px';v.appendChild(sf);}d.appendChild(v);
      var u=mk('div','unit');if(o.unidade)u.appendChild(document.createTextNode(o.unidade));
      if(o.frete){if(o.unidade)u.appendChild(document.createTextNode(' '));u.appendChild(document.createTextNode('+ '));u.appendChild(mk('b',null,'entrega grátis'));}
      if(o.economia){u.appendChild(document.createElement('br'));u.appendChild(mk('span','save',o.economia));}
      d.appendChild(u);
      if(o.notas&&o.notas.length){var ul=mk('ul');o.notas.forEach(function(n){ul.appendChild(mk('li',null,n));});d.appendChild(ul);}
      var a=mk('a','btn '+(o.destaque?'btn-gold':'btn-ghost'),o.cta);a.href='#pedido';
      a.addEventListener('click',function(){window.TQR_pedir(o.qtdSug,o.itensKit);});d.appendChild(a);
      return d;
    }
    function ofertasDe(V){
      var porId={};V.produtos.forEach(function(p){porId[p.id]=p;});
      var out=[];
      V.produtos.forEach(function(p,i){
        out.push({titulo:p.nome,qtd:'1 unidade'+(p.volume_ml?' de '+p.volume_ml+' ml':''),valor:so(p.preco),prefixo:'R$',unidade:p.descricao||'',
          img:p.foto_url||(i===0?'img/hf-hero.webp':''),cta:'Pedir 1',qtdSug:1,itensKit:i===0?null:[{produto_id:p.id,qtd:1}],notas:i===0?['Pedido mínimo de 1 garrafa','Delivery ou retirada']:[]});
      });
      V.promocoes.forEach(function(x){
        var r=x.regra||{},o={titulo:x.titulo||x.nome,qtd:x.qtd_label||'',rotulo:x.rotulo,notas:x.notas||[],img:x.imagem_url,cta:x.cta||'Pedir agora',qtdSug:x.qtd_sugerida||1,destaque:x.destaque,frete:x.frete_gratis,prefixo:'R$'};
        if(x.tipo==='combo'){
          var qt=0,base=0;(r.itens||[]).forEach(function(it){qt+=it.qtd;base+=it.qtd*((porId[it.produto_id]||{}).preco||0);});
          o.valor=so(r.preco);o.unidade=qt?rs(r.preco/qt)+' cada':'';o.economia=base>r.preco?'Economize '+brl(base-r.preco):'';
          o.itensKit=r.itens;o.qtdSug=qt||o.qtdSug;if(!o.qtd)o.qtd=qt+' unidades';
        }else if(x.tipo==='faixa_quantidade'){
          o.valor=so(r.preco_unit);o.sufixo='/cada';o.economia=r.min+' garrafas por '+rs(r.min*r.preco_unit);o.qtdSug=r.min;if(!o.qtd)o.qtd='a partir de '+r.min+' unidades';
        }else if(x.tipo==='leve_pague'){o.prefixo='';o.valor='Leve '+r.leve+', pague '+r.pague;
        }else if(x.tipo==='casadinha'){o.prefixo='';o.valor=so(r.desconto_percentual)+'% off';o.unidade='na segunda unidade da casadinha';
        }else if(x.tipo==='desconto_percentual'){o.prefixo='';o.valor=so(r.percentual)+'%';o.sufixo='de desconto';
        }else if(x.tipo==='desconto_valor'){o.valor=so(r.valor);o.sufixo='de desconto';
        }else if(x.tipo==='frete_gratis'){o.prefixo='';o.valor='Frete grátis';o.frete=false;
        }else if(x.tipo==='brinde'){o.prefixo='';o.valor='Ganhe brinde';
          var pb=porId[r.produto_id];o.unidade=pb?r.qtd+'× '+pb.nome:'';}
        out.push(o);
      });
      return out;
    }
    function aplicaVitrine(V){
      if(!V||!V.produtos||!V.produtos.length){aplicaPendente();return;}
      PRODS=V.produtos.map(function(p){return {id:p.id,nome:p.nome,preco:+p.preco,descricao:p.descricao,foto_url:p.foto_url,volume_ml:p.volume_ml,categoria_id:p.categoria_id};});
      MAIN=PRODS[0];UN=MAIN.preco;COMBO=null;FAIXA=null;
      V.promocoes.forEach(function(x){
        var r=x.regra||{};
        if(x.tipo==='combo'&&r.itens&&r.itens.length===1&&r.itens[0].produto_id===MAIN.id){var c={q:r.itens[0].qtd,preco:+r.preco};if(!COMBO||c.preco/c.q<COMBO.preco/COMBO.q)COMBO=c;}
        if(x.tipo==='faixa_quantidade'&&r.produto_id===MAIN.id){var fx={min:+r.min,preco:+r.preco_unit,frete:!!x.frete_gratis};if(!FAIXA||fx.preco<FAIXA.preco)FAIXA=fx;}
      });
      var plans=document.querySelector('#ofertas .plans');
      if(plans){plans.textContent='';ofertasDe(V).forEach(function(o){plans.appendChild(cardOferta(o));});}
      var ch=f.querySelectorAll('.qchips button');
      if(ch.length>=3){
        ch[1].hidden=!COMBO;if(COMBO){ch[1].dataset.set=COMBO.q;ch[1].textContent='Combo '+COMBO.q;}
        ch[2].hidden=!FAIXA;if(FAIXA){ch[2].dataset.set=FAIXA.min;ch[2].textContent=FAIXA.min+'+';}
      }
      var qt=document.querySelector('.q-head .q-tab');
      if(qt){qt.textContent=rs(UN)+' cada';if(COMBO){var bb=document.createElement('b');bb.textContent=COMBO.q+' por '+rs(COMBO.preco);qt.appendChild(document.createTextNode(' · '));qt.appendChild(bb);}}
      var mb=document.querySelector('.mbar .p b');
      if(mb&&!mb.parentNode.dataset.fixo){var mn=UN;if(COMBO)mn=Math.min(mn,COMBO.preco/COMBO.q);if(FAIXA)mn=Math.min(mn,FAIXA.preco);mb.textContent=rs(mn);}
      GRUPOS=(V.personalizacao||[]).filter(function(g){return g.opcoes&&g.opcoes.length;});MONT=[];renderMont();
      VIT=V;montaCardapio();
      renderPacks();renderExtras();update();aplicaPendente();
    }
    rpc('obter_vitrine',{},6000).then(aplicaVitrine).catch(function(){aplicaPendente();});
    // Configuração do painel: WhatsApp, aviso, horário, pagamento, contador e limites. Se a leitura falhar, vale o que está no HTML.
    function emojiPag(id){return id==='pix'?'💠':(id==='cartao'?'💳':'💵');}
    function fmtH(x){return x.replace(/^0/,'').replace(':00','h').replace(':','h');}
    function dentroDoHorario(a,b){
      var p=new Intl.DateTimeFormat('en-GB',{timeZone:'America/Fortaleza',hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).formatToParts(new Date()), h=+p[0].value*60+ +p[2].value;
      function m(x){var t=x.split(':');return +t[0]*60+ +t[1];}
      var ini=m(a),fim=m(b);
      return ini<=fim?(h>=ini&&h<fim):(h>=ini||h<fim);
    }
    rpc('obter_config_publica',{},5000).then(function(c){
      if(!c||typeof c!=='object')return;
      window.TQR_CFG=c;try{document.dispatchEvent(new CustomEvent('tqr:config',{detail:c}));}catch(e){}
      if(/^55\d{10,11}$/.test(c.whatsapp||'')){window.TQR_FONE=c.whatsapp;if(window.TQR_relink)window.TQR_relink();}
      if(c.aviso){var av=document.createElement('div');av.className='aviso';av.setAttribute('role','status');av.textContent=c.aviso;document.body.insertBefore(av,document.body.firstChild);}
      var ct=document.getElementById('statCount');
      if(ct&&c.contador>0){ct.textContent='+'+Number(c.contador).toLocaleString('pt-BR');}
      if(c.pedido_min>0&&c.pedido_max>=c.pedido_min){QMIN=c.pedido_min;QMAX=c.pedido_max;qty.min=QMIN;qty.max=QMAX;var qq0=document.getElementById('qQty');if(qq0){qq0.min=QMIN;qq0.max=QMAX;}}
      if(c.formas_pagamento&&c.formas_pagamento.length){
        var box=f.querySelector('.opts input[name=pag]').closest('.opts'); box.textContent='';
        c.formas_pagamento.forEach(function(fp,i){
          var l=document.createElement('label'),r=document.createElement('input'),sp=document.createElement('span');
          l.className='opt';r.type='radio';r.name='pag';r.value=fp.id;r.dataset.nome=fp.nome;r.checked=(i===0);
          sp.textContent=emojiPag(fp.id)+' '+fp.nome;l.appendChild(r);l.appendChild(sp);box.appendChild(l);
        });
      }
      if(c.horario_abre&&c.horario_fecha&&!dentroDoHorario(c.horario_abre,c.horario_fecha)){
        var hn=document.getElementById('horaNote');
        hn.textContent='Agora estamos fora do horário de atendimento ('+fmtH(c.horario_abre)+' às '+fmtH(c.horario_fecha)+'). Pode enviar o pedido; respondemos assim que abrirmos.';hn.hidden=false;
      }
      CARRINHO=c.modo_cardapio==='carrinho';f.classList.toggle('modo-carrinho',CARRINHO);
      try{localStorage.setItem('tqr_modo',CARRINHO?'carrinho':'garrafa');}catch(e){}
      montaCardapio();
      BAIRROS=c.bairros||[];
      var bs=document.getElementById('bairroSel'),bfl=document.getElementById('bairroSelFld');
      if(BAIRROS.length){
        bs.textContent='';
        var o0=document.createElement('option');o0.value='';o0.textContent='Escolha o bairro';bs.appendChild(o0);
        BAIRROS.forEach(function(b){var o=document.createElement('option');o.value=b.id;o.dataset.nome=b.nome;o.textContent=b.nome+(+b.taxa>0?' — '+brl(+b.taxa):' — grátis');bs.appendChild(o);});
        var oo=document.createElement('option');oo.value='outro';oo.textContent='Outro bairro (entrega por aplicativo)';bs.appendChild(oo);
        bfl.hidden=false;
        try{var sv2=JSON.parse(localStorage.getItem(KEY)||'{}');if(sv2.bs&&bs.querySelector('option[value="'+sv2.bs+'"]'))bs.value=sv2.bs;}catch(e){}
      }else{bfl.hidden=true;}
      update(); if(typeof qset==='function')qset(qq.value);
    }).catch(function(){});
    var wf=f.elements.whats, nomeFld=document.getElementById('nomeFld'), waNote=document.getElementById('waNote'), loyal=document.getElementById('loyalBox'), tmr;
    function digits(){return wf.value.replace(/\D/g,'');}
    // ===== Endereços salvos (exigem confirmar o número com um código enviado pelo WhatsApp) =====
    var SESS=null;
    (function(){var d=window.TQR_DEV.get();if(d)SESS={w:d.w,t:d.t};})();
    function msgEnd(t){var m=document.getElementById('endMsg');m.textContent=t||'';m.hidden=!t;}
    function guardaSess(){if(SESS)window.TQR_DEV.set(SESS.w,SESS.t,90);else window.TQR_DEV.clear();}
    function sessOk(){return !!(SESS&&String(SESS.w).replace(/^55/,'')===digits().replace(/^55/,''));}
    function preencheEnd(e){
      f.elements.rua.value=e.rua||''; f.elements.comp.value=e.complemento||''; f.elements.ref.value=e.referencia||'';
      var bs=document.getElementById('bairroSel');
      if(BAIRROS.length){
        if(e.bairro_id&&bs.querySelector('option[value="'+e.bairro_id+'"]')){bs.value=e.bairro_id;}
        else{bs.value='outro';f.elements.bairro.value=e.bairro||'';}
      }else{f.elements.bairro.value=e.bairro||'';}
      f.elements.rua.dispatchEvent(new Event('input'));update();
    }
    function listaEnd(){
      var box=document.getElementById('endLista');
      rpc('listar_enderecos',{p_whatsapp:digits(),p_token:SESS.t},6000).then(function(arr){
        box.textContent='';box.hidden=false;msgEnd(arr.length?'':'Você ainda não tem endereços salvos. Preencha abaixo e marque para salvar.');
        arr.forEach(function(e){
          var r=document.createElement('div'),t=document.createElement('span'),sm=document.createElement('small'),ac=document.createElement('div'),u=document.createElement('button'),x=document.createElement('button');
          r.className='endrow';t.textContent=(e.apelido?e.apelido+' · ':'')+e.rua;sm.textContent=e.bairro+(e.complemento?' · '+e.complemento:'');t.appendChild(sm);
          ac.className='ea';u.type=x.type='button';u.textContent='Usar';x.textContent='Apagar';x.className='x';x.setAttribute('aria-label','Apagar endereço '+e.rua);
          u.addEventListener('click',function(){preencheEnd(e);});
          x.addEventListener('click',function(){if(!window.confirm('Apagar este endereço salvo?'))return;rpc('apagar_endereco',{p_whatsapp:digits(),p_token:SESS.t,p_id:e.id},6000).then(listaEnd).catch(function(){msgEnd('Não consegui apagar agora.');});});
          ac.appendChild(u);ac.appendChild(x);r.appendChild(t);r.appendChild(ac);box.appendChild(r);
        });
        document.getElementById('salvarEndFld').hidden=false;
      }).catch(function(){SESS=null;guardaSess();document.getElementById('endLista').hidden=true;msgEnd('Este aparelho não está mais reconhecido. Informe o código de acesso de um pedido seu.');});
    }
    document.getElementById('btnEnd').addEventListener('click',function(){
      if(sessOk()){listaEnd();return;}
      document.getElementById('endCod').hidden=false;msgEnd('');document.getElementById('endCodIn').focus();
    });
    document.getElementById('endCodOk').addEventListener('click',function(){
      var c=(document.getElementById('endCodIn').value||'').trim(); if(c.replace(/[^A-Za-z0-9]/g,'').length<8){msgEnd('Digite o código de acesso completo (ex.: '+PFX+'-0027-K7F2).');return;}
      rpc('entrar_com_codigo',{p_whatsapp:digits(),p_acesso:c},6000).then(function(tok){
        if(!tok){msgEnd('Código de acesso incorreto. Confira no seu pedido anterior. Depois de várias tentativas erradas é preciso esperar um pouco.');return;}
        SESS={w:digits(),t:tok};guardaSess();document.getElementById('endCod').hidden=true;document.getElementById('endCodIn').value='';msgEnd('');listaEnd();
      }).catch(function(){msgEnd('Não consegui confirmar agora. Confira o código e tente de novo; após várias tentativas erradas é preciso esperar um pouco.');});
    });
    function salvarEnderecoSeQuiser(){
      if(!sessOk()||!f.elements.rua.value.trim()||document.getElementById('salvarEndFld').hidden||!document.getElementById('salvarEnd').checked||tipo()!=='entrega')return;
      var bn=bairroNome(); if(!bn)return;
      rpc('salvar_endereco',{p_whatsapp:digits(),p_token:SESS.t,p_rua:f.elements.rua.value.trim(),p_bairro:bn,p_complemento:f.elements.comp.value.trim()||null,
        p_referencia:f.elements.ref.value.trim()||null,p_bairro_id:bairroId()},6000).catch(function(){});
    }
    function setKnown(k){known=k;document.getElementById('endBox').hidden=!k;if(!k||!sessOk()){document.getElementById('endLista').hidden=true;document.getElementById('salvarEndFld').hidden=true;}if(k&&sessOk())listaEnd();nomeFld.hidden=k;f.elements.nome.required=!k;waNote.hidden=!k;waNote.textContent=k?'Cadastro encontrado. Não precisa informar o nome.':'';loyal.hidden=k;}
    wf.addEventListener('input',function(){
      clearTimeout(tmr);var d=digits();setKnown(false);
      if(d.length>=10)tmr=setTimeout(function(){rpc('cliente_cadastrado',{p_whatsapp:d},4000).then(function(r){if(digits()===d)setKnown(r===true);}).catch(function(){});},500);
    });
    // lembrar dados do cliente neste aparelho
    var KEY='tqr_cliente';
    try{var sv=JSON.parse(localStorage.getItem(KEY)||'{}');if(sv.nome){f.elements.lembrar.checked=true;}['whats','nome','rua','bairro','comp','ref'].forEach(function(k){if(sv[k])f.elements[k].value=sv[k];});if(f.elements.whats.value)f.elements.whats.dispatchEvent(new Event('input'));}catch(e){}
    f.elements.lembrar.addEventListener('change',function(){if(!this.checked){try{localStorage.removeItem(KEY);}catch(e){}}});
    function clearErr(el){var w=el.closest('.fld');if(!w)return;w.classList.remove('err');var m=w.querySelector('.msg');if(m)m.remove();var ip=w.querySelector('input,select');if(ip){ip.removeAttribute('aria-invalid');ip.removeAttribute('aria-describedby');}}
    var errSeq=0;new MutationObserver(function(ms){ms.forEach(function(r){r.addedNodes.forEach(function(n){if(n.nodeType===1&&n.classList&&n.classList.contains('msg')){var w=n.closest('.fld'),ip=w&&w.querySelector('input,select');if(ip){n.id='err'+(++errSeq);n.setAttribute('role','alert');ip.setAttribute('aria-invalid','true');ip.setAttribute('aria-describedby',n.id);}}});});}).observe(f,{childList:true,subtree:true});
    f.querySelectorAll('.fld input').forEach(function(i){i.addEventListener('input',function(){clearErr(i);});});
    // ===== Etapas do pedido (abas): 1 Pedido, 2 Entrega e dados, 3 Pagamento. Sem JS tudo aparece de uma vez. =====
    var PS=document.getElementById('pSteps'), PN=[1,2,3].map(function(n){return document.getElementById('pnl'+n);}), PT=[1,2,3].map(function(n){return document.getElementById('stp'+n);}), passo=0, cbBtn=document.querySelector('#cartBar a');
    function obrig(scope){var first=null;scope.querySelectorAll('input[required],select[required]').forEach(function(i){clearErr(i);if(!i.value.trim()){var w=i.closest('.fld');w.classList.add('err');var m=document.createElement('span');m.className='msg';m.textContent=i.tagName==='SELECT'?'Escolha uma opção':'Preencha este campo';w.appendChild(m);first=first||i;}});return first;}
    function errDados(){
      var dg=digits();
      if(dg.length<10||dg.length>13){var ww=wf.closest('.fld');ww.classList.add('err');var mm=document.createElement('span');mm.className='msg';mm.textContent='Informe o DDD e o número';ww.appendChild(mm);return wf;}
      if(!known&&f.elements.nome.value.trim().length<3){var nw=f.elements.nome.closest('.fld');nw.classList.add('err');var nmm=document.createElement('span');nmm.className='msg';nmm.textContent='Informe seu nome';nw.appendChild(nmm);return f.elements.nome;}
      return null;
    }
    function mostraPasso(n,rola){
      if(!PS||PS.hidden)return;
      passo=n;f.classList.add('tabs-on');
      PN.forEach(function(p,i){p.hidden=i!==n;});
      PT.forEach(function(t,i){t.setAttribute('aria-selected',i===n?'true':'false');t.tabIndex=i===n?0:-1;t.classList.toggle('on',i===n);t.classList.toggle('done',i<n);});
      if(cbBtn)cbBtn.innerHTML=(n<2?'Continuar':'Finalizar')+' <span aria-hidden="true">→</span>';
      if(rola)PS.scrollIntoView({block:'start'});
    }
    function ir(el){var p=el&&el.closest&&el.closest('.p-panel');if(p&&PS&&!PS.hidden)mostraPasso(PN.indexOf(p));}
    function proximo(){
      if(passo===0){
        if(CARRINHO&&!unidades()){var ch=document.getElementById('cardHint');ch.textContent='Adicione ao menos um item ao pedido.';ch.hidden=false;return;}
        var em=montErro();if(em){var hh=document.getElementById('qtyHint');hh.textContent=em;return;}
        mostraPasso(1,true);
      }else if(passo===1){
        var bad=obrig(PN[1])||errDados();if(bad){bad.focus();return;}
        mostraPasso(2,true);
      }
    }
    if(PS&&PN.every(Boolean)){
      PS.hidden=false;
      PT.forEach(function(t,i){
        t.addEventListener('click',function(){if(i>passo){var k=passo;while(k<i&&passo===k){proximo();k++;}}else mostraPasso(i,true);});
        t.addEventListener('keydown',function(e){var d=e.key==='ArrowRight'?1:e.key==='ArrowLeft'?-1:0;if(!d)return;var j=(i+d+3)%3;mostraPasso(j);PT[j].focus();e.preventDefault();});
      });
      f.addEventListener('click',function(e){var b=e.target.closest&&e.target.closest('[data-next],[data-prev]');if(!b)return;if(b.hasAttribute('data-next'))proximo();else mostraPasso(passo-1,true);});
      if(cbBtn)cbBtn.addEventListener('click',function(e){if(passo<2){e.preventDefault();proximo();}});
      mostraPasso(0);
    }
    f.addEventListener('submit',function(e){
      e.preventDefault(); var c=update(), ok=true, first=null;
      first=obrig(f);ok=!first;
      if(!ok){ir(first);first.focus();return;}
      var v=function(k){return (f.elements[k].value||'').trim();}, q=CARRINHO?unidades():+qty.value, mod=modalidade(), ent=mod!=='retirada';
      if(CARRINHO&&!q){var ch=document.getElementById('cardHint');ch.textContent='Adicione ao menos um item ao pedido.';ch.hidden=false;ir(ch);ch.scrollIntoView({block:'center'});return;}
      try{if(f.elements.lembrar.checked){localStorage.setItem(KEY,JSON.stringify({whats:v('whats'),nome:known?(JSON.parse(localStorage.getItem(KEY)||'{}').nome||''):v('nome'),rua:v('rua'),bairro:v('bairro'),comp:v('comp'),ref:v('ref'),bs:bsel()}));}else{localStorage.removeItem(KEY);}}catch(e){}
      var em=montErro();if(em){var hh=document.getElementById('qtyHint');hh.textContent=em;ir(hh);hh.scrollIntoView({block:'center'});return;}
      var dg=digits(), nm=known?'':v('nome');
      var bad=errDados();if(bad){ir(bad);bad.focus();return;}
      var pagi=f.querySelector('input[name=pag]:checked'), pagv=pagi.value, pagn=pagi.dataset.nome||pagi.value, btn=f.querySelector('button[type=submit]'), lbl=btn.innerHTML;
      btn.disabled=true; btn.textContent='Registrando pedido…';
      var it=itens(), bn=bairroNome();
      // 1) pega o total oficial do servidor; 2) grava o pedido; 3) abre o WhatsApp. Se algo falhar, o WhatsApp abre do mesmo jeito.
      simular().then(function(S){
        function go(code,r){
          // total oficial: o da criação do pedido; os detalhes vêm da simulação (só se os dois batem)
          var T=(S&&(!r||r.total==null||Math.abs(+r.total-+S.total)<0.01))?S:null;
          var tot=r&&r.total!=null?+r.total:(T?+T.total:c.total), L=[br('Olá, TQR Açaí! 💜 Quero fazer um pedido pelo site:'),''];
          if(code){L.push('🔖 *Pedido:* '+code);L.push('🔎 *Acompanhe:* '+location.origin+location.pathname+'?acompanhar='+code);}
          var itensTxt=T&&T.itens?T.itens.map(function(l){return '• '+l.quantidade+'× '+l.nome;}):linhasTexto().map(function(t){return '• '+t;});
          L.push('🥤 *Itens:*'); itensTxt.forEach(function(t){L.push(t);});
          var mtx=T?montTexto(T):[];if(mtx.length){L.push('✨ *Montagem:*');mtx.forEach(function(t){L.push('• '+t);});}
          if(T&&T.brindes&&T.brindes.length)T.brindes.forEach(function(b){L.push('🎁 '+b.quantidade+'× '+b.nome+' (brinde)');});
          var promoNome=r&&r.pedido_promocao?r.pedido_promocao:(T&&T.promocao?T.promocao.nome:'');
          if(promoNome)L.push('🏷️ *Promoção:* '+promoNome);
          if(T&&T.cupom_status==='aplicado'&&T.promocao&&T.promocao.codigo)L.push('🎟️ *Cupom:* '+T.promocao.codigo);
          var det=T&&(+T.desconto>0||+T.taxa_entrega>0||+T.extras>0)?' (itens '+brl(T.subtotal)+(+T.extras>0?' + adicionais '+brl(T.extras):'')+(+T.desconto>0?' − desconto '+brl(T.desconto):'')+(+T.taxa_entrega>0?' + entrega '+brl(T.taxa_entrega):'')+')':'';
          L.push('💰 *Total:* '+brl(tot)+det);
          if(mod==='retirada')L.push('🏠 *Retirada*');
          else if(mod==='entrega_bairro')L.push('🛵 *Entrega* – '+bn+(T&&T.frete_gratis?' (grátis)':(T&&+T.taxa_entrega>0?' (taxa '+brl(T.taxa_entrega)+')':'')));
          else L.push('🛵 *Entrega por aplicativo*'+(T&&T.frete_gratis?' (grátis)':' (taxa do app)'));
          L.push('📱 *WhatsApp:* '+v('whats'));
          if(nm)L.push('👤 *Nome:* '+nm);
          if(ent){L.push('📍 *Endereço:* '+v('rua')+(v('comp')?', '+v('comp'):'')+' – '+bn);if(v('ref'))L.push('🧭 *Referência:* '+v('ref'));}
          L.push('💳 *Pagamento:* '+pagn);
          if(v('obs'))L.push('📝 *Obs.:* '+v('obs'));
          var url='https://wa.me/'+window.TQR_FONE+'?text='+encodeURIComponent(L.join('\n'));
          var pp={quantidade:q,valor:tot,tipo:ent?'entrega':'retirada'};
          try{window.dataLayer=window.dataLayer||[];dataLayer.push(Object.assign({event:'pedido_formulario'},pp));}catch(e){}
          try{if(window.gtag)gtag('event','pedido_formulario',pp);}catch(e){}
          try{if(window.fbq)fbq('track','Lead',{value:tot,currency:'BRL'});}catch(e){}
          btn.disabled=false; btn.innerHTML=lbl;
          var gwPix=(code&&pagv==='pix'&&!window.__semPix)?mostraPix(code,dg):Promise.resolve(false);
          if(code&&pagv==='pix'&&mod!=='entrega_app')gwPix.then(function(g){if(!g)pixEstatico(code,tot);});
          mostraConf({code:code,zap:dg,tot:tot,url:url,itens:itensTxt.concat(mtx.map(function(t){return '✨ '+t;})),ent:ent,bn:bn,pagn:pagn});
          var w=window.open(url,'_blank'); if(w){try{w.opener=null;}catch(e){}}
        }
        var obs=[ent?'':'Retirada',ent&&v('ref')?'Ref.: '+v('ref'):'',v('obs')].filter(Boolean).join(' | ')||null;
        var args=it?{
          p_whatsapp:dg,p_itens:it,p_nome:nm||null,
          p_data_nascimento:known?null:(v('nasc')||null),p_email:known?null:(v('email')||null),
          p_aceite_lgpd:true,p_forma_pagamento:pagv,
          p_endereco:ent?(v('rua')+(v('comp')?', '+v('comp'):'')):null,
          p_bairro:mod==='entrega_app'?v('bairro'):null,p_bairro_id:bairroId(),p_modalidade:mod,
          p_cupom:cupomVal()||null,p_observacao:obs,
          p_montagens:GRUPOS.length?montagens():undefined
        }:{   // sem vitrine (servidor antigo/indisponível): pedido simples só com a quantidade
          p_whatsapp:dg,p_quantidade:q,p_nome:nm||null,
          p_data_nascimento:known?null:(v('nasc')||null),p_email:known?null:(v('email')||null),
          p_aceite_lgpd:true,p_forma_pagamento:pagv,
          p_endereco:ent?(v('rua')+(v('comp')?', '+v('comp'):'')):null,p_bairro:ent?bn:null,p_observacao:obs
        };
        // Robô preencheu o campo-isca: não grava nada. Quem é gente nunca vê esse campo.
        if(f.elements.site_url.value){go(null);return;}
        // Com Turnstile ligado, só grava com token válido. Sem token (bloqueador, falha de rede) o WhatsApp abre
        // do mesmo jeito, sem código: a venda nunca se perde.
        var req=window.TQR_TURNSTILE
          ? (tsToken?post('/functions/v1/criar-pedido',{token:tsToken,versao:it?(GRUPOS.length?3:2):1,args:args},9000):Promise.reject(new Error('sem_token')))
          : rpc(it?(GRUPOS.length?'criar_pedido_v3':'criar_pedido_v2'):'criar_pedido',args);
        req.then(function(r){var x=r&&r[0];if(x&&x.pedido_codigo)salvarEnderecoSeQuiser();go(x&&x.pedido_codigo,x?{total:+x.pedido_total,pedido_promocao:x.pedido_promocao}:null);}).catch(function(){go(null);}).then(resetTs);
      });
    });

    var qq=null,qset=null;
    renderPacks();
    update();
  })();


  // ===== PROGRAMA DE PONTOS: consulta do saldo (número confirmado por código enviado pelo WhatsApp) =====
  (function(){
    var box=document.getElementById('ptCheck'); if(!box) return;
    var SBU='https://elaczoriyaejkixkubxn.supabase.co', KEYP='sb_publishable_NscsoGdrovVNuBol72Rh3Q_ov8i8lGv';
    function rpcP(fn,args){
      var ac=window.AbortController?new AbortController():null, t=ac&&setTimeout(function(){ac.abort();},8000);
      return fetch(SBU+'/rest/v1/rpc/'+fn,{method:'POST',headers:{apikey:KEYP,'Content-Type':'application/json'},body:JSON.stringify(args),signal:ac?ac.signal:undefined})
        .then(function(r){clearTimeout(t);if(!r.ok)throw new Error('http'+r.status);return r.json();},function(e){clearTimeout(t);throw e;});
    }
    var zap=document.getElementById('ptZap'), msg=document.getElementById('ptMsg'), res=document.getElementById('ptRes'), codRow=document.getElementById('ptCodRow');
    function dg(){return zap.value.replace(/\D/g,'');}
    function say(t){msg.textContent=t||'';msg.hidden=!t;}
    function aplicaCfg(c){
      if(!c)return;
      if(c.pontos_por_real>0){var r=Number(c.pontos_por_real);document.getElementById('ptReal').textContent=(r%1?String(r).replace('.',','):r)+(r===1?' ponto':' pontos');}
      if(c.pontos_por_brinde>0)document.getElementById('ptBrinde').textContent=c.pontos_por_brinde+' pontos';
    }
    aplicaCfg(window.TQR_CFG); document.addEventListener('tqr:config',function(e){aplicaCfg(e.detail);});
    function mk(tag,cls,txt){var e=document.createElement(tag);if(cls)e.className=cls;if(txt!=null)e.textContent=txt;return e;}
    var TIPO={ganho:'Pedido pago',resgate:'Resgate',estorno:'Estorno',ajuste:'Ajuste',aniversario:'Aniversário'};
    function mostra(d){
      res.textContent='';res.hidden=false;codRow.hidden=true;say('');
      var pct=d.saldo>=d.por_brinde?100:Math.max(0,Math.round(Math.max(d.saldo,0)%d.por_brinde/d.por_brinde*100));
      // anel de progresso: traço tracejado do tamanho da volta; o vazio é puxado até a porcentagem
      var NS='http://www.w3.org/2000/svg',ring=mk('div','pt-ring'),sv=document.createElementNS(NS,'svg');
      sv.setAttribute('viewBox','0 0 120 120');sv.setAttribute('aria-hidden','true');
      var tr=document.createElementNS(NS,'circle'),pg=document.createElementNS(NS,'circle'),C=2*Math.PI*52;
      [tr,pg].forEach(function(c){c.setAttribute('cx','60');c.setAttribute('cy','60');c.setAttribute('r','52');c.setAttribute('fill','none');c.setAttribute('stroke-width','9');});
      tr.setAttribute('class','pt-ring-tr');pg.setAttribute('class','pt-ring-pg');pg.setAttribute('stroke-linecap','round');
      pg.style.strokeDasharray=C.toFixed(1);pg.style.strokeDashoffset=C.toFixed(1);
      sv.appendChild(tr);sv.appendChild(pg);ring.appendChild(sv);
      var s=mk('div','pt-saldo gold'),sn=mk('b',null,String(d.saldo)),sl=mk('small',null,' pontos');s.appendChild(sn);s.appendChild(sl);ring.appendChild(s);res.appendChild(ring);
      setTimeout(function(){pg.style.strokeDashoffset=(C*(1-pct/100)).toFixed(1);},60);
      var top=mk('div','pt-top'),info=mk('div','pt-info');
      top.appendChild(ring);
      info.appendChild(mk('p','pt-msg',d.garrafas_gratis>0?('Você tem '+d.garrafas_gratis+' '+(d.garrafas_gratis>1?UNS:UN1)+' grátis para resgatar!'):('Faltam '+d.faltam+' pontos para '+PROX+'.')));
      if(d.garrafas_gratis>0){var a=mk('a','btn btn-wa','Resgatar pelo WhatsApp');a.target='_blank';a.rel='noopener';
        a.href='https://wa.me/'+window.TQR_FONE+'?text='+encodeURIComponent(br('Olá, TQR Açaí! 💜 Quero resgatar '+RESG+' com os meus pontos.'));info.appendChild(a);}
      if(d.mes_aniversario)info.appendChild(mk('p','hint','🎂 Este é o mês do seu aniversário! Peça o seu brinde pelo WhatsApp.'));
      top.appendChild(info);res.appendChild(top);
      var hs=d.historico||[];
      if(hs.length){
        var hb=mk('div','pt-hist'),lista=mk('div','pt-list'),MAX=5;
        hb.appendChild(mk('h4',null,'Últimos movimentos'));
        hs.forEach(function(x,n){
          var row=mk('div','pt-row'+(n>=MAX?' extra':'')),p=+x.pontos;
          if(n>=MAX)row.hidden=true;
          row.appendChild(mk('span','d',new Date(x.em).toLocaleDateString('pt-BR',{day:'2-digit',month:'2-digit'})));
          row.appendChild(mk('span','l',TIPO[x.tipo]||x.tipo));
          row.appendChild(mk('b','p '+(p>=0?'mais':'menos'),(p>0?'+':'')+p));
          lista.appendChild(row);
        });
        hb.appendChild(lista);
        if(hs.length>MAX){
          var mais=mk('button','pt-mais','Ver todos os '+hs.length+' movimentos');mais.type='button';
          mais.addEventListener('click',function(){var abre=lista.classList.toggle('aberta');lista.querySelectorAll('.extra').forEach(function(r){r.hidden=!abre;});mais.textContent=abre?'Mostrar menos':'Ver todos os '+hs.length+' movimentos';});
          hb.appendChild(mais);
        }
        res.appendChild(hb);
      }
    }
    function consulta(tok){
      return rpcP('consultar_saldo',{p_whatsapp:dg(),p_token:tok}).then(mostra).catch(function(){
        window.TQR_DEV.clear();res.hidden=true;return Promise.reject();});
    }
    function pedeCodigo(){codRow.hidden=false;res.hidden=true;say('Para ver seus pontos neste aparelho, informe o código de acesso de um pedido seu (ex.: '+PFX+'-0027-K7F2). Ele aparece na confirmação do pedido. Se você ainda não pediu por este site, faça um pedido e seus pontos aparecem aqui.');document.getElementById('ptCod').focus();}
    document.getElementById('ptPedir').addEventListener('click',function(){
      if(dg().length<10){say('Informe o DDD e o número.');return;}
      var d=window.TQR_DEV.get(dg());
      if(d){say('');consulta(d.t).catch(pedeCodigo);}else pedeCodigo();
    });
    document.getElementById('ptOk').addEventListener('click',function(){
      var c=(document.getElementById('ptCod').value||'').trim(); if(c.replace(/[^A-Za-z0-9]/g,'').length<8){say('Digite o código de acesso completo (ex.: '+PFX+'-0027-K7F2).');return;}
      rpcP('entrar_com_codigo',{p_whatsapp:dg(),p_acesso:c}).then(function(tok){
        if(!tok){say('Código de acesso incorreto. Confira no seu pedido anterior. Depois de várias tentativas erradas é preciso esperar um pouco.');return;}
        window.TQR_DEV.set(dg(),tok,90);codRow.hidden=true;say('');
        consulta(tok).catch(function(){say('Não consegui consultar agora. Tente de novo.');});
      }).catch(function(){say('Não consegui confirmar agora. Confira o código e tente de novo; após várias tentativas erradas é preciso esperar um pouco.');});
    });
    // aparelho já reconhecido: os pontos aparecem sozinhos quando a seção entra na tela
    (function(){
      var d=window.TQR_DEV.get(); if(!d||!('IntersectionObserver' in window))return;
      var io2=new IntersectionObserver(function(es){es.forEach(function(e){if(!e.isIntersecting)return;io2.disconnect();
        if(!zap.value)zap.value=d.w; consulta(d.t).catch(function(){});});},{threshold:.3});
      io2.observe(box);
    })();
  })();

  // ===== CONSENTIMENTO DE COOKIES (LGPD) + carregamento do rastreamento =====
  (function(){
    var T=window.TQR_TRACKING||{}, has=!!(T.ga4||T.metaPixel), K='tqr_consent', bar=document.getElementById('cookieBar');
    function get(){try{return localStorage.getItem(K);}catch(e){return null;}}
    function load(){
      if(window.__tqrLoaded) return; window.__tqrLoaded=true;
      if(T.ga4){var g=document.createElement('script');g.async=true;g.src='https://www.googletagmanager.com/gtag/js?id='+T.ga4;document.head.appendChild(g);
        window.dataLayer=window.dataLayer||[];window.gtag=function(){dataLayer.push(arguments);};gtag('js',new Date());gtag('config',T.ga4);}
      if(T.metaPixel){!function(f,b,e,v,n,t,s){if(f.fbq)return;n=f.fbq=function(){n.callMethod?n.callMethod.apply(n,arguments):n.queue.push(arguments)};if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';n.queue=[];t=b.createElement(e);t.async=!0;t.src=v;s=b.getElementsByTagName(e)[0];s.parentNode.insertBefore(t,s)}(window,document,'script','https://connect.facebook.net/en_US/fbevents.js');fbq('init',T.metaPixel);fbq('track','PageView');}
    }
    function show(){bar.hidden=false;document.body.classList.add('cookie-on');}
    function hide(){bar.hidden=true;document.body.classList.remove('cookie-on');}
    bar.querySelectorAll('[data-consent]').forEach(function(b){b.addEventListener('click',function(){
      var c=b.dataset.consent; try{localStorage.setItem(K,c);}catch(e){}
      hide(); if(c==='todos') load(); else if(window.__tqrLoaded) location.reload();
    });});
    var pref=document.getElementById('cookiePrefs'); if(pref) pref.addEventListener('click',function(e){e.preventDefault();show();});
    var c=get(); if(c==='todos') load(); else if(!c && has) show();
  })();

  // ===== SLIDER DE PESSOAS =====
  (function(){
    var root=document.getElementById('lifeSlider'); if(!root) return;
    var track=root.querySelector('.slides'), slides=[].slice.call(track.children), dots=[].slice.call(root.querySelectorAll('.sl-dots button'));
    var bar=root.querySelector('.sl-bar i'), i=0, timer=null, DUR=4500, reduce=matchMedia('(prefers-reduced-motion: reduce)').matches, visible=false, paused=false;
    function mark(n){i=n;slides.forEach(function(s,k){s.classList.toggle('on',k===n);});dots.forEach(function(d,k){d.classList.toggle('on',k===n);d.setAttribute('aria-current',k===n?'true':'false');});}
    function go(n){n=(n+slides.length)%slides.length;track.scrollTo({left:slides[n].offsetLeft,behavior:reduce?'auto':'smooth'});mark(n);restart();}
    function restart(){clearTimeout(timer);root.classList.remove('run');void bar.offsetWidth;if(reduce||paused||!visible)return;root.classList.add('run');timer=setTimeout(function(){go(i+1);},DUR);}
    root.querySelector('.prev').addEventListener('click',function(){go(i-1);});
    root.querySelector('.next').addEventListener('click',function(){go(i+1);});
    dots.forEach(function(d,k){d.addEventListener('click',function(){go(k);});});
    track.addEventListener('keydown',function(e){if(e.key==='ArrowRight'){e.preventDefault();go(i+1);}if(e.key==='ArrowLeft'){e.preventDefault();go(i-1);}});
    var st; track.addEventListener('scroll',function(){clearTimeout(st);st=setTimeout(function(){var n=Math.round(track.scrollLeft/track.clientWidth);if(n!==i){mark(n);restart();}},120);},{passive:true});
    ['mouseenter','focusin','touchstart'].forEach(function(ev){root.addEventListener(ev,function(){paused=true;restart();},{passive:true});});
    ['mouseleave','focusout'].forEach(function(ev){root.addEventListener(ev,function(){paused=false;restart();});});
    root.addEventListener('touchend',function(){setTimeout(function(){paused=false;restart();},2500);},{passive:true});
    if('IntersectionObserver' in window){new IntersectionObserver(function(es){visible=es[0].isIntersecting;restart();},{threshold:.35}).observe(root);}else{visible=true;}
    mark(0); restart();
  })();

  // ===== Transições de entrada ao rolar =====
  (function(){
    var reduce=matchMedia('(prefers-reduced-motion: reduce)').matches;
    // [seletor, efeito, escalonar filhos?]
    var map=[
      ['main section:not(.hero) .eyebrow','up'],['main section:not(.hero) h2','up'],['main section:not(.hero) .lead','up'],
      ['.problem .split > :first-child','left'],['.problem .split > :last-child > *:not(.eyebrow):not(h2):not(.lead)','right',1],
      ['.trust .wrap > *','up',1],['.benefits > *','up',1],['.steps > *','up',1],['.tip','up'],
      ['.ingr-list > *','scale',1],['.allergen','up'],['.nutri','right'],
      ['.moments > *','up',1],['.gallery > *','scale',1],
      ['.pillars > *','blur',1],['.story-title','blur'],['.hashtag','up'],
      ['.stats > *','up',1],['.insta-head','up'],['.insta-grid > *','scale',1],
      ['.plans > *','up',1],['.pay','up'],['.order-fields > *','up',1],['.order-sum','right'],
      ['.resale-box','scale'],['.faq-list > *','up',1],
      ['.final .logo','scale'],['.final .btn','up'],['.final .micro','up']
    ];
    var els=[];
    map.forEach(function(m){
      document.querySelectorAll(m[0]).forEach(function(el){
        if(el.hasAttribute('data-anim')||el.closest('.hero')) return;
        if(innerWidth<761&&el.parentNode.classList.contains('gallery')) return; // carrossel horizontal no celular
        var t=m[1]; if(innerWidth<761&&(t==='left'||t==='right')) t='up';
        el.setAttribute('data-anim',t);
        if(m[2]){var k=Array.prototype.indexOf.call(el.parentNode.children,el);el.style.setProperty('--d',Math.min(k,6)*0.08+'s');}
        els.push(el);
      });
    });
    if(reduce||!('IntersectionObserver' in window)) return;
    var vh=window.innerHeight;
    var io=new IntersectionObserver(function(es){es.forEach(function(e){
      if(!e.isIntersecting) return; var el=e.target; io.unobserve(el); el.classList.remove('pre');
      var d=parseFloat(el.style.getPropertyValue('--d'))||0;
      setTimeout(function(){el.removeAttribute('data-anim');el.style.removeProperty('--d');},1100+d*1000);
    });},{threshold:.12,rootMargin:'0px 0px -6% 0px'});
    els.forEach(function(el){var r=el.getBoundingClientRect(); if(r.top>vh*0.92){el.classList.add('pre');io.observe(el);} else {el.removeAttribute('data-anim');}});
  })();
  // ===== Topo compacto + barra de progresso =====
  (function(){
    var top=document.getElementById('topbar'), tick=false;
    function upd(){tick=false;var h=document.documentElement.scrollHeight-innerHeight;top.style.setProperty('--p',h>0?Math.min(1,scrollY/h):0);top.classList.toggle('scrolled',scrollY>40);}
    addEventListener('scroll',function(){if(!tick){tick=true;requestAnimationFrame(upd);}},{passive:true}); upd();
  })();
  // Barra fixa no celular depois do topo
  var bar=document.getElementById('mbar'),heroCta=document.getElementById('quickBox');
  if(bar){  var formVis=false, ord=document.getElementById('pedido'); if(ord&&'IntersectionObserver' in window){new IntersectionObserver(function(es){formVis=es[0].isIntersecting;document.body.classList.toggle('form-on',formVis);}).observe(ord);}
  if('IntersectionObserver' in window&&heroCta){new IntersectionObserver(function(es){bar.classList.toggle('show',!formVis&&!es[0].isIntersecting&&es[0].boundingClientRect.top<0);}).observe(heroCta);}
  else{addEventListener('scroll',function(){bar.classList.toggle('show',scrollY>560);},{passive:true});}}
})();
