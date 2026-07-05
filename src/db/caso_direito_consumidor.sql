-- ==============================================================================
-- NOVO CASO: AÇÃO DE INDENIZAÇÃO (DIREITO DO CONSUMIDOR - PRODUTO COM DEFEITO)
-- ==============================================================================

-- 1. Inserindo uma nova Vara
INSERT INTO Vara (nome, tipo, entrancia) VALUES
('1º Juizado Especial Cível de Florianópolis', 'JEC', 'Inicial');

-- 2. Inserindo as novas Pessoas (Autor, Réu e Advogados)
INSERT INTO Pessoa (primeiro_nome, ultimo_nome, cpf_cnpj, tipo_pessoa, sexo, data_nascimento) VALUES
('Sérgio', 'Medeiros', '101.202.303-44', 'Física', 'M', '1985-07-12'), -- Autor (Consumidor)
('E-commerce Eletro S/A', '', '11.222.333/0001-44', 'Jurídica', NULL, NULL), -- Réu (Loja Online)
('Celso', 'Russomanco', '999.888.777-66', 'Física', 'F', '1990-08-20'), -- Advogado do Autor
('Roberto', 'Campos', '555.444.333-22', 'Física', 'M', '1982-11-15'); -- Advogado da Ré

-- 3. Registrando os novos Advogados
INSERT INTO Advogado (fk_id_pessoa, oab, area_atuacao) VALUES
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '999.888.777-66'), 'OAB/SC 45.678', 'Direito do Consumidor'),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '555.444.333-22'), 'OAB/SP 11.222', 'Direito Empresarial');

-- 4. Inserindo o novo Processo
INSERT INTO Processo (numero_processo, tipo_processo, assunto, status, data_inicio, data_encerramento, fk_id_vara) VALUES
('0005555-33.2026.8.24.0090', 'Ação de Indenização', 'Produto Defeituoso - Danos Morais e Materiais', 'Concluído', '2026-01-10', '2026-06-20', 
(SELECT id_vara FROM Vara WHERE nome = '1º Juizado Especial Cível de Florianópolis'));

-- 5. Vinculando as Partes ao Processo
INSERT INTO Parte (fk_id_pessoa, fk_id_processo, parte_tipo) VALUES
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '101.202.303-44'), (SELECT id_processo FROM Processo WHERE numero_processo = '0005555-33.2026.8.24.0090'), 'Autor'),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '11.222.333/0001-44'), (SELECT id_processo FROM Processo WHERE numero_processo = '0005555-33.2026.8.24.0090'), 'Réu');

-- 6. Vinculando os Advogados aos seus Clientes no Processo
INSERT INTO Processo_Advogado (fk_id_advogado, fk_id_processo, fk_id_cliente) VALUES
-- Advogada Marina defendendo o Autor Sérgio
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '999.888.777-66'), (SELECT id_processo FROM Processo WHERE numero_processo = '0005555-33.2026.8.24.0090'), (SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '101.202.303-44')),
-- Advogado Roberto defendendo a Loja E-commerce Eletro S/A
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '555.444.333-22'), (SELECT id_processo FROM Processo WHERE numero_processo = '0005555-33.2026.8.24.0090'), (SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '11.222.333/0001-44'));

-- 7. Inserindo a Lei (CDC) e Fundamentando o Processo
INSERT INTO Lei (titulo, descricao) VALUES
('Lei nº 8.078 (CDC)', 'Código de Defesa do Consumidor.');

INSERT INTO Processo_Lei (fk_id_processo, fk_id_lei, artigo_paragrafo_especifico) VALUES
((SELECT id_processo FROM Processo WHERE numero_processo = '0005555-33.2026.8.24.0090'), 
 (SELECT id_lei FROM Lei WHERE titulo = 'Lei nº 8.078 (CDC)'), 'Art. 18 (Responsabilidade por vício do produto)');

-- 8. Inserindo os 6 Trâmites do Processo (Linha do tempo lógica)
INSERT INTO Tramite (fk_id_processo, data_hora, tipo, descricao) VALUES
((SELECT id_processo FROM Processo WHERE numero_processo = '0005555-33.2026.8.24.0090'), '2026-01-10 14:15:00-03', 'Petição Inicial', 'Ação distribuída. Autor alega compra de geladeira com defeito no motor, sem solução pela assistência técnica após 30 dias. Requer restituição do valor pago e danos morais.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0005555-33.2026.8.24.0090'), '2026-01-15 10:30:00-03', 'Citação e Intimação', 'Expedida carta de citação com AR para a empresa ré, com data designada para audiência de conciliação.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0005555-33.2026.8.24.0090'), '2026-02-20 16:00:00-03', 'Termo de Audiência', 'Audiência de conciliação realizada. Proposta de acordo pela ré (troca do produto) recusada pelo autor, que exige a devolução do dinheiro.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0005555-33.2026.8.24.0090'), '2026-03-05 17:45:00-03', 'Contestação', 'Ré apresenta defesa tempestiva alegando que o defeito ocorreu por mau uso do consumidor (oscilação de energia na residência).'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0005555-33.2026.8.24.0090'), '2026-05-10 13:20:00-03', 'Sentença', 'Pedido julgado PROCEDENTE. Condenação da ré à devolução de R$ 3.500,00 (valor do produto) e ao pagamento de R$ 3.000,00 a título de danos morais pela privação de bem essencial.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0005555-33.2026.8.24.0090'), '2026-06-20 09:00:00-03', 'Trânsito em Julgado', 'Certificado o decurso do prazo de 10 dias sem interposição de Recurso Inominado por nenhuma das partes. Processo baixado e arquivado.');