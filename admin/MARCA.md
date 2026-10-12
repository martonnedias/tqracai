# Pacote de marca do painel (Central TQR)

Para entregar o painel a outro cliente (outro tipo de delivery), troque **só** estes itens:

| O quê | Onde | Efeito |
|---|---|---|
| Nome, subtítulo, logo, textos da fila, do pulso e do login | `admin/marca.js` | Cabeçalho, login, título da aba, telas vazias |
| Cores da casca (menu e topo), da marca, do destaque e do fundo | `admin/marca.js` > `cores` | Todo o painel (variáveis CSS) |
| Fonte de destaque (nome, saudação, telas vazias) | `admin/marca.js` > `fonteDestaque` + arquivo `.ttf` | Marca |
| Palavra do produto ("garrafa", "pizza", "marmita") | `admin/marca.js` > `vocabulario` | Troca a palavra em todos os textos do painel |
| Horário de funcionamento | Configurações do painel (banco) | O "Pulso do dia" usa o horário de cada cliente |
| Catálogo, bairros, formas de pagamento, preços | Painel (banco) | Dados de cada cliente |

Não mexa no HTML do painel para personalizar. O mesmo núcleo atende todos os clientes; a identidade vem do pacote.

## Falta para vender como assinatura (ver HANDOFF.md, "Produto como assinatura")
- Site público também lendo o pacote de marca (hoje o `index.html` do site é específico do #TQR Açaí).
- Assistente de implantação (novo projeto Supabase + migrações + usuário dono).
- Cobrança recorrente, termos de uso e contrato.
