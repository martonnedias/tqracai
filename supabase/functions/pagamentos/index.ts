// Função de borda de pagamentos. Ações (POST JSON):
//   { acao: "cobrar", pedido_id }            -> painel (JWT de quem tem financeiro.gerir ou pedidos.status): cria cobrança Pix no gateway
//   { acao: "publico", codigo, whatsapp }    -> site: cria/consulta a cobrança do próprio pedido
//   { acao: "estornar", pagamento_id }       -> painel (financeiro.gerir): pede o estorno ao gateway
//   POST ?webhook=asaas                      -> gateway avisa mudança de status (valida o token do webhook)
// Segredos (supabase secrets set): GATEWAY_API_KEY, GATEWAY_WEBHOOK_TOKEN, GATEWAY_URL (sandbox: https://sandbox.asaas.com/api/v3).
// SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY já vêm no ambiente. Publicar: supabase functions deploy pagamentos --no-verify-jwt
// Sem GATEWAY_API_KEY a função recusa as ações; o modo "teste" não precisa dela (roda só no banco).
// ATENÇÃO: o adaptador Asaas segue a documentação pública e ainda não foi exercitado contra a conta real; valide no sandbox antes de ligar.
import { createClient } from "npm:@supabase/supabase-js@2.45.0";

const ORIGENS = (Deno.env.get("ALLOWED_ORIGINS") ?? "https://martonnedias.github.io").split(",").map((o) => o.trim());
const API = Deno.env.get("GATEWAY_URL") ?? "https://sandbox.asaas.com/api/v3";
const KEY = Deno.env.get("GATEWAY_API_KEY") ?? "";
const WH_TOKEN = Deno.env.get("GATEWAY_WEBHOOK_TOKEN") ?? "";

