// Função de borda: gerencia usuários e perfis do painel. Só o perfil "dono" pode chamar.
// Precisa da chave de serviço (SUPABASE_SERVICE_ROLE_KEY, já presente no ambiente das funções); nunca vai para o navegador.
// Publicar com: supabase functions deploy admin-usuarios --project-ref elaczoriyaejkixkubxn
// (mantenha a verificação de JWT ligada: o painel envia o token do usuário logado).
import { createClient } from "npm:@supabase/supabase-js@2.45.0";

const PERMISSOES = [
  "pedidos.ver", "pedidos.criar", "pedidos.status", "pedidos.status_entrega", "pedidos.cancelar", "pedidos.editar",
  "clientes.ver", "clientes.editar", "produtos.gerir", "promocoes.gerir", "config.gerir", "financeiro.ver", "financeiro.gerir",
  "custos.ver", "custos.gerir", "estoque.ver", "estoque.gerir",
];

const ORIGENS = (Deno.env.get("ALLOWED_ORIGINS") ?? "https://martonnedias.github.io").split(",").map((o) => o.trim());

function cors(req: Request) {
  const o = req.headers.get("origin") ?? "";
  return {
    "Access-Control-Allow-Origin": ORIGENS.includes(o) ? o : ORIGENS[0],
    "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false },
});

class Erro extends Error {
  constructor(public codigo: string, public status = 400) { super(codigo); }
}

