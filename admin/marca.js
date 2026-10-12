/* Pacote de marca do painel. Para outro cliente, troque só este arquivo (e o logo/fonte que ele aponta).
   Tudo aqui é lido pelo painel na abertura: nome, textos, cores da casca, fonte de destaque e frases de tela vazia. */
window.TQR_MARCA = {
  nome: 'Central TQR',
  empresa: '#TQR Açaí',
  subtitulo: 'Gestão do #TQR Açaí',
  logo: '../img/rotulo.webp',
  cores: {
    casca: '#1a0a2b',       // menu lateral e topo
    casca2: '#2a1245',      // realces da casca
    marca: '#59298a',       // botões e seleção
    marcaHover: '#491f73',
    destaque: '#e8be62',    // fio de ouro, foco e o "agora" do pulso
    destaque2: '#fbe2a0',
    fundo: '#f5f1f9'        // fundo da área de trabalho
  },
  fonteDestaque: { familia: "'Kaushan Script'", arquivo: '../fonts/Kaushan.ttf' },   // saudação, nome e telas vazias
  // Vocabulário do negócio: o painel troca "garrafa(s)" por estas palavras (ex.: pizza/pizzas, marmita/marmitas).
  vocabulario: { unidade: 'garrafa', unidades: 'garrafas' },
  saudacao: { manha: 'Bom dia', tarde: 'Boa tarde', noite: 'Boa noite' },
  textos: {
    filaVazia: 'Nenhum pedido na fila. Bora vender?',
    pulsoVazio: 'O dia ainda não começou. Os pedidos aparecem aqui, na hora em que chegam.',
    montagemTitulo: 'Monte o seu açaí',
    exemploCompra: 'compra de açaí',
    loginSub: 'Gestão do #TQR Açaí · acesso da equipe'
  }
};
