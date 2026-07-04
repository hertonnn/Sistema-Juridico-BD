-- ==============================================================================
-- CASO: O GRANDE GOLPE DA VAPORTECH
-- ==============================================================================

-- 1. CADASTRO DOS ENVOLVIDOS (PESSOAS E EMPRESAS)
INSERT INTO Pessoa (primeiro_nome, ultimo_nome, cpf_cnpj, tipo_pessoa, sexo, data_nascimento) VALUES
-- Autores
('Leopoldo', 'Strauss', '999.888.777-11', 'Física', 'M', '1965-03-12'),
('Alpha Capital S/A', '', '11.222.333/0001-44', 'Jurídica', NULL, NULL),
-- Réus
('Maximilian', 'Von Crypto', '555.444.333-22', 'Física', 'M', '1995-10-31'),
('Offshore Ventures Inc', '', '99.888.999/0001-00', 'Jurídica', NULL, NULL),
('João', 'das Neves', '123.321.123-99', 'Física', 'M', '1980-05-15'),
-- Advogados
('Arnaldo', 'Coimbra', '000.111.222-33', 'Física', 'M', '1970-08-20'),
('Beatriz', 'Solano', '111.222.333-99', 'Física', 'F', '1982-11-11'),
('Carlos', 'Matos', '222.333.444-88', 'Física', 'M', '1975-06-06'),
('Dante', 'Alighieri', '333.444.555-77', 'Física', 'M', '1960-01-01');

-- 2. CADASTRO DOS ADVOGADOS (ESPECIALIZAÇÃO)
INSERT INTO Advogado (fk_id_pessoa, oab, area_atuacao) VALUES
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '000.111.222-33'), 'OAB/SC 10.001', 'Direito Societário'),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '111.222.333-99'), 'OAB/SP 88.002', 'Direito Financeiro'),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '222.333.444-88'), 'OAB/RJ 55.003', 'Direito Digital'),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '333.444.555-77'), 'OAB/MG 33.004', 'Direito Penal Empresarial');

-- 3. CRIAÇÃO DO PROCESSO
INSERT INTO Processo (numero_processo, tipo_processo, assunto, status, data_inicio, data_encerramento, fk_id_vara) VALUES
('0099887-77.2026.8.24.0038', 'Indenizatória c/c Dissolução', 'Fraude Societária e Desvio de PI', 'Em Andamento', '2026-01-10', NULL, 1);

-- 4. VINCULAÇÃO DAS PARTES AO PROCESSO
INSERT INTO Parte (fk_id_pessoa, fk_id_processo, parte_tipo) VALUES
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '999.888.777-11'), (SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), 'Autor'),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '11.222.333/0001-44'), (SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), 'Autor'),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '555.444.333-22'), (SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), 'Réu'),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '99.888.999/0001-00'), (SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), 'Réu'),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '123.321.123-99'), (SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), 'Réu');

-- 5. VINCULAÇÃO DOS ADVOGADOS (MÚLTIPLAS REPRESENTAÇÕES)
INSERT INTO Processo_Advogado (fk_id_advogado, fk_id_processo, fk_id_cliente) VALUES
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '000.111.222-33'), (SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), (SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '999.888.777-11')),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '111.222.333-99'), (SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), (SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '11.222.333/0001-44')),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '222.333.444-88'), (SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), (SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '555.444.333-22')),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '222.333.444-88'), (SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), (SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '99.888.999/0001-00')),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '333.444.555-77'), (SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), (SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '123.321.123-99'));

-- 6. INSERÇÃO DO HISTÓRICO DE TRÂMITES (O DRAMA JURÍDICO)
INSERT INTO Tramite (fk_id_processo, data_hora, tipo, descricao) VALUES
((SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), '2026-01-10 10:00:00-03', 'Petição Inicial', 'Ação de indenização por quebra de fidúcia societária e fraude, com pedido de tutela de urgência antecipada para bloqueio de bens.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), '2026-01-12 15:30:00-03', 'Decisão Interlocutória', 'Deferida a liminar cautelar. Determinado o bloqueio on-line de R$ 5.000.000,00 via SISBAJUD nas contas dos réus.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), '2026-01-20 14:00:00-03', 'Agravo de Instrumento', 'Réu Maximilian ingressa com Agravo alegando que o bloqueio recaiu sobre verbas alimentares e inviabiliza a operação da empresa.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), '2026-02-05 09:15:00-03', 'Citação por Edital', 'Expedido edital de citação da ré Offshore Ventures Inc, com sede em paraíso fiscal, após tentativas frustradas via carta rogatória.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), '2026-03-10 17:45:00-03', 'Contestação', 'Réu João das Neves apresenta contestação, levantando incidente de falsidade documental. Alega que sua assinatura no contrato social foi forjada.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), '2026-03-25 11:00:00-03', 'Despacho', 'Nomeado perito judicial grafotécnico. Partes intimadas para apresentar quesitos.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), '2026-05-18 16:20:00-03', 'Laudo Pericial', 'Juntado laudo pericial. Conclusão: a assinatura NÃO é falsa, tendo sido emanada do próprio punho de João das Neves.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), '2026-06-01 13:00:00-03', 'Exceção de Incompetência', 'Offshore Ventures protocola incidente arguindo incompetência da justiça brasileira devido a cláusula de arbitragem internacional.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), '2026-06-15 15:40:00-03', 'Decisão', 'Rejeitada a exceção. Magistrado afasta a cláusula de arbitragem devido a indícios cristalinos de fraude à lei brasileira.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), '2026-08-10 14:00:00-03', 'Audiência de Instrução', 'Realizada oitiva de testemunhas. Ex-desenvolvedor confessa sob juramento que o software prometido não existia e era uma maquete com um roteador escondido.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), '2026-08-30 18:00:00-03', 'Alegações Finais', 'Autores reiteram o pedido de condenação. Réus pedem a nulidade das provas orais.'),
((SELECT id_processo FROM Processo WHERE numero_processo = '0099887-77.2026.8.24.0038'), '2026-09-15 09:30:00-03', 'Conclusos para Sentença', 'Autos remetidos ao gabinete do Juiz para prolação da sentença.');