function jwtAal(token: string): string {
  try {
    const p = JSON.parse(atob(token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")));
    return String(p.aal ?? "aal1");
  } catch { return "aal1"; }
}

async function exigirDono(req: Request) {
  const token = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) throw new Erro("nao_autenticado", 401);
  const { data, error } = await sb.auth.getUser(token);
  if (error || !data.user) throw new Erro("nao_autenticado", 401);
  const { data: adm } = await sb.from("admins").select("perfil_id, ativo").eq("user_id", data.user.id).maybeSingle();
  if (!adm || !adm.ativo || adm.perfil_id !== "dono") throw new Erro("sem_permissao", 403);
  // Quem cadastrou verificação em duas etapas precisa ter entrado com o código.
  const { data: fat } = await sb.auth.admin.mfa.listFactors({ userId: data.user.id });
  const temMfa = (fat?.factors ?? []).some((f: { status: string }) => f.status === "verified");
  if (temMfa && jwtAal(token) !== "aal2") throw new Erro("mfa_necessario", 401);
  return data.user.id;
}

function texto(v: unknown, min: number, max: number, campo: string): string {
  const s = String(v ?? "").trim();
  if (s.length < min || s.length > max) throw new Erro("invalido:" + campo);
  return s;
}

async function donosAtivos(): Promise<number> {
  const { count } = await sb.from("admins").select("user_id", { count: "exact", head: true }).eq("perfil_id", "dono").eq("ativo", true);
  return count ?? 0;
}

async function perfilExiste(id: string) {
  const { data } = await sb.from("perfis").select("id").eq("id", id).maybeSingle();
  if (!data) throw new Erro("perfil_inexistente");
}

async function listar() {
  const { data: admins, error } = await sb.from("admins").select("user_id, perfil_id, nome, ativo, criado_em").order("criado_em");
  if (error) throw new Erro("falha_banco", 500);
  const { data: lista } = await sb.auth.admin.listUsers({ page: 1, perPage: 200 });
  const emails = new Map((lista?.users ?? []).map((u) => [u.id, u.email]));
  const { data: perfis } = await sb.from("perfis").select("*").order("sistema", { ascending: false }).order("nome");
  return {
    usuarios: (admins ?? []).map((a) => ({ ...a, email: emails.get(a.user_id) ?? "" })),
    perfis: perfis ?? [],
    permissoes: PERMISSOES,
  };
}

async function criar(b: Record<string, unknown>) {
  const email = texto(b.email, 5, 120, "email").toLowerCase();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw new Erro("invalido:email");
  const nome = texto(b.nome, 2, 80, "nome");
  const senha = texto(b.senha, 10, 72, "senha");
  const perfil = texto(b.perfil_id, 2, 31, "perfil_id");
  await perfilExiste(perfil);
  const { data, error } = await sb.auth.admin.createUser({ email, password: senha, email_confirm: true });
  if (error || !data.user) throw new Erro(error?.message?.includes("already") ? "email_ja_cadastrado" : "falha_criar_usuario");
  const { error: e2 } = await sb.from("admins").insert({ user_id: data.user.id, perfil_id: perfil, nome });
  if (e2) { await sb.auth.admin.deleteUser(data.user.id); throw new Erro("falha_banco", 500); }
  return { user_id: data.user.id };
}

async function atualizar(b: Record<string, unknown>, eu: string) {
  const id = texto(b.user_id, 36, 36, "user_id");
  const campos: Record<string, unknown> = {};
  if (b.nome !== undefined) campos.nome = texto(b.nome, 2, 80, "nome");
  if (b.perfil_id !== undefined) { campos.perfil_id = texto(b.perfil_id, 2, 31, "perfil_id"); await perfilExiste(String(campos.perfil_id)); }
  if (b.ativo !== undefined) campos.ativo = Boolean(b.ativo);
  const { data: atual } = await sb.from("admins").select("perfil_id, ativo").eq("user_id", id).maybeSingle();
  if (!atual) throw new Erro("usuario_inexistente", 404);
  const deixaDeSerDono = atual.perfil_id === "dono" && atual.ativo &&
    ((campos.perfil_id !== undefined && campos.perfil_id !== "dono") || campos.ativo === false);
  if (deixaDeSerDono) {
    if (id === eu) throw new Erro("nao_pode_em_si_mesmo");
    if ((await donosAtivos()) <= 1) throw new Erro("precisa_de_um_dono");
  }
  if (id === eu && campos.ativo === false) throw new Erro("nao_pode_em_si_mesmo");
  const { error } = await sb.from("admins").update(campos).eq("user_id", id);
  if (error) throw new Erro("falha_banco", 500);
  if (campos.ativo !== undefined) {
    // desativado também não consegue mais entrar
    await sb.auth.admin.updateUserById(id, { ban_duration: campos.ativo ? "none" : "876000h" });
  }
  return {};
}

async function redefinirSenha(b: Record<string, unknown>) {
  const id = texto(b.user_id, 36, 36, "user_id");
  const senha = texto(b.senha, 10, 72, "senha");
  const { error } = await sb.auth.admin.updateUserById(id, { password: senha });
  if (error) throw new Erro("falha_senha");
  return {};
}

async function salvarPerfil(b: Record<string, unknown>) {
  const id = texto(b.id, 2, 31, "id");
  if (!/^[a-z][a-z0-9_]{1,30}$/.test(id)) throw new Erro("invalido:id");
  const nome = texto(b.nome, 2, 40, "nome");
  const descricao = String(b.descricao ?? "").trim().slice(0, 200) || null;
  const perms = Array.isArray(b.permissoes) ? b.permissoes.map(String) : [];
  if (perms.some((p) => !PERMISSOES.includes(p))) throw new Erro("permissao_invalida");
  const { data: atual } = await sb.from("perfis").select("sistema").eq("id", id).maybeSingle();
  if (!perms.length) throw new Erro("invalido:permissoes");
  if (atual?.sistema) {
    // perfis do sistema: o dono (acesso total) é fixo; nos demais só as permissões e a descrição podem mudar (código, nome e a marca "sistema" não)
    if (id === "dono") throw new Erro("perfil_de_sistema");
    const { error } = await sb.from("perfis").update({ descricao, permissoes: [...new Set(perms)] }).eq("id", id);
    if (error) throw new Erro("falha_banco", 500);
    return {};
  }
  const { error } = await sb.from("perfis").upsert({ id, nome, descricao, permissoes: [...new Set(perms)], sistema: false });
  if (error) throw new Erro("falha_banco", 500);
  return {};
}

async function excluirPerfil(b: Record<string, unknown>) {
  const id = texto(b.id, 2, 31, "id");
  const { data: atual } = await sb.from("perfis").select("sistema").eq("id", id).maybeSingle();
  if (!atual) throw new Erro("perfil_inexistente", 404);
  if (atual.sistema) throw new Erro("perfil_de_sistema");
  const { count } = await sb.from("admins").select("user_id", { count: "exact", head: true }).eq("perfil_id", id);
  if ((count ?? 0) > 0) throw new Erro("perfil_em_uso");
  const { error } = await sb.from("perfis").delete().eq("id", id);
  if (error) throw new Erro("falha_banco", 500);
  return {};
}

Deno.serve(async (req) => {
  const h = { ...cors(req), "Content-Type": "application/json" };
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: h });
  if (req.method !== "POST") return new Response("{}", { status: 405, headers: h });
  try {
    const eu = await exigirDono(req);
    const b = await req.json().catch(() => ({}));
    let r: unknown;
    switch (b.acao) {
      case "listar": r = await listar(); break;
      case "criar": r = await criar(b); break;
      case "atualizar": r = await atualizar(b, eu); break;
      case "redefinir_senha": r = await redefinirSenha(b); break;
      case "perfil_salvar": r = await salvarPerfil(b); break;
      case "perfil_excluir": r = await excluirPerfil(b); break;
      default: throw new Erro("acao_invalida");
    }
    return new Response(JSON.stringify(r), { status: 200, headers: h });
  } catch (e) {
    const er = e instanceof Erro ? e : new Erro("erro_interno", 500);
    return new Response(JSON.stringify({ erro: er.codigo }), { status: er.status, headers: h });
  }
});
