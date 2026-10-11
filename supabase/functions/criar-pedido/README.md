# criar-pedido (proteção contra robôs)

Passos, nesta ordem (o site continua funcionando em cada etapa):

1. Cloudflare: Turnstile → Add site → domínio `martonnedias.github.io` (e o domínio próprio depois). Guarde a *site key* (pública) e a *secret key*.
2. `supabase secrets set TURNSTILE_SECRET=<secret key> --project-ref elaczoriyaejkixkubxn`
   (opcional) `ALLOWED_ORIGINS=https://martonnedias.github.io,https://tqracai.com.br`
3. `supabase functions deploy criar-pedido --no-verify-jwt --project-ref elaczoriyaejkixkubxn`
4. No `index.html`, `window.TQR_TURNSTILE='<site key>'`; suba o arquivo e faça um pedido de teste.
5. Só depois de confirmar que o pedido com Turnstile funciona, aplique `supabase/opcional/fechar_criar_pedido_anonimo.sql`.
   Antes disso, qualquer pessoa ainda consegue chamar `criar_pedido` direto, contornando o Turnstile.

Se o Turnstile não carregar (bloqueador, falha de rede), o site abre o WhatsApp sem código de pedido, como já fazia quando o banco falhava.
Atenção LGPD: o Turnstile é da Cloudflare; a política de privacidade já cita o serviço.
