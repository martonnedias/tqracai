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
  function cores(c){
    var r=document.documentElement.style, d=hex(c.destaque), d2=hex(c.destaque2), f=hex(c.fundo), f2=hex(c.fundo2);
    if(d){d2=d2||mix(d,'#ffffff',.55);
      r.setProperty('--gold',d);r.setProperty('--gold2',d2);r.setProperty('--gold3',mix(d,'#000000',.22));
      r.setProperty('--gold4',mix(d,d2,.55));r.setProperty('--gold5',mix(d,d2,.62));r.setProperty('--gold-rgb',rgb(d).join(','));}
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
