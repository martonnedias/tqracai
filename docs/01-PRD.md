# 01 · PRD — Documento de Requisitos do Produto

**Produto:** #TQR Açaí (site de pedidos) + **Central TQR** (painel de gestão)
**Dono:** Martonne · **Cidade:** Teresina-PI · **Idioma:** pt-BR
**Estado:** em produção (modo de testes; pagamento e nota fiscal em homologação)

---

## 1. Visão

Entregar açaí tradicional em garrafa de 300 ml, pronto para tomar, com pedido simples pelo site/WhatsApp e uma operação enxuta controlada por um painel único.

**Visão de negócio (segunda fase):** transformar o conjunto *site + painel + banco* em um **produto de assinatura (SaaS)** vendido a outros tipos de delivery (hamburgueria, pizzaria, doces, marmitas…), contratado **por módulos/planos**. Caminho escolhido: **uma instância por cliente** (um projeto Supabase + um site + um painel a partir deste modelo), com multi-tenant só depois, se o volume justificar.

## 2. Problema

- Pedidos chegam por WhatsApp sem padrão: erros de preço, endereço e troco.
- Dono não enxerga caixa, custo, estoque nem recompra de clientes.
- Sem fidelização nem comunicação organizada com a base.
- Ferramentas prontas de delivery cobram comissão alta e não deixam personalizar.

## 3. Usuários

| Perfil | Quem é | Precisa de |
|---|---|---|
| **Cliente final** | Quem compra açaí | Montar pedido, ver preço correto, pagar, acompanhar, juntar pontos |
| **Dono** (`*`) | Martonne | Tudo: financeiro, custos, configurações, usuários |
| **Gerente** | Braço direito | Operação + relatórios + estoque, sem usuários |
| **Atendente** | Balcão/WhatsApp | Criar e mover pedidos, ver clientes |
| **Entregador** | Moto | Ver e atualizar status de entrega |
| **Cliente-assinante (futuro)** | Outro delivery | Instalação rápida, marca própria, pagar só o que usa |

## 4. Objetivos e métricas

| Objetivo | Métrica de sucesso |
|---|---|
| Reduzir erro de pedido | 0 divergências de preço (preço calculado no servidor) |
| Operação rápida | Pedido manual em < 60 s; fila visível em tempo real |
| Saber o lucro | CMV e margem por produto atualizados a cada compra |
| Recompra | % de clientes ativos vs. em risco (CRM) e uso de pontos |
| Vendável | Nova instância pronta em horas, não dias |

## 5. Escopo atual (o que já foi feito)

Legenda: ✅ pronto · 🧪 homologação/teste · ⏳ pendente

### 5.1 Site público (`index.html`)
- ✅ Vitrine, combos e preços vindos do banco (`obter_vitrine`, `obter_precos`), contador de garrafas, aviso configurável, horário de funcionamento.
- ✅ Montagem de pedido, simulação de preço, cadastro/login do cliente por código, endereços, saldo de pontos.
- ✅ Envio do pedido ao banco + mensagem formatada ao WhatsApp da loja.
- ✅ Pix: diálogo com QR/copia-e-cola (quando o gateway estiver ativo).
- ✅ Acessibilidade básica (skip link, aria-labels), blog estático.

### 5.2 Painel Central TQR (`admin/`)
| Grupo | Módulo | Estado | Resumo |
|---|---|---|---|
| Operação | Início | ✅ | "Pulso do dia" (linha do tempo por hora) e fila ao vivo |
| | Pedidos | ✅ | Kanban (pendente→confirmado→pago→saiu_entrega→entregue/cancelado), limite por coluna, menu "⋯", impressão de comanda |
| | Novo pedido | ✅ | Pedido manual com tiles de produto (− / +), 3 blocos |
| | Pagamentos | 🧪 | Cobrança Pix; modos nenhum/teste/Asaas |
| Clientes e marketing | Clientes, CRM | ✅ | Ficha, endereços, segmentos, tarefas, interações |
| | Mensagens | ✅ | Campanha rápida por segmento via WhatsApp |
| | Promoções | ✅ | Regras com validação em trigger |
| | Fidelidade | ✅ | Pontos por real/brinde, aniversário, resgate |
| Gestão | Financeiro | ✅ | Lançamentos, categorias, fluxo mensal, gráficos |
| | Relatórios | ✅ | Vendas/produtos/financeiro/clientes, PDF resumido e analítico, deltas |
| | Notas fiscais | 🧪 | Emissão **simulada** (homologação); produção indisponível |
| | Custos | ✅ | Ficha técnica, custo médio das últimas N compras, histórico |
| | Estoque | ✅ | Insumos, compras, movimentos, baixa automática ao pagar |
| Catálogo | Produtos, Montagem | ✅ | Grupos de opções, receitas, preços |
| Sistema | Configurações | ✅ | 5 sub-abas (Loja, Pedidos, Empresa/fiscal, Pagamento, Entrega) |
| | Usuários | ✅ | Usuários, perfis e **edição das permissões de cada perfil** (Edge Function `admin-usuarios`) |
| | Plano e módulos | ✅ | Liga/desliga módulos e aplica plano; trava no servidor |
| | Personalização | ✅ | Cores, fontes, nome e logo do painel, com prévia e contraste |
| | Ajuda | ✅ | Guia por módulo e dicas por campo |

