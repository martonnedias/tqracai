/* Tema claro/escuro: a escolha do visitante fica guardada neste aparelho (padrão: escuro, o visual da marca). */
(function(){
  var K='tqr_tema',r=document.documentElement;
  function lido(){try{return localStorage.getItem(K);}catch(e){return null;}}
  function aplica(t){
    if(t==='claro')r.setAttribute('data-tema','claro');else r.removeAttribute('data-tema');
    var m=document.querySelector('meta[name=theme-color]');
    if(m){if(!m.getAttribute('data-orig'))m.setAttribute('data-orig',m.getAttribute('content')||'');m.setAttribute('content',t==='claro'?'#fbf7ff':m.getAttribute('data-orig'));}
    var bs=document.querySelectorAll('[data-tema-toggle]');
    for(var i=0;i<bs.length;i++){var b=bs[i],c=t==='claro';
      b.setAttribute('aria-pressed',c?'true':'false');b.setAttribute('aria-label',c?'Mudar para o tema escuro':'Mudar para o tema claro');b.title=c?'Tema escuro':'Tema claro';
      var l=b.querySelector('.tema-lbl');if(l)l.textContent=c?'Tema escuro':'Tema claro';}
  }
  aplica(lido());
  document.addEventListener('DOMContentLoaded',function(){
    aplica(lido());
    document.addEventListener('click',function(e){
      var b=e.target.closest&&e.target.closest('[data-tema-toggle]');if(!b)return;
      var n=r.getAttribute('data-tema')==='claro'?'escuro':'claro';
      try{localStorage.setItem(K,n);}catch(x){}
      aplica(n);
    });
  });
})();
