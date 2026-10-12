# 03 · Fluxo de Trabalho

## 1. Pedido do cliente (ponta a ponta)

```mermaid
sequenceDiagram
  actor Cl as Cliente
  participant S as Site
  participant DB as Supabase (RPC)
  participant WA as WhatsApp
  participant P as Painel
  Cl->>S: Monta o pedido
  S->>DB: simular_pedido (preço do servidor)
  Cl->>S: Confirma (nome, telefone, endereço)
  S->>DB: criar_pedido_v3
  DB-->>S: pedido #, total
  S->>WA: Abre wa.me com resumo
  DB-->>P: Pedido aparece na fila (pendente)
  opt Pix online ativo
    S->>DB: pagamento_registrar
    DB-->>S: QR / copia-e-cola
  end
```

## 2. Máquina de estados do pedido

```mermaid
stateDiagram-v2
  [*] --> pendente
  pendente --> confirmado
  pendente --> cancelado
  confirmado --> pago
  confirmado --> cancelado
  pago --> saiu_entrega
  pago --> cancelado
  saiu_entrega --> entregue
  entregue --> [*]
  cancelado --> [*]
```

Efeitos automáticos (gatilhos): **pago** → baixa de estoque, receita no caixa, pontos de fidelidade, nota (se automática). **cancelado** → estorno de estoque/caixa quando aplicável. Todo passo grava em `pedido_eventos`.

## 3. Rotina da operação (dia a dia)

| Quando | Quem | O que faz | Onde |
|---|---|---|---|
| Abertura | Dono/Gerente | Confere aviso, horário, estoque baixo | Início, Estoque |
| Durante | Atendente | Confirma pedidos, cria pedidos manuais, cobra Pix | Pedidos, Novo pedido, Pagamentos |
| Durante | Entregador | Marca "saiu para entrega" / "entregue" | Pedidos |
| Fechamento | Dono | Confere caixa, lança despesas, imprime relatório | Financeiro, Relatórios |
| Semanal | Dono | Registra compras de insumo, revisa custo/margem | Estoque, Custos |
| Semanal | Dono/Marketing | Campanha para clientes em risco, aniversariantes | CRM, Mensagens |
| Mensal | Dono | Relatório PDF analítico, fluxo mensal, contador | Relatórios, Notas |

## 4. Fluxo financeiro, custo e estoque

```mermaid
flowchart LR
  Compra[Compra de insumo] --> Custo[Custo médio últimas N compras]
  Custo --> Ficha[Ficha técnica / custo do produto]
  Venda[Pedido pago] --> Baixa[Baixa de estoque por receita]
  Venda --> Caixa[Lançamento de receita]
  Venda --> Pontos[Pontos de fidelidade]
  Ficha --> CMV[CMV e margem]
  Caixa --> Fluxo[Fluxo mensal]
```

## 5. Marketing e fidelidade

1. CRM classifica clientes (ativo, em risco, novo, aniversariante).
2. Dono escolhe segmento em **Mensagens** → campanha rápida abre WhatsApp com texto pronto.
3. Contato fica registrado em `interacoes_crm` / `mensagens_crm`; tarefas em `tarefas_crm`.
4. Pontos: R$ → pontos (`pontos_por_real`); brinde a cada `pontos_por_brinde`; resgate pelo painel.

## 6. Fluxo de desenvolvimento (como mudamos o sistema)

```mermaid
flowchart LR
  I[Ideia / pedido do dono] --> B[Branch claude/...]
  B --> C[Código + migration]
  C --> T[Testes Playwright + Postgres local]
  T --> M[Migration aplicada no Supabase]
  T --> PR[Pull Request]
  PR --> D[Dono mescla no main]
  D --> Pg[GitHub Pages publica]
  Pg --> V[Painel avisa nova versão]
```

Regras: nunca empurrar para `main` direto; se o PR já foi mesclado, recomeçar a branch de `origin/main`; atualizar **Ajuda** (`ajuda.js`) e o aviso de versão a cada mudança visível.

## 7. Implantação de um novo cliente (modelo "uma instância por cliente")

```mermaid
flowchart TD
  A[Contrato + escolha de plano] --> B[Criar projeto Supabase]
  B --> C[Aplicar migrations 01..N]
  C --> D[Ativar módulos do plano]
  D --> E[Fork do repo / copiar template]
  E --> F[Editar marca.js + cores + vocabulário]
  F --> G[Carga inicial: produtos, bairros, horários, WhatsApp]
  G --> H[Criar usuário dono]
  H --> I[Publicar Pages + domínio]
  I --> J[Teste de ponta a ponta]
  J --> K[Entrega + treinamento]
```

Meta: automatizar B–I num **assistente de implantação** (fase 3 do plano).

## 8. Suporte e mudança de plano
1. Cliente pede módulo extra → painel mestre ativa `instancia_modulos` → menu aparece no próximo carregamento.
2. Inadimplência (webhook Asaas) → módulos pagos ficam `ativo=false`; Núcleo continua, dados preservados.
3. Atualização de versão: aplicar migrations novas por instância, registrar em `versao_instancia`.
4. Incidente: verificar Supabase (pausa/limite), logs (`query_logs`), advisors; comunicar cliente.
