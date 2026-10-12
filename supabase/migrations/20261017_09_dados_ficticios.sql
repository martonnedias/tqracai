-- TQR Açaí · dados FICTÍCIOS de demonstração (para o dono trocar pelos reais depois)
-- Tudo aqui é exemplo. Identificação: clientes com observação '[EXEMPLO]' e WhatsApp 55869990000xx,
-- pedidos/lançamentos com '[EXEMPLO]' na observação/descrição. Para remover: supabase/opcional/remover_dados_ficticios.sql
-- Catálogo (produtos, bairros, formas, promoções) é editável direto no painel.

-- ===== Produtos =====
insert into public.produtos (nome, volume_ml, preco, descricao, categoria, ordem, ativo)
select v.* from (values
 ('Açaí com granola 300 ml', 300, 18.99, 'Açaí cremoso com granola crocante (exemplo)', 'Açaí', 1, true),
 ('Açaí zero açúcar 300 ml', 300, 19.99, 'Sem açúcar adicionado (exemplo)', 'Açaí', 2, true),
 ('Açaí tradicional 500 ml', 500, 26.90, 'Garrafa maior para dividir (exemplo)', 'Açaí', 3, true),
 ('Cupuaçu 300 ml', 300, 15.99, 'Polpa de cupuaçu (exemplo)', 'Polpas', 4, true)
) as v(nome, volume_ml, preco, descricao, categoria, ordem, ativo)
where not exists (select 1 from public.produtos p where p.nome = v.nome);

-- ===== Bairros (taxas de exemplo) =====
insert into public.bairros_entrega (nome, taxa, ordem) values
 ('Centro', 5.00, 1), ('Jóquei', 7.00, 2), ('Fátima', 8.00, 3), ('Ininga', 8.00, 4),
 ('São Cristóvão', 9.00, 5), ('Ilhotas', 6.00, 6), ('Santa Isabel', 10.00, 7), ('Dirceu', 12.00, 8)
on conflict (nome) do nothing;

-- ===== Formas de pagamento (taxas de exemplo) =====
update public.formas_pagamento set taxa_percentual = 3.99, instrucoes = 'Link de pagamento ou maquininha na entrega.' where id = 'cartao';
insert into public.formas_pagamento (id, nome, ordem, taxa_percentual, instrucoes) values
 ('dinheiro', 'Dinheiro', 3, 0, 'Pagamento na entrega. Avise se precisa de troco.')
on conflict (id) do nothing;

-- ===== Promoções e cupons de exemplo (nenhuma nova aparece na vitrine; só os cupons/regras valem no pedido) =====
insert into public.promocoes (nome, tipo, regra, ativo, codigo, primeira_compra, prioridade)
select 'Cupom BEMVINDO10 (10% na 1ª compra)', 'desconto_percentual', '{"percentual":10}'::jsonb, true, 'BEMVINDO10', true, 5
where not exists (select 1 from public.promocoes where lower(codigo) = 'bemvindo10');
insert into public.promocoes (nome, tipo, regra, ativo, codigo, dias_semana, prioridade)
select 'Cupom SEXTOU5 (R$ 5 off às sextas)', 'desconto_valor', '{"valor":5}'::jsonb, true, 'SEXTOU5', array[5], 4
where not exists (select 1 from public.promocoes where lower(codigo) = 'sextou5');
insert into public.promocoes (nome, tipo, regra, ativo, min_valor, prioridade)
select 'Frete grátis acima de R$ 80', 'frete_gratis', '{}'::jsonb, true, 80, 3
where not exists (select 1 from public.promocoes where nome = 'Frete grátis acima de R$ 80');
insert into public.promocoes (nome, tipo, regra, ativo, min_valor, prioridade)
select 'Brinde: 1 Cupuaçu acima de R$ 150', 'brinde',
  jsonb_build_object('produto_id', (select id from public.produtos where nome = 'Cupuaçu 300 ml'), 'qtd', 1), true, 150, 2
where not exists (select 1 from public.promocoes where nome = 'Brinde: 1 Cupuaçu acima de R$ 150');
insert into public.promocoes (nome, tipo, regra, ativo, prioridade)
select 'Leve 4, pague 3 (tradicional)', 'leve_pague',
  jsonb_build_object('leve', 4, 'pague', 3, 'produto_id', (select id from public.produtos where nome = 'Açaí tradicional 300 ml')), false, 1
where not exists (select 1 from public.promocoes where nome = 'Leve 4, pague 3 (tradicional)');

-- ===== Aviso de exemplo (desligado) =====
update public.configuracoes set valor = 'Hoje tem açaí gelado até a meia-noite! (exemplo)' where chave = 'aviso_site' and valor = '';