function cors(req: Request) {
  const o = req.headers.get("origin") ?? "";
  return {
    "Access-Control-Allow-Origin": ORIGENS.includes(o) ? o : ORIGENS[0],
    "Access-Control-Allow-Headers": "authorization, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}
const J = (b: unknown, s: number, h: HeadersInit) => new Response(JSON.stringify(b), { status: s, headers: h });

async function asaas(path: string, init: RequestInit = {}) {
  const r = await fetch(API + path, {
    ...init,
    headers: { "Content-Type": "application/json", "access_token": KEY, "User-Agent": "tqr-acai", ...(init.headers ?? {}) },
  });
  const txt = await r.text();
  let j: any = {}; try { j = JSON.parse(txt); } catch { /* resposta não JSON */ }
  if (!r.ok) throw new Error("gateway_" + r.status + ":" + (j?.errors?.[0]?.description ?? "erro"));
  return j;
}

// cria cliente + cobrança Pix para o pedido e grava em public.pagamentos
async function cobrarPix(sb: ReturnType<typeof createClient>, pedidoId: string) {
  const { data: ped } = await sb.from("pedidos").select("id,codigo,total,status,clientes(nome,whatsapp)").eq("id", pedidoId).single();
  if (!ped) throw new Error("pedido_inexistente");
  const { data: pend } = await sb.from("pagamentos").select("id").eq("pedido_id", pedidoId).eq("status", "pendente").gt("expira_em", new Date().toISOString()).maybeSingle();
  if (pend) return pend.id as string;
  const cli: any = Array.isArray(ped.clientes) ? ped.clientes[0] : ped.clientes;
  const cliente = await asaas("/customers", { method: "POST", body: JSON.stringify({ name: cli?.nome ?? "Cliente " + ped.codigo, mobilePhone: cli?.whatsapp, externalReference: ped.id }) });
  const venc = new Date(Date.now() + 86400000).toISOString().slice(0, 10);
  const cob = await asaas("/payments", { method: "POST", body: JSON.stringify({ customer: cliente.id, billingType: "PIX", value: Number(ped.total), dueDate: venc, description: "Pedido " + ped.codigo, externalReference: ped.id }) });
  const qr = await asaas(`/payments/${cob.id}/pixQrCode`);
  const { data: id, error } = await sb.rpc("pagamento_registrar", {
    p_pedido: ped.id, p_gateway: "asaas", p_provider: cob.id, p_metodo: "pix", p_pix: qr.payload ?? null, p_qr: qr.encodedImage ?? null,
    p_link: cob.invoiceUrl ?? null, p_expira: qr.expirationDate ? new Date(qr.expirationDate).toISOString() : new Date(Date.now() + 1800000).toISOString(),
    p_payload: { id: cob.id, status: cob.status },
  });
  if (error) throw new Error(error.message);
  return id as string;
}

Deno.serve(async (req) => {
  const h = { ...cors(req), "Content-Type": "application/json" };
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: h });
  if (req.method !== "POST") return J({}, 405, h);
  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const url = new URL(req.url);

  // ===== webhook do gateway =====
  if (url.searchParams.get("webhook") === "asaas") {
    if (!WH_TOKEN || req.headers.get("asaas-access-token") !== WH_TOKEN) return J({ erro: "assinatura" }, 401, h);
    const ev: any = await req.json().catch(() => null);
    if (!ev?.payment?.id) return J({ ok: true }, 200, h);
    const mapa: Record<string, string> = {
      PAYMENT_RECEIVED: "aprovado", PAYMENT_CONFIRMED: "aprovado", PAYMENT_OVERDUE: "expirado", PAYMENT_REFUNDED: "estornado",
      PAYMENT_CHARGEBACK_REQUESTED: "disputa", PAYMENT_DELETED: "expirado", PAYMENT_REPROVED_BY_RISK_ANALYSIS: "recusado",
    };
    const tipo = mapa[ev.event];
    if (!tipo) return J({ ok: true, ignorado: ev.event }, 200, h);
    const taxa = ev.payment.value != null && ev.payment.netValue != null ? Math.round((ev.payment.value - ev.payment.netValue) * 100) / 100 : null;
    const { data, error } = await sb.rpc("pagamento_webhook", {
      p_gateway: "asaas", p_evento_id: ev.id ?? (ev.payment.id + ":" + ev.event), p_provider_id: ev.payment.id, p_tipo: tipo, p_taxa: taxa,
      p_payload: { evento: ev.event, status: ev.payment.status },
    });
    if (error) return J({ erro: error.message }, 500, h);   // 500 faz o gateway reenviar
    return J({ ok: true, resultado: data }, 200, h);
  }

  if (!KEY) return J({ erro: "gateway_nao_configurado" }, 503, h);
  const c: any = await req.json().catch(() => null);
  if (!c?.acao) return J({ erro: "dados" }, 400, h);

  try {
    if (c.acao === "publico") {
      const { data: s } = await sb.rpc("pagamento_publico", { p_codigo: c.codigo, p_whatsapp: c.whatsapp, p_criar: false });
      if (!s?.disponivel && s?.gateway !== "asaas") return J(s ?? { disponivel: false }, 200, h);
      const { data: ped } = await sb.from("pedidos").select("id,status,forma_pagamento,clientes!inner(whatsapp)")
        .eq("codigo", String(c.codigo).toUpperCase()).eq("clientes.whatsapp", String(c.whatsapp).replace(/\D/g, "")).maybeSingle();
      if (ped && ped.status === "pendente" && ped.forma_pagamento === "pix") await cobrarPix(sb, ped.id);
      const { data: r } = await sb.rpc("pagamento_publico", { p_codigo: c.codigo, p_whatsapp: c.whatsapp, p_criar: false });
      return J(r, 200, h);
    }

    // ações do painel: valida o JWT e a permissão
    const jwt = (req.headers.get("authorization") ?? "").replace(/^Bearer /i, "");
    const { data: u } = await sb.auth.getUser(jwt);
    if (!u?.user) return J({ erro: "sessao" }, 401, h);
    const { data: ps } = await sb.from("admins").select("ativo,perfil_id,perfis(permissoes)").eq("user_id", u.user.id).maybeSingle();
    const perms: string[] = (ps as any)?.perfis?.permissoes ?? [];
    const pode = (p: string) => !!ps && (ps as any).ativo && (perms.includes("*") || perms.includes(p));

    if (c.acao === "cobrar") {
      if (!(pode("financeiro.gerir") || pode("pedidos.status"))) return J({ erro: "sem_permissao" }, 403, h);
      return J({ id: await cobrarPix(sb, c.pedido_id) }, 200, h);
    }
    if (c.acao === "estornar") {
      if (!pode("financeiro.gerir")) return J({ erro: "sem_permissao" }, 403, h);
      const { data: pg } = await sb.from("pagamentos").select("provider_id,gateway,status").eq("id", c.pagamento_id).single();
      if (!pg || pg.gateway !== "asaas" || pg.status !== "aprovado") return J({ erro: "nao_estornavel" }, 422, h);
      await asaas(`/payments/${pg.provider_id}/refund`, { method: "POST", body: "{}" });
      return J({ ok: true, aviso: "estorno pedido; o status muda quando o gateway confirmar (webhook)" }, 200, h);
    }
    return J({ erro: "acao" }, 400, h);
  } catch (e) {
    return J({ erro: String((e as Error).message ?? e) }, 422, h);
  }
});
