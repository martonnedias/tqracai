/* Marca do site público: nome, logo e cores vindos do painel (Personalização > Site).
   Sem nada salvo, o site mantém o visual padrão do CSS. A última marca fica guardada no aparelho para não "piscar" na abertura. */
(function(){
  var SB={url:'https://elaczoriyaejkixkubxn.supabase.co',key:'sb_publishable_NscsoGdrovVNuBol72Rh3Q_ov8i8lGv'}, K='tqr_marca_site', PADRAO='#TQR Açaí';
  var M=null;
  function hex(c){return /^#[0-9a-f]{6}$/i.test(c||'')?c.toLowerCase():null;}
  function rgb(c){return [parseInt(c.substr(1,2),16),parseInt(c.substr(3,2),16),parseInt(c.substr(5,2),16)];}
  function toHex(a){return '#'+a.map(function(v){v=Math.max(0,Math.min(255,Math.round(v)));return (v<16?'0':'')+v.toString(16);}).join('');}
  function mix(a,b,t){var x=rgb(a),y=rgb(b);return toHex([x[0]+(y[0]-x[0])*t,x[1]+(y[1]-x[1])*t,x[2]+(y[2]-x[2])*t]);}
  function nomeCurto(){return M&&M.nome?M.nome.replace(/^#/,''):null;}
  // troca o nome padrão pelo da marca em textos (mensagens de WhatsApp, títulos)
  window.TQR_br=function(s){
    if(!M||!M.nome||typeof s!=='string')return s;
    return s.replace(/#TQR Açaí/g,M.nome).replace(/TQR Açaí/g,nomeCurto());
  };
  // o roxo decorativo (brilhos, órbitas, degradês) acompanha o tom da cor de destaque: só troca o matiz, mantém brilho e saturação
  function hsl(a){var r=a[0]/255,g=a[1]/255,b=a[2]/255,mx=Math.max(r,g,b),mn=Math.min(r,g,b),l=(mx+mn)/2,h=0,s=0,d=mx-mn;
    if(d){s=l>.5?d/(2-mx-mn):d/(mx+mn);h=mx===r?(g-b)/d+(g<b?6:0):mx===g?(b-r)/d+2:(r-g)/d+4;h/=6;}return [h,s,l];}
  function deHsl(h,s,l){function f(p,q,t){if(t<0)t+=1;if(t>1)t-=1;return t<1/6?p+(q-p)*6*t:t<1/2?q:t<2/3?p+(q-p)*(2/3-t)*6:p;}
    if(!s)return [l*255,l*255,l*255];var q=l<.5?l*(1+s):l+s-l*s,p=2*l-q;return [f(p,q,h+1/3)*255,f(p,q,h)*255,f(p,q,h-1/3)*255];}
  function tinge(a,H){var x=hsl(a);return deHsl(H,x[1],x[2]).map(Math.round);}
  function roxos(d){
    var H=hsl(rgb(d))[0],st=document.documentElement.style,cs=getComputedStyle(document.documentElement);
    ['--pu','--go'].forEach(function(pre){for(var i=1;i<=80;i++){
      var n=pre+i,v=(cs.getPropertyValue(n)||'').trim();if(!v)continue;
      var base=document.documentElement.dataset[pre.slice(2)+i];if(!base){document.documentElement.dataset[pre.slice(2)+i]=v;base=v;}   // guarda o valor original (idempotente)
      var a=/^#[0-9a-f]{6}$/i.test(base)?rgb(base.toLowerCase()):base.split(',').map(Number);if(a.length!==3||a.some(isNaN))continue;
      var t=tinge(a,H);st.setProperty(n,/^#/.test(base)?toHex(t):t.join(','));
    }});
  }
  function cores(c){
    var r=document.documentElement.style, d=hex(c.destaque), d2=hex(c.destaque2), f=hex(c.fundo), f2=hex(c.fundo2);
    if(d){d2=d2||mix(d,'#ffffff',.55);
      r.setProperty('--gold',d);r.setProperty('--gold2',d2);r.setProperty('--gold3',mix(d,'#000000',.22));
      r.setProperty('--gold4',mix(d,d2,.55));r.setProperty('--gold5',mix(d,d2,.62));r.setProperty('--gold-rgb',rgb(d).join(','));roxos(d);}
    else if(d2){r.setProperty('--gold2',d2);}
    if(f){f2=f2||mix(f,'#ffffff',.04);
      r.setProperty('--bg',f);r.setProperty('--bg2',f2);r.setProperty('--bg3',mix(f2,'#ffffff',.04));r.setProperty('--bg4',mix(f,'#ffffff',.12));
      r.setProperty('--card',mix(f2,'#ffffff',.05));r.setProperty('--bg-rgb',rgb(f).join(','));}
  }
  function aplica(){
    if(!M)return;
    if(M.cores)cores(M.cores);
    if(M.nome){
      document.title=window.TQR_br(document.title);
      document.querySelectorAll('.brand span').forEach(function(e){e.textContent=M.nome;});
      document.querySelectorAll('img[alt="'+PADRAO+'"]').forEach(function(i){i.alt=M.nome;});
    }
    if(M.logo){
      document.querySelectorAll('.brand img, img.logo, #instaAvatar').forEach(function(i){i.src=M.logo;});
      var ic=document.querySelector('link[rel=icon]');if(ic)ic.href=M.logo;
    }
    try{document.dispatchEvent(new CustomEvent('tqr:marca',{detail:M}));}catch(e){}
  }
  function guarda(s){try{if(s)localStorage.setItem(K,JSON.stringify(s));else localStorage.removeItem(K);}catch(e){}}
  function ler(){try{var o=JSON.parse(localStorage.getItem(K)||'null');return o&&typeof o==='object'?o:null;}catch(e){return null;}}
  function ok(m){
    if(!m)return null;var r={};
    if(typeof m.nome==='string'&&m.nome.length<=40&&!/[<>]/.test(m.nome))r.nome=m.nome;
    if(typeof m.logo==='string'&&(/^img\/[\w.\-\/]+$/.test(m.logo)||/^https:\/\/[^\s"'<>]+$/.test(m.logo)))r.logo=m.logo;
    if(m.cores&&typeof m.cores==='object'){r.cores={};['destaque','destaque2','fundo','fundo2'].forEach(function(k){if(hex(m.cores[k]))r.cores[k]=m.cores[k];});}
    return (r.nome||r.logo||(r.cores&&Object.keys(r.cores).length))?r:null;
  }
  function depois(f){if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',f);else f();}
  M=ok(ler());
  if(M){
    // cores já na primeira pintura; textos e imagens quando o corpo existir
    if(M.cores)cores(M.cores);
    depois(aplica);
  }
  window.TQR_MARCA_SITE=function(){return M;};
  // busca a marca atual; mexe na tela só se for diferente da que já estava guardada
  try{
    fetch(SB.url+'/rest/v1/rpc/obter_marca',{method:'POST',headers:{apikey:SB.key,'Content-Type':'application/json'},body:'{}'})
      .then(function(r){return r.ok?r.json():Promise.reject();})
      .then(function(d){
        var novo=ok(d&&d.site),antes=JSON.stringify(M);
        if(JSON.stringify(novo)===antes)return;
        guarda(novo);
        if(!novo&&M){location.reload();return;}   // marca removida: volta ao padrão
        M=novo;depois(aplica);
        try{if(window.TQR_relink)window.TQR_relink();}catch(e){}
      }).catch(function(){});
  }catch(e){}
})();
