// Função de borda: verifica o Cloudflare Turnstile e só então cria o pedido.
// Entrada: { token, args } onde args são os parâmetros de public.criar_pedido.
// Segredos (supabase secrets set): TURNSTILE_SECRET. SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY já vêm no ambiente.
// Publicar com: supabase functions deploy criar-pedido --no-verify-jwt
import { createClient } from "npm:@supabase/supabase-js@2.45.0";

const ORIGENS = (Deno.env.get("ALLOWED_ORIGINS") ?? "https://martonnedias.github.io")
  .split(",").map((o) => o.trim());

function cors(req: Request) {
  const o = req.headers.get("origin") ?? "";
  return {
    "Access-Control-Allow-Origin": ORIGENS.includes(o) ? o : ORIGENS[0],
    "Access-Control-Allow-Headers": "apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

const CAMPOS = [
  "p_whatsapp", "p_quantidade", "p_nome", "p_data_nascimento", "p_email",
  "p_aceite_lgpd", "p_forma_pagamento", "p_endereco", "p_bairro", "p_observacao",
];

Deno.serve(async (req) => {
  const h = { ...cors(req), "Content-Type": "application/json" };
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: h });
  if (req.method !== "POST") return new Response("{}", { status: 405, headers: h });

  let corpo: { token?: string; args?: Record<string, unknown> };
  try { corpo = await req.json(); } catch { return new Response('{"erro":"json"}', { status: 400, headers: h }); }
  if (!corpo.token || !corpo.args) return new Response('{"erro":"dados"}', { status: 400, headers: h });

  const form = new FormData();
  form.append("secret", Deno.env.get("TURNSTILE_SECRET") ?? "");
  form.append("response", corpo.token);
  const ip = req.headers.get("cf-connecting-ip") ?? req.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  if (ip) form.append("remoteip", ip);
  const v = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", { method: "POST", body: form })
    .then((r) => r.json()).catch(() => ({ success: false }));
  if (!v.success) return new Response('{"erro":"robo"}', { status: 403, headers: h });

  // Repassa só os campos conhecidos de criar_pedido.
  const args: Record<string, unknown> = {};
  for (const k of CAMPOS) if (k in corpo.args) args[k] = corpo.args[k];

  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data, error } = await sb.rpc("criar_pedido", args);
  if (error) return new Response(JSON.stringify({ erro: error.message }), { status: 422, headers: h });
  return new Response(JSON.stringify(data), { status: 200, headers: h });
});
