# 06 · Plano de Implementação

Esforço relativo: **P** (≤ 1 dia) · **M** (2–4 dias) · **G** (1–2 semanas) · **GG** (> 2 semanas).

## 1. Histórico — o que já foi entregue

| Etapa | Entrega | PR/estado |
|---|---|---|
| 1 | Site, banco, pedido, preço no servidor | ✅ produção |
| 2 | Painel: pedidos, clientes, produtos, usuários | ✅ |
| 3 | Fidelidade, promoções, CRM | ✅ |
| 4 | Custos e estoque (ficha técnica, CMV) | ✅ |
| 5 | Impressão (migration 18) | ✅ |
| 6 | Pagamentos Asaas, modo teste (19) | 🧪 |
| 7 | Nota fiscal em homologação (20) | 🧪 |
| 8 | Relatórios + PDF (21) | ✅ |
| 9 | Redesign "Central TQR", marca trocável, Pulso do dia | ✅ PRs #7–#14 |
| 10 | Menu Marketing, pedido manual, gráficos, barra inferior mobile | ✅ |
| 11 | Limite de cartões no Kanban | ✅ PR #15 |
| 12 | Documentação PRD/TRD/Fluxo/Design/Banco/Plano | ✅ este PR |

## 2. Go-live (pendências do dono)

- [ ] Mesclar PRs abertos e conferir `https://martonnedias.github.io/tqracai/admin/`
- [ ] Testar login real de cada perfil
- [ ] Trocar WhatsApp de teste pelo número real
- [ ] Preencher razão social, endereço, e-mail (Configurações → Empresa)
- [ ] Ativar MFA e proteção de senha vazada (Supabase Auth)
- [ ] Apagar pedidos/clientes de teste
- [ ] Implantar `criar-pedido` (Turnstile) e `pagamentos` (secrets `GATEWAY_API_KEY`, `GATEWAY_WEBHOOK_TOKEN`, `GATEWAY_URL`)
- [ ] Decidir: Supabase Pro (evita pausa e dá backup)
- [ ] Textos do site: "freezer", "100% natural", encurtar página
- [ ] Dados do contador para nota fiscal real (antes de sair de homologação)

## 3. Roadmap da assinatura (SaaS)

### Fase 1 — Módulos e planos · **G**
- Migration 22: `modulos`, `planos`, `plano_modulos`, `instancia_modulos`, `modulo_ativo()`, `meus_modulos()`.
- Guardas em RLS/RPCs: `gestao` (financeiro, relatórios, custos, estoque), `marketing` (CRM, mensagens, promoções, fidelidade), `pagamentos`, `fiscal`, `personalizacao`.
- Painel: ocultar abas, tela "Plano e módulos", mensagem "módulo não contratado".
- **Aceite:** desativar `gestao` ⇒ aba some **e** chamada direta a `rel_vendas` falha; Núcleo nunca desativa; testes cobrem os 3 planos.
- **Risco:** esquecer uma RPC → checklist automatizado listando funções sem guarda.

### Fase 2 — Painel mestre e licenças · **G**
- Projeto Supabase do dono do produto: clientes, instâncias, plano, status, versão.
- Edge Function de licença (token assinado, cache e tolerância na instância).
- **Aceite:** ligar/desligar módulo no mestre reflete na instância em ≤ 5 min; offline respeita tolerância.
- Depende da Fase 1.

### Fase 3 — Assistente de implantação · **G**
- Script/CLI: cria projeto Supabase, aplica migrations, semeia módulos do plano, gera `marca.js`, publica Pages.
- Modelos por segmento (açaí, hamburgueria, pizzaria, doces, marmita): catálogo e vocabulário iniciais.
- **Aceite:** instância nova pronta em < 2 h por checklist; sem editar código à mão além de `marca.js`.

### Fase 4 — Cobrança recorrente · **M**
- Assinatura Asaas por plano/add-on; webhook → `instancia_modulos` (ativa/suspende).
- Régua de inadimplência: aviso → carência → suspende módulos pagos (dados preservados).
- **Aceite:** pagamento confirmado ativa em minutos; atraso suspende após carência.

### Fase 5 — WhatsApp oficial e modelos · **G**
- API oficial (provedor), modelos aprovados, envio em lote com opt-out, status de entrega.
- Módulo add-on `whatsapp`.

### Fase 6 — Atualização em massa · **M**
- `versao_instancia`; script aplica migrations novas em todas as instâncias com relatório de falhas; canário primeiro.

### Fase 7 — Multi-tenant / multiloja · **GG** (só se houver volume)
- `loja_id` em todas as tabelas, RLS por loja, painel por loja. Reavaliar após ~10 clientes.

## 4. Backlog de funcionalidades sugeridas (priorizado)

| Prioridade | Item | Esforço |
|---|---|---|
| Alta | Notificação sonora/visual de novo pedido | P |
| Alta | PWA instalável (painel e site) | M |
| Alta | Taxa de entrega por bairro/distância refinada | M |
| Alta | Controle de caixa/turno (abertura/fechamento) | M |
| Média | Cupons de desconto | M |
| Média | Agendamento de pedidos | M |
| Média | Avaliação pós-entrega (NPS) | P |
| Média | Comprovante/rota para entregador | M |
| Média | Importação de pedidos iFood/Rappi | G |
| Baixa | QR de mesa / cardápio digital | M |
| Baixa | Multi-forma de pagamento no balcão | M |
| Baixa | Painel de metas e alertas (estoque mínimo, margem) | M |

## 5. Dívidas técnicas a quitar (paralelo)
Self-host de fontes · estados `.fld.err` e `.btn.load` · `prefers-reduced-motion` · achados do relatório de acessibilidade · textos de marca ainda fixos no site · quebrar `admin/index.html` em módulos quando passar ~6 mil linhas · mais testes de SQL (pgTAP).

## 6. Regras de execução
- Uma fase = um PR (ou poucos), sempre com testes e **Ajuda** atualizada.
- Só vender módulo com status ✅ no PRD.
- Contador e jurídico (LGPD/DPA, regra fiscal da assinatura) antes da primeira venda.
- Ordem recomendada: **1 → 2 → 3 → 4 → 5**, com a Fase 6 antes do 3º cliente.