### 5.3 Plataforma
- ✅ Banco Supabase com RLS por permissão, 21 migrations, gatilhos de negócio.
- ✅ Pacote de marca trocável (`admin/marca.js`) com vocabulário (garrafa → unidade).
- ✅ Aviso automático de nova versão no painel.
- ✅ Hospedagem gratuita (GitHub Pages) com deploy a cada merge no `main`.

## 6. Requisitos funcionais

| ID | Requisito | Prioridade |
|---|---|---|
| RF-01 | Cliente monta pedido e vê preço idêntico ao cobrado (servidor decide) | Alta |
| RF-02 | Pedido nasce `pendente` e segue máquina de estados validada em trigger | Alta |
| RF-03 | Pagamento aprovado muda pedido para `pago` de forma idempotente | Alta |
| RF-04 | Pedido pago baixa estoque, lança receita no caixa e credita pontos | Alta |
| RF-05 | Permissão por ação (`pedidos.cancelar`, `financeiro.ver`…) imposta no banco | Alta |
| RF-06 | Dono cria usuários e define perfil sem expor chave de serviço no navegador | Alta |
| RF-07 | Custo do produto = média ponderada das últimas N compras | Média |
| RF-08 | Campanhas por segmento (ativos, em risco, aniversariantes) | Média |
| RF-09 | Relatórios com comparação ao período anterior e exportação PDF | Média |
| RF-10 | Impressão de comanda e recibo | Média |
| RF-11 | Nota fiscal (homologação) com cancelamento e XML de teste | Baixa (até contador) |
| RF-12 | Troca de marca/vocabulário sem alterar código do painel | Média |
| RF-13 | **Ativar/desativar módulos por instância** (ver §8) | Alta (fase SaaS) — ✅ entregue (migração 22) |
| RF-14 | **Cadastro de empresas assinantes** no painel mestre: dados da empresa, contatos, plano, módulos, instância, contrato e cobrança (ver §8.4) | Alta (fase SaaS) |
| RF-15 | **Personalização da marca pelo próprio cliente**: cores, fontes, nome e logo do painel, com prévia ao vivo e aviso de contraste (ver §8.5) | Alta — ✅ entregue (migração 23, tela Personalização) |
| RF-16 | Histórico de eventos por assinante (ativação, troca de plano, suspensão, versão aplicada) | Média |

## 7. Requisitos não funcionais

- **Segurança:** RLS em 100% das tabelas; nenhuma regra de preço no navegador; MFA e proteção de senha vazada ativos antes da operação real; LGPD (dados mínimos, opt-out de mensagens).
- **Desempenho:** sem build; páginas estáticas; consultas agregadas por views/RPC.
- **Disponibilidade:** depende de Supabase e GitHub Pages; plano Free pode **pausar** por inatividade → recomendado Pro em produção.
- **Usabilidade:** funciona em celular (barra inferior ≤ 959 px), toque ≥ 44 px, contraste AA.
- **Manutenibilidade:** arquivo único no painel, ajuda e design system documentados; testes automatizados com Playwright + Postgres local.
- **Custo:** operação ~ R$ 0 (Free) a ~US$ 25/mês (Supabase Pro).

## 8. Modelo comercial (assinatura por módulos)

### 8.1 Catálogo de módulos
| Módulo | Conteúdo | Observação |
|---|---|---|
| **Núcleo** (obrigatório) | Site, pedidos, clientes, usuários, config | Sempre ativo |
| **Operação** | Kanban, pedido manual, impressão | |
| **Gestão** | Financeiro, relatórios, custos, estoque | |
| **Marketing** | CRM, mensagens, promoções, fidelidade | |
| **Pagamentos online** | Pix/cartão via Asaas | Taxa do gateway à parte |
| **Nota fiscal** | NFC-e/NF-e | Só após validação com contador |
| **Personalização** | Marca própria, domínio, vocabulário | |
| **Multiusuário** | Mais de N usuários/perfis | |
| **Multiloja** | Várias unidades | Exige multi-tenant (fase 2) |

### 8.2 Planos sugeridos
- **Essencial:** Núcleo + Operação.
- **Profissional:** + Gestão + Marketing.
- **Completo:** + Pagamentos + Nota fiscal + Personalização.
- **Add-ons:** módulos avulsos, usuários extras, WhatsApp oficial.

