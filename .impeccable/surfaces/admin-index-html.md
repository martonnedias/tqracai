---
version: 1
slug: "admin-index-html"
primary_target: "admin/index.html"
related_targets: []
---

# Central TQR — painel administrativo (Operate)

Escopo: admin/index.html. Visitante: dono e equipe, no balcão pelo celular e no computador; tarefa: atender pedidos, ver o dia, gerir o negócio.

## Direction contract
seed: d5853b03 (roll degradado, direção fixada pelo usuário: balcão + rótulo + pulso)
THESIS: o painel é um quadro de balcão ao vivo com a identidade do rótulo da garrafa; recusa o dashboard cinza genérico de cartões iguais com um acento roxo.
OWN-WORLD: casca (menu e topo) em berinjela profunda com fio de folha de ouro; área de trabalho em lilás-polpa claro; ouro só em foco, seleção e no pulso; títulos em Poppins, saudação e telas vazias em Kaushan Script; estados (pendente âmbar, pago verde, atrasado vermelho) sobre a paleta.
STORY: em uma olhada o dono entende o ritmo do dia, o que está parado e confirma um pedido com um toque.
FIRST VIEWPORT (Início): saudação em script, faixa de indicadores, "Pulso do dia" (linha do dia das 8h às 2h com cada pedido como marca por hora, agora destacado, ontem em fantasma) e fila de pedidos ao vivo com o botão da próxima ação.
SIGNATURE: Pulso do dia (linha de 24h, horário de funcionamento sombreado, pedidos como marcas coloridas por estado).
RISK: pacote de marca troca cores, logo, fonte de destaque e textos em um arquivo (admin/marca.js) para replicar em outros clientes.
