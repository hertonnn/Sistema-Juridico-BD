-- ==============================================================================
-- NOVO CASO: AÇÃO DE RESCISÃO CONTRATUAL C/C DANOS MORAIS (CASO DE TV)
-- ==============================================================================

-- 1. Inserindo uma nova Vara (Foro Regional da Barra Funda - SP, próximo à Record)
INSERT INTO Vara (nome, tipo, entrancia) VALUES
('Juizado Especial Cível - Foro Regional Barra Funda', 'JEC', 'Inicial');

-- 2. Inserindo as novas Pessoas (Autor, Réu, Celso Russomanno e Advogado da Ré)
INSERT INTO Pessoa (primeiro_nome, ultimo_nome, cpf_cnpj, tipo_pessoa, sexo, data_nascimento) VALUES
('Maria Aparecida', 'das Dores', '777.888.999-01', 'Física', 'F', '1955-03-10'), -- Autora (Consumidora lesada)
('Auto Premium Multimarcas', '', '44.555.666/0002-88', 'Jurídica', NULL, NULL), -- Réu (Agência de Carros)
('Celso', 'Russomanno', '100.200.300-40', 'Física', 'M', '1956-08-20'), -- Advogado da Autora
('Valdir', 'Saboia', '222.333.444-50', 'Física', 'M', '1978-12-05'); -- Advogado da Ré

-- 3. Registrando os novos Advogados
INSERT INTO Advogado (fk_id_pessoa, oab, area_atuacao) VALUES
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '100.200.300-40'), 'OAB/SP 123.456', 'Direito do Consumidor'),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '222.333.444-50'), 'OAB/SP 654.321', 'Direito Cível');

-- 4. Inserindo o novo Processo
INSERT INTO Processo (numero_processo, tipo_processo, assunto, status, data_inicio, data_encerramento, fk_id_vara) VALUES
('0001900-50.2026.8.26.0004', 'Rescisão Contratual', 'Vício Oculto - Veículo Usado - Danos Morais', 'Concluído', '2026-03-10', '2026-06-30', 
(SELECT id_vara FROM Vara WHERE nome = 'Juizado Especial Cível - Foro Regional Barra Funda'));

-- 5. Vinculando as Partes ao Processo
INSERT INTO Parte (fk_id_pessoa, fk_id_processo, parte_tipo) VALUES
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '777.888.999-01'), (SELECT id_processo FROM Processo WHERE numero_processo = '0001900-50.2026.8.26.0004'), 'Autor'),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '44.555.666/0002-88'), (SELECT id_processo FROM Processo WHERE numero_processo = '0001900-50.2026.8.26.0004'), 'Réu');

-- 6. Vinculando os Advogados aos seus Clientes no Processo
INSERT INTO Processo_Advogado (fk_id_advogado, fk_id_processo, fk_id_cliente) VALUES
-- Celso Russomanno defendendo a Dona Maria
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '100.200.300-40'), (SELECT id_processo FROM Processo WHERE numero_processo = '0001900-50.2026.8.26.0004'), (SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '777.888.999-01')),
-- Valdir Saboia defendendo a Agência Auto Premium
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '222.333.444-50'), (SELECT id_processo FROM Processo WHERE numero_processo = '0001900-50.2026.8.26.0004'), (SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '44.555.666/0002-88'));

-- 7. Inserindo a Lei e Fundamentando o Processo
-- Garantindo que o CDC exista caso a tabela tenha sido zerada, ou ignorando se já existir
INSERT INTO Lei (titulo, descricao) 
SELECT 'Lei nº 8.078 (CDC)', 'Código de Defesa do Consumidor.'
WHERE NOT EXISTS (SELECT 1 FROM Lei WHERE titulo = 'Lei nº 8.078 (CDC)');

INSERT INTO Processo_Lei (fk_id_processo, fk_id_lei, artigo_paragrafo_especifico) VALUES
((SELECT id_processo FROM Processo WHERE numero_processo = '0001900-50.2026.8.26.0004'), 
 (SELECT id_lei FROM Lei WHERE titulo = 'Lei nº 8.078 (CDC)'), 'Art. 18 (Vício Oculto) e Art. 37 (Propaganda Enganosa)');

-- 8. Inserindo os Trâmites do Processo (O drama televisionado levado aos autos com Celso Russomanno)
INSERT INTO Tramite (fk_id_processo, data_hora, tipo, descricao) VALUES
((SELECT id_processo FROM Processo WHERE numero_processo = '0001900-50.2026.8.26.0004'), 
 '2026-03-10 11:00:00-03', 
 'Petição Inicial', 
 'Ação ajuizada. Autora relata compra de veículo que fundiu o motor no 2º dia. Anexado pendrive com a reportagem do programa Patrulha do Consumidor, conduzida por Celso Russomanno, mostrando o gerente da loja fugindo pela porta dos fundos ao ser questionado. A petição assinada por Celso requer devolução imediata do valor e danos morais.'),

((SELECT id_processo FROM Processo WHERE numero_processo = '0001900-50.2026.8.26.0004'), 
 '2026-03-12 14:30:00-03', 
 'Decisão Interlocutória', 
 'Deferida tutela de urgência. Juiz determina o bloqueio via SISBAJUD de R$ 25.000,00 nas contas da agência ré, dado o evidente risco de dilapidação de patrimônio evidenciado nas gravações apresentadas pela equipe de Celso Russomanno.'),

((SELECT id_processo FROM Processo WHERE numero_processo = '0001900-50.2026.8.26.0004'), 
 '2026-04-15 15:00:00-03', 
 'Termo de Audiência', 
 'Audiência de conciliação inexitosa. O advogado da ré ofereceu o conserto do motor mediante pagamento de 50% das peças pela autora. A proposta foi veementemente rechaçada pelo advogado Celso Russomanno, que bateu na mesa exigindo o cumprimento integral do Artigo 18 do CDC perante o conciliador.'),

((SELECT id_processo FROM Processo WHERE numero_processo = '0001900-50.2026.8.26.0004'), 
 '2026-04-30 17:15:00-03', 
 'Contestação', 
 'Ré apresenta defesa alegando que o vídeo anexado aos autos foi editado de forma sensacionalista pelo programa de Celso Russomanno e que o veículo foi vendido "no estado em que se encontrava", transferindo o risco ao comprador.'),

((SELECT id_processo FROM Processo WHERE numero_processo = '0001900-50.2026.8.26.0004'), 
 '2026-06-05 13:40:00-03', 
 'Sentença', 
 'Ação julgada PROCEDENTE. Magistrado afasta a tese de "venda no estado" (prática ilegal). Condena a ré a restituir o valor do veículo (R$ 25.000,00) e indenização de R$ 10.000,00 por danos morais, citando a conduta abusiva contra a idosa que foi perfeitamente documentada na petição e nos vídeos juntados por Celso Russomanno.'),

((SELECT id_processo FROM Processo WHERE numero_processo = '0001900-50.2026.8.26.0004'), 
 '2026-06-30 10:00:00-03', 
 'Alvará Expedido', 
 'Transferência do valor bloqueado (R$ 35.000,00) para a conta da autora. Processo extinto pelo cumprimento da obrigação. Comprovante de encerramento encaminhado aos cuidados do escritório de Celso Russomanno.');