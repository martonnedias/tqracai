/* menu do celular (blog e políticas): abre e fecha o painel de links do topo */
(function(){
  var b=document.getElementById('menuBtn'),nav=document.getElementById('menuNav'); if(!b||!nav) return;
  function abre(v){document.body.classList.toggle('menu-open',v);b.setAttribute('aria-expanded',v?'true':'false');b.setAttribute('aria-label',v?'Fechar menu':'Abrir menu');}
  b.addEventListener('click',function(){abre(!document.body.classList.contains('menu-open'));});
  nav.addEventListener('click',function(e){if(e.target.closest('a'))abre(false);});
  document.addEventListener('keydown',function(e){if(e.key==='Escape'&&document.body.classList.contains('menu-open')){abre(false);b.focus();}});
  document.addEventListener('click',function(e){if(document.body.classList.contains('menu-open')&&!e.target.closest('.top'))abre(false);});
  addEventListener('resize',function(){if(innerWidth>900)abre(false);});
})();
