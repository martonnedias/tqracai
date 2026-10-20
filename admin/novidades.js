/* Novidades do painel: cada função nova entra aqui ao ser lançada e ganha o selo "Novo".
   id: 'aba:<data-tab do menu>' ou 'sub:<secao>-<subaba>' (id do botão sem "st-"). desde: AAAA-MM-DD.
   O selo some sozinho depois de N dias (Configurações > Novidades), quando o usuário abre a aba,
   ou quando o dono desliga o item. SEMPRE que lançar algo novo, acrescente uma linha aqui. */
window.TQR_NOVIDADES = [
  { id: 'aba:config',   rot: 'Licença do sistema', desde: '2026-10-18' },
  { id: 'aba:estoque',  rot: 'Garrafas prontas por sabor', desde: '2026-10-20' },
  { id: 'aba:produtos', rot: 'Sabores com foto, sugestão de venda e exclusões', desde: '2026-10-20' },
  { id: 'aba:pedidos',  rot: 'Código de entrega e Pix com valor', desde: '2026-10-17' },
  { id: 'aba:prova',   rot: 'Prova social',      desde: '2026-10-15' },
  { id: 'aba:marca',   rot: 'Personalização do site (nome, logo e cores)', desde: '2026-10-17' },
  { id: 'aba:modulos', rot: 'Plano e módulos',   desde: '2026-10-29' }
];
