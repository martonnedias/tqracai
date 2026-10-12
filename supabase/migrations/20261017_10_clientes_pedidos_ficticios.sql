-- TQR Açaí · clientes, endereços, pedidos, caixa e pontos FICTÍCIOS (continuação da 09)
-- Os pedidos passam pelo fluxo real de status, então o financeiro e os pontos são gerados pelos gatilhos.
-- O contador público é neutralizado em contador_ajuste (ver final) para as vendas de exemplo não inflarem o número do site.
do $$
declare
  p record; tr uuid;
  pid uuid; cid uuid; bid uuid; q int; sub numeric; tx numeric; tot numeric; dias int; cod text; forma text; st text;
  qtd_total int := 0; i int := 0;
begin
  if exists (select 1 from public.clientes where observacoes = '[EXEMPLO]') then return; end if;
  select id into tr from public.produtos where nome = 'Açaí tradicional 300 ml';

  -- clientes
  insert into public.clientes (whatsapp, nome, data_nascimento, observacoes, aceite_lgpd_em) values
   ('5586999000001','Ana Souza (exemplo)',  date '1992-03-14','[EXEMPLO]', now()),
   ('5586999000002','Bruno Lima (exemplo)', date '1988-11-02','[EXEMPLO]', now()),
   ('5586999000003','Carla Mendes (exemplo)', date '1995-07-21','[EXEMPLO]', now()),
   ('5586999000004','Diego Rocha (exemplo)', date '1990-12-05','[EXEMPLO]', now()),
   ('5586999000005','Elisa Prado (exemplo)', date '1985-05-30','[EXEMPLO]', now()),
   ('5586999000006','Felipe Alves (exemplo)', date '2000-09-18','[EXEMPLO]', now());

  -- endereços
  insert into public.enderecos_cliente (cliente_id, apelido, rua, complemento, bairro, bairro_id, referencia, padrao)
  select cl.id, v.apelido, v.rua, v.compl, v.bairro, (select id from public.bairros_entrega b where b.nome = v.bairro), v.ref, v.padrao
  from (values
   ('5586999000001','Casa','Rua Exemplo, 100','Apto 12','Jóquei','Perto da praça',true),
   ('5586999000001','Trabalho','Av. Modelo, 2500','Sala 3','Centro','Edifício azul',false),
   ('5586999000002','Casa','Rua Teste, 45',null,'Fátima',null,true),
   ('5586999000003','Casa','Rua Amostra, 880','Casa 2','Ininga','Portão verde',true),
   ('5586999000004','Casa','Rua Fictícia, 12',null,'São Cristóvão',null,true)
  ) as v(zap, apelido, rua, compl, bairro, ref, padrao)
  join public.clientes cl on cl.whatsapp = v.zap;

  -- pedidos: (cliente, dias atrás, qtd, modalidade, bairro, forma, status final)
  for p in select * from (values
   (1, 85, 3, 'entrega_bairro', 'Jóquei',  'pix',      'entregue'),
   (2, 80, 1, 'retirada',       null,      'dinheiro', 'entregue'),
   (3, 70, 5, 'entrega_bairro', 'Ininga',  'pix',      'entregue'),
   (1, 62, 2, 'entrega_bairro', 'Centro',  'cartao',   'entregue'),
   (4, 55, 6, 'entrega_bairro', 'São Cristóvão','pix', 'entregue'),
   (5, 48, 3, 'retirada',       null,      'pix',      'entregue'),
   (2, 40, 4, 'entrega_bairro', 'Fátima',  'cartao',   'entregue'),
   (3, 33, 2, 'entrega_app',    null,      'pix',      'entregue'),
   (1, 25, 3, 'entrega_bairro', 'Jóquei',  'pix',      'entregue'),
   (6, 18, 1, 'retirada',       null,      'dinheiro', 'cancelado'),
   (4, 12, 5, 'entrega_bairro', 'São Cristóvão','pix', 'entregue'),
   (5,  7, 3, 'retirada',       null,      'cartao',   'entregue'),
   (2,  3, 2, 'entrega_bairro', 'Fátima',  'pix',      'saiu_entrega'),
   (3,  2, 4, 'entrega_bairro', 'Ininga',  'pix',      'pago'),
   (1,  1, 3, 'entrega_bairro', 'Jóquei',  'pix',      'confirmado'),
   (6,  0, 1, 'entrega_app',    null,      'pix',      'pendente')
  ) as t(ci, dias, qtd, modal, bairro, forma, st)
  loop
    i := i + 1;
    select id into cid from public.clientes where whatsapp = '558699900000' || p.ci;
    select b.id, b.taxa into bid, tx from public.bairros_entrega b where b.nome = p.bairro;
    tx := case when p.modal = 'entrega_bairro' then coalesce(tx, 0) else 0 end;
    sub := p.qtd * 16.99;
    tot := case when p.qtd = 3 then 42.00 when p.qtd >= 5 then p.qtd * 14.00 else sub end;
    if p.qtd >= 5 then tx := 0; end if;
    cod := 'TQR-' || lpad(nextval('public.pedido_codigo_seq')::text, 4, '0');
    insert into public.pedidos (codigo, cliente_id, total, forma_pagamento, endereco, bairro, observacao, origem,
                                modalidade, bairro_id, subtotal, desconto, taxa_entrega, criado_em, atualizado_em)
    values (cod, cid, tot + tx, p.forma, case when p.modal = 'retirada' then null else 'Endereço de exemplo' end,
            p.bairro, '[EXEMPLO]', 'site', p.modal, case when p.modal = 'entrega_bairro' then bid end,
            sub, sub - tot, tx, now() - make_interval(days => p.dias), now() - make_interval(days => p.dias))
    returning id into pid;
    insert into public.itens_pedido (pedido_id, produto_id, quantidade, subtotal, preco_unitario, nome_produto)
    values (pid, tr, p.qtd, tot, round(tot / p.qtd, 2), 'Açaí tradicional 300 ml');

    -- percorre o fluxo de status para os gatilhos gerarem caixa e pontos
    if p.st in ('confirmado','pago','saiu_entrega','entregue') then update public.pedidos set status = 'confirmado' where id = pid; end if;
    if p.st in ('pago','saiu_entrega','entregue') then update public.pedidos set status = 'pago' where id = pid; end if;
    if p.st in ('saiu_entrega','entregue') then update public.pedidos set status = 'saiu_entrega' where id = pid; end if;
    if p.st = 'entregue' then update public.pedidos set status = 'entregue' where id = pid; end if;
    if p.st = 'cancelado' then update public.pedidos set status = 'cancelado' where id = pid; end if;
    if p.st in ('pago','saiu_entrega','entregue') then qtd_total := qtd_total + p.qtd; end if;

    -- datas do caixa e dos pontos acompanham a data do pedido
    update public.lancamentos set data = (now() - make_interval(days => p.dias))::date, criado_em = now() - make_interval(days => p.dias)
      where pedido_id = pid;
    update public.livro_pontos set criado_em = now() - make_interval(days => p.dias) where pedido_id = pid;
    update public.pedidos set atualizado_em = now() - make_interval(days => p.dias) where id = pid;
  end loop;

  -- pontos extras de exemplo
  insert into public.livro_pontos (cliente_id, tipo, pontos, motivo)
  select id, 'ajuste', 30, '[EXEMPLO] bônus de boas-vindas' from public.clientes where whatsapp = '5586999000001';

  -- despesas de exemplo (3 meses)
  insert into public.lancamentos (tipo, categoria_id, descricao, valor, data, pago, pago_em)
  select 'saida', v.cat, '[EXEMPLO] ' || v.descr, v.valor, d.dia, true, d.dia
  from (values
   ('aluguel','Aluguel do ponto', 300.00), ('energia_agua','Energia, água e internet', 110.00),
   ('pessoal','Ajudante', 220.00), ('insumos','Compra de polpa de açaí', 150.00),
   ('embalagem','Garrafas e tampas', 55.00), ('marketing','Anúncios Instagram', 40.00),
   ('entrega','Combustível', 30.00)
  ) as v(cat, descr, valor)
  cross join (select (date_trunc('month', now() at time zone 'America/Fortaleza') - make_interval(months => m) + interval '9 days')::date as dia
              from generate_series(1, 3) m) d;
  insert into public.lancamentos (tipo, categoria_id, descricao, valor, data, vencimento, pago)
  values ('saida','aluguel','[EXEMPLO] Aluguel do próximo mês', 300.00, (now() at time zone 'America/Fortaleza')::date,
          ((now() at time zone 'America/Fortaleza')::date + 7), false),
         ('saida','insumos','[EXEMPLO] Fornecedor de polpa (a pagar)', 180.00, (now() at time zone 'America/Fortaleza')::date,
          ((now() at time zone 'America/Fortaleza')::date + 3), false);

  -- contador público: neutraliza as garrafas de exemplo
  update public.configuracoes set valor = (valor::int - qtd_total)::text where chave = 'contador_ajuste';
end $$;
