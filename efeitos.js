/* #TQR Açaí · efeitos de interface em JavaScript puro (sem bibliotecas).
   Tudo respeita "reduzir movimento" e só liga o que faz sentido: luz do mouse e botão elástico apenas com mouse. */
(function(){
  var reduz=matchMedia('(prefers-reduced-motion: reduce)').matches;
  var mouse=matchMedia('(hover:hover) and (pointer:fine)').matches;

  // 1) Luz que segue o mouse nos cartões (JS só grava a posição; o brilho é um gradiente do CSS)
  if(mouse&&!reduz){
    var ALVO='.plan,.step,.p-prod,.pack,.stat,.trk-code,.p-pix,.cbox';
    document.addEventListener('pointermove',function(e){
      var el=e.target.closest&&e.target.closest(ALVO); if(!el)return;
      var r=el.getBoundingClientRect();
      el.style.setProperty('--mx',(e.clientX-r.left)+'px'); el.style.setProperty('--my',(e.clientY-r.top)+'px');
      if(!el.classList.contains('fx-luz'))el.classList.add('fx-luz');
    },{passive:true});
  }

  // 2) Botão dourado elástico: mola de verdade (velocidade + amortecimento a cada quadro) que puxa o botão para o mouse
  if(mouse&&!reduz){
    var K=.16,D=.78,MAX=7,RAIO=70;
    document.querySelectorAll('.btn-gold').forEach(function(b){
      if(b.classList.contains('btn-send')||b.closest('.cartbar,.cookie'))return;
      var x=0,y=0,vx=0,vy=0,tx=0,ty=0,rodando=false;
      function passo(){
        vx=(vx+(tx-x)*K)*D; vy=(vy+(ty-y)*K)*D; x+=vx; y+=vy;
        b.style.translate=x.toFixed(2)+'px '+y.toFixed(2)+'px';
        if(Math.abs(vx)+Math.abs(vy)+Math.abs(tx-x)+Math.abs(ty-y)>.05)requestAnimationFrame(passo);
        else{rodando=false;b.style.translate='';}
      }
      function liga(){if(!rodando){rodando=true;requestAnimationFrame(passo);}}
      window.addEventListener('pointermove',function(e){
        var r=b.getBoundingClientRect(); if(r.bottom<0||r.top>innerHeight)return;
        var cx=r.left+r.width/2,cy=r.top+r.height/2,dx=e.clientX-cx,dy=e.clientY-cy,d=Math.hypot(dx,dy),lim=Math.max(r.width,r.height)/2+RAIO;
        if(d<lim){var f=Math.min(1,(lim-d)/lim);tx=Math.max(-MAX,Math.min(MAX,dx*.14*f*2));ty=Math.max(-MAX,Math.min(MAX,dy*.14*f*2));liga();}
        else if(tx||ty){tx=0;ty=0;liga();}
      },{passive:true});
    });
  }

  // 3) "Como funciona": o trilho dourado liga os passos e se desenha conforme a rolagem; cada número acende quando o trilho chega
  (function(){
    var box=document.querySelector('.steps'); if(!box)return;
    var passos=[].slice.call(box.querySelectorAll('.step')),n=passos.length; if(!n)return;
    function quadro(){
      var wide=matchMedia('(min-width:900px)').matches,b=box.getBoundingClientRect(),vh=innerHeight;
      var p=reduz?1:Math.max(0,Math.min(1,(vh*.72-b.top)/(b.height+vh*.1)));
      passos.forEach(function(s,i){
        var ini=i/Math.max(1,n-1),acende=reduz||(wide?p>=ini-.001:s.getBoundingClientRect().top<vh*.72);
        s.classList.toggle('fx-on',acende);
        var seg=reduz?1:Math.max(0,Math.min(1,(p-ini)*Math.max(1,n-1)));
        s.style.setProperty('--seg',seg.toFixed(3));
      });
    }
    var raf=0; function agenda(){if(raf)return;raf=requestAnimationFrame(function(){raf=0;quadro();});}
    addEventListener('scroll',agenda,{passive:true}); addEventListener('resize',agenda); quadro();
  })();

  // 4) Odômetro: cada dígito é uma fita de 0 a 9 que desliza até o número certo
  function odometro(el){
    var txt=el.textContent.trim(); if(!txt||el.dataset.odTxt===txt)return;
    el.dataset.odTxt=txt; el.setAttribute('aria-label',txt); el.textContent='';
    var n=0;
    txt.split('').forEach(function(ch){
      if(!/\d/.test(ch)){var s=document.createElement('span');s.setAttribute('aria-hidden','true');s.textContent=ch;el.appendChild(s);return;}
      var jan=document.createElement('span'),fita=document.createElement('span');
      jan.className='od-j'; jan.setAttribute('aria-hidden','true'); fita.className='od-f';
      for(var i=0;i<10;i++){var d=document.createElement('span');d.textContent=i;fita.appendChild(d);}
      jan.appendChild(fita); el.appendChild(jan);
      var alvo=+ch;
      if(reduz){fita.style.transform='translateY(-'+alvo*10+'%)';}
      else{fita.style.transition='transform '+(1.1+n*.18)+'s cubic-bezier(.2,.8,.2,1)';
        requestAnimationFrame(function(){requestAnimationFrame(function(){fita.style.transform='translateY(-'+alvo*10+'%)';});});}
      n++;
    });
  }
  window.TQR_odometro=odometro;
  document.querySelectorAll('#statCount').forEach(function(el){
    if(!('IntersectionObserver' in window)){return;}
    var visto=false,mexendo=false;
    var io=new IntersectionObserver(function(es){es.forEach(function(e){if(e.isIntersecting&&!visto){visto=true;mexendo=true;odometro(el);mexendo=false;}});},{threshold:.6});
    io.observe(el);
    // o número verdadeiro chega do banco depois: se mudar depois de visto, rola de novo
    new MutationObserver(function(){if(visto&&!mexendo&&el.dataset.odTxt!==el.textContent.trim()&&!el.querySelector('.od-j')){mexendo=true;odometro(el);mexendo=false;}}).observe(el,{childList:true,characterData:true,subtree:false});
  });

  // 5) Confete dourado e roxo quando o pedido é recebido
  window.TQR_confete=function(){
    if(reduz)return;
    var c=document.createElement('canvas'); c.setAttribute('aria-hidden','true');
    c.style.cssText='position:fixed;inset:0;width:100%;height:100%;pointer-events:none;z-index:9999';
    var dpr=Math.min(2,devicePixelRatio||1),W=innerWidth,H=innerHeight; c.width=W*dpr; c.height=H*dpr; document.body.appendChild(c);
    var g=c.getContext('2d'); g.scale(dpr,dpr);
    var cores=['#e8be62','#f7dc9b','#c8902e','#7a2fb0','#b57be0','#ffffff'],ps=[],N=W<600?70:110;
    for(var i=0;i<N;i++){var ang=-Math.PI/2+(Math.random()-.5)*1.5,v=7+Math.random()*9;
      ps.push({x:W/2,y:H*.32,vx:Math.cos(ang)*v,vy:Math.sin(ang)*v,w:5+Math.random()*6,h:3+Math.random()*4,r:Math.random()*6,vr:(Math.random()-.5)*.4,c:cores[i%cores.length]});}
    var t0=null;
    (function f(t){
      if(!t0)t0=t; var k=(t-t0)/2600; g.clearRect(0,0,W,H);
      ps.forEach(function(p){p.vy+=.28;p.vx*=.992;p.x+=p.vx;p.y+=p.vy;p.r+=p.vr;
        g.save();g.globalAlpha=Math.max(0,1-k*k);g.translate(p.x,p.y);g.rotate(p.r);g.fillStyle=p.c;g.fillRect(-p.w/2,-p.h/2,p.w,p.h);g.restore();});
      if(k<1)requestAnimationFrame(f);else c.remove();
    })(performance.now());
  };
})();