### 8.3 Como controlar
1. Tabelas `modulos`, `planos`, `instancia_modulos` (ver `05-BANCO-DE-DADOS.md` §9).
2. Função `modulo_ativo(codigo)` aplicada em **RLS e RPCs** (o servidor recusa mesmo que alguém force pelo console).
3. Painel esconde menus de módulos inativos (cosmético, não é a segurança).
4. **Painel mestre** (do dono do produto) liga/desliga módulos por cliente; licença com cache e tolerância offline.
5. Cobrança recorrente (Asaas) → webhook ativa/desativa módulos automaticamente.

### 8.4 Cadastro de empresas assinantes (painel mestre)
O painel mestre é um sistema **do dono do produto** (separado das lojas) e guarda quem assina:

| Grupo | Campos |
|---|---|
| Empresa | Razão social, nome fantasia, CNPJ/CPF, segmento (açaí, pizzaria, hamburgueria...), cidade/UF, site, logo |
| Contatos | Responsável, e-mail, WhatsApp, contato financeiro, contato técnico |
| Contrato | Plano, módulos extras (add-ons), data de início, vencimento, ciclo (mensal/anual), valor, desconto, status (teste, ativo, inadimplente, suspenso, cancelado) |
| Instância | Projeto Supabase, URL do site e do painel, domínio próprio, versão do sistema aplicada, último acesso, saúde (ativo/pausado) |
| Cobrança | Cliente no gateway, assinatura recorrente, últimas cobranças, status do pagamento |
| LGPD | Aceite do contrato e do termo de operador de dados, data e versão |
| Histórico | Linha do tempo: criado, plano trocado, módulo ligado/desligado, suspenso, versão atualizada, observações |

Telas: lista com filtros (status, plano, segmento, vencimento), ficha do assinante, botão "Ligar/desligar módulo", "Suspender", "Abrir painel da loja". Cada ação no mestre reflete na instância da loja (ver TRD §12).

### 8.5 Personalização da marca (white-label)
Já entregue: tela **Personalização** (módulo `personalizacao`). O cliente escolhe um modelo pronto ou ajusta 4 cores (fundo do menu, cor principal, destaque, fundo das telas), 3 fontes (textos, títulos, destaque), nome, subtítulo e logo. A prévia é ao vivo; o servidor valida cores (#rrggbb), fontes (lista liberada) e o logo (link https); avisos de contraste (WCAG) impedem combinações ilegíveis sem bloquear. Vale na tela de login também. "Voltar ao padrão" restaura o visual do arquivo `marca.js`.
Ainda fora desta entrega: upload do logo, favicon próprio, personalização do **site público** (hoje só o painel) e domínio próprio.

## 9. Sugestões para deixar o sistema mais completo

Priorizadas no `06-PLANO-DE-IMPLEMENTACAO.md`. Resumo: cardápio/QR de mesa, cupons, entregador com rota e comprovante, avaliação pós-entrega, WhatsApp oficial (API) com modelos, app instalável (PWA), notificação sonora de novo pedido, múltiplas formas de pagamento no balcão, controle de caixa/turno, taxa por bairro/distância, agendamento de pedidos, integração iFood/Rappi (importação), assistente de implantação, modelos por segmento.

## 10. Fora de escopo (por ora)
Multi-tenant em um único banco; app nativo; emissão fiscal em produção; entrega com rastreio GPS; marketplace.

## 11. Riscos e cuidados

| Risco | Mitigação |
|---|---|
| Atualizar N instâncias com versões diferentes | Migrations versionadas + script de atualização + versão por instância |
| LGPD: o dono do produto vira **operador** dos dados do cliente-assinante | Contrato (DPA), dados isolados por projeto, política de retenção |
| Regra fiscal de serviço próprio (nota da assinatura) | Contador; começar com MEI/Simples conforme enquadramento |
| Prometer módulo não construído | Vender só o que está ✅; roadmap público separado |
| Projeto Free pausado | Plano Pro nas instâncias pagas |
| Dependência de gateway/WhatsApp | Adaptadores trocáveis |

## 12. Pendências do dono (antes da operação real)
Mesclar PRs; testar login real; trocar WhatsApp de teste; preencher razão social/endereço/e-mail; ativar MFA e proteção de senha vazada; apagar pedidos de teste; implantar Edge Functions `criar-pedido` (Turnstile) e `pagamentos` (secrets `GATEWAY_API_KEY`, `GATEWAY_WEBHOOK_TOKEN`, `GATEWAY_URL`); dados do contador para NF real; avaliar Supabase Pro; decidir texto "freezer"/"100% natural" e encurtar página.
