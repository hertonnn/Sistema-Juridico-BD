-- ==============================================================================
-- 0. LIMPEZA INICIAL (Para garantir que o script possa ser rodado várias vezes)
-- ==============================================================================
DROP TABLE IF EXISTS Processo_Lei CASCADE;
DROP TABLE IF EXISTS Processo_Advogado CASCADE;
DROP TABLE IF EXISTS Lei CASCADE;
DROP TABLE IF EXISTS Advogado CASCADE;
DROP TABLE IF EXISTS Tramite CASCADE;
DROP TABLE IF EXISTS Parte CASCADE;
DROP TABLE IF EXISTS Processo CASCADE;
DROP TABLE IF EXISTS Vara CASCADE;
DROP TABLE IF EXISTS Pessoa CASCADE;

-- ==============================================================================
-- 1. ESTRUTURA DO BANCO DE DADOS
-- ==============================================================================

-- Tabela 1: Pessoa
CREATE TABLE Pessoa (
    id_pessoa SERIAL PRIMARY KEY,
    primeiro_nome VARCHAR(50) NOT NULL,
    ultimo_nome VARCHAR(50) NOT NULL,
    cpf_cnpj VARCHAR(18) UNIQUE NOT NULL,
    tipo_pessoa VARCHAR(20) NOT NULL CHECK (tipo_pessoa IN ('Física', 'Jurídica')),
    sexo CHAR(1) CHECK (sexo IN ('M', 'F', 'N')), -- 'N' para Não Informado/Jurídica
    data_nascimento DATE
);

-- Tabela 2: Vara
CREATE TABLE Vara (
    id_vara SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    entrancia VARCHAR(50)
);

-- Tabela 3: Processo
CREATE TABLE Processo (
    id_processo SERIAL PRIMARY KEY,
    numero_processo VARCHAR(50) UNIQUE NOT NULL,
    tipo_processo VARCHAR(50) NOT NULL,
    assunto VARCHAR(255) NOT NULL,
    status VARCHAR(30) NOT NULL,
    data_inicio DATE NOT NULL,
    data_encerramento DATE,
    fk_id_vara INT NOT NULL,
    
    CONSTRAINT fk_processo_vara
        FOREIGN KEY (fk_id_vara) 
        REFERENCES Vara(id_vara)
        ON DELETE RESTRICT,
        
    CONSTRAINT chk_datas_processo 
        CHECK (data_encerramento IS NULL OR data_encerramento >= data_inicio)
);

-- Tabela 4: Parte (Tabela de Junção)
CREATE TABLE Parte (
    fk_id_pessoa INT NOT NULL,
    fk_id_processo INT NOT NULL,
    parte_tipo VARCHAR(50) NOT NULL, -- Autor, Réu, Perito, Reclamante, etc.
    
    CONSTRAINT fk_parte_pessoa
        FOREIGN KEY (fk_id_pessoa) 
        REFERENCES Pessoa(id_pessoa)
        ON DELETE RESTRICT,
        
    CONSTRAINT fk_parte_processo
        FOREIGN KEY (fk_id_processo) 
        REFERENCES Processo(id_processo)
        ON DELETE CASCADE,
        
    PRIMARY KEY (fk_id_pessoa, fk_id_processo, parte_tipo) -- Modificado para permitir que a mesma pessoa atue em papéis diferentes, se necessário.
);

-- Tabela 5: Tramite
CREATE TABLE Tramite (
    id_tramite SERIAL PRIMARY KEY,
    fk_id_processo INT NOT NULL,
    data_hora TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tipo VARCHAR(50) NOT NULL,
    descricao TEXT NOT NULL,
    
    CONSTRAINT fk_tramite_processo
        FOREIGN KEY (fk_id_processo) 
        REFERENCES Processo(id_processo)
        ON DELETE CASCADE
);

-- ==============================================================================
-- 2. ÍNDICES DE PERFORMANCE
-- ==============================================================================
CREATE INDEX idx_pessoa_cpf_cnpj ON Pessoa(cpf_cnpj);
CREATE INDEX idx_processo_numero ON Processo(numero_processo);
CREATE INDEX idx_processo_status ON Processo(status);
CREATE INDEX idx_tramite_processo ON Tramite(fk_id_processo);
CREATE INDEX idx_tramite_data ON Tramite(data_hora);

-- ==============================================================================
-- 3. INSERÇÃO DE DADOS (POVOAMENTO)
-- ==============================================================================

-- Inserindo Varas
INSERT INTO Vara (nome, tipo, entrancia) VALUES
('1ª Vara Cível de Joinville', 'Cível', 'Final'),
('Vara da Família de Joinville', 'Família', 'Final'),
('2ª Vara Criminal de Blumenau', 'Criminal', 'Intermediária'),
('1ª Vara do Trabalho de Joinville', 'Trabalhista', 'Especial'),
('3ª Vara da Fazenda Pública de Florianópolis', 'Fazenda Pública', 'Especial'),
('2ª Vara Federal de Curitiba', 'Federal', 'Especial'),
('Juizado Especial Cível de São José', 'JEC', 'Inicial');

-- Inserindo Pessoas (Físicas e Jurídicas)
INSERT INTO Pessoa (primeiro_nome, ultimo_nome, cpf_cnpj, tipo_pessoa, sexo, data_nascimento) VALUES
('Adriano', 'Silva', '123.456.789-10', 'Física', 'M', '2001-01-10'),
('Empresa ABC Ltda', '', '83.891.283/0001-36', 'Jurídica', NULL, NULL),
('Herton', 'Silveira', '987.654.321-00', 'Física', 'M', '2000-11-30'),
('Carlos', 'Mendes', '123.789.456-10', 'Física', 'M', '1985-04-12'),
('Ana', 'Maria', '123.654.789-00', 'Física', 'F', '1998-12-30'),
('Carlos Eduardo', 'Souza', '321.654.987-11', 'Física', 'M', '1990-05-22'),
('Banco Sul S/A', '', '12.345.678/0001-99', 'Jurídica', NULL, NULL),
('Mariana', 'Alcantara', '456.789.123-22', 'Física', 'F', '1982-10-15'),
('Estado de Santa Catarina', '', '82.951.222/0001-44', 'Jurídica', NULL, NULL),
('Roberto', 'Alencar', '789.123.456-33', 'Física', 'M', '1975-08-08'),
('Tech Soluções Ltda', '', '99.888.777/0001-55', 'Jurídica', NULL, NULL),
('Juliana', 'Ferreira', '111.222.333-44', 'Física', 'F', '1992-07-14'),
('Condomínio Edifício Central', '', '44.555.666/0001-77', 'Jurídica', NULL, NULL),
('Marcelo', 'Pereira', '555.666.777-88', 'Física', 'M', '1980-02-28'); -- Perito

-- Inserindo Processos
INSERT INTO Processo (numero_processo, tipo_processo, assunto, status, data_inicio, data_encerramento, fk_id_vara) VALUES
('0000001-15.2025.8.24.0038', 'Ação de Cobrança', 'Dívida Contratual', 'Em Andamento', '2025-01-15', NULL, 1),
('0000002-20.2025.8.24.0038', 'Divórcio Consensual', 'Dissolução de Casamento', 'Concluído', '2025-02-20', '2025-03-15', 2),
('5002314-82.2026.8.24.0038', 'Ação de Indenização', 'Danos Morais', 'Em Andamento', '2026-03-01', NULL, 1),
('0312455-19.2025.8.24.0038', 'Mandado de Segurança', 'Tributário', 'Julgado', '2025-08-10', '2026-01-20', 5),
('5019842-11.2026.8.24.0038', 'Ação Trabalhista', 'Rescisão Contratual', 'Suspenso', '2026-05-20', NULL, 4),
('5043321-44.2026.8.24.0023', 'Execução Fiscal', 'IPTU', 'Em Andamento', '2026-02-10', NULL, 5),
('0011223-99.2026.8.24.0090', 'Ação de Despejo', 'Falta de Pagamento', 'Em Andamento', '2026-06-05', NULL, 7);

-- Inserindo Partes (Relações Pessoa <-> Processo)
-- Processo 1: Empresa ABC cobra Carlos Mendes
INSERT INTO Parte (fk_id_pessoa, fk_id_processo, parte_tipo) VALUES
(2, 1, 'Autor'),
(4, 1, 'Réu');

-- Processo 2: Ana Maria e Carlos Mendes se divorciam
INSERT INTO Parte (fk_id_pessoa, fk_id_processo, parte_tipo) VALUES
(5, 2, 'Requerente'),
(4, 2, 'Requerido');

-- Processo 3: Carlos Eduardo contra Banco Sul
INSERT INTO Parte (fk_id_pessoa, fk_id_processo, parte_tipo) VALUES
(6, 3, 'Autor'),
(7, 3, 'Réu');

-- Processo 4: Mariana contra Estado de SC
INSERT INTO Parte (fk_id_pessoa, fk_id_processo, parte_tipo) VALUES
(8, 4, 'Impetrante'),
(9, 4, 'Impetrado');

-- Processo 5: Roberto contra Tech Soluções + Perito Marcelo
INSERT INTO Parte (fk_id_pessoa, fk_id_processo, parte_tipo) VALUES
(10, 5, 'Reclamante'),
(11, 5, 'Reclamada'),
(14, 5, 'Perito Judicial');

-- Processo 6: Estado de SC cobra Juliana
INSERT INTO Parte (fk_id_pessoa, fk_id_processo, parte_tipo) VALUES
(9, 6, 'Exequente'),
(12, 6, 'Executado');

-- Processo 7: Condomínio cobra múltiplos réus (Litisconsórcio)
INSERT INTO Parte (fk_id_pessoa, fk_id_processo, parte_tipo) VALUES
(13, 7, 'Autor'),
(1, 7, 'Réu'),
(3, 7, 'Réu');

-- Inserindo Trâmites (Histórico)
INSERT INTO Tramite (fk_id_processo, data_hora, tipo, descricao) VALUES
-- Trâmites Processo 1
(1, '2025-01-15 14:30:00-03', 'Petição Inicial', 'Distribuído livremente para a 1ª Vara Cível.'),
(1, '2025-02-01 10:00:00-03', 'Citação', 'Mandado de citação do réu expedido.'),
(1, '2025-03-05 17:45:00-03', 'Contestação', 'Réu apresenta defesa e documentos juntados aos autos.'),
(1, '2025-04-10 13:20:00-03', 'Impugnação', 'Autor apresenta réplica à contestação.'),

-- Trâmites Processo 2
(2, '2025-02-20 11:00:00-03', 'Petição Inicial', 'Recebida petição de divórcio consensual.'),
(2, '2025-03-15 09:30:00-03', 'Sentença', 'Homologado o acordo e decretado o divórcio das partes. Processo arquivado com baixa.'),

-- Trâmites Processo 3
(3, '2026-03-01 09:00:00-03', 'Petição Inicial', 'Ação de indenização por danos morais distribuída.'),
(3, '2026-03-15 14:00:00-03', 'Audiência Marcada', 'Audiência de conciliação agendada para 20/05/2026.'),
(3, '2026-05-20 16:00:00-03', 'Termo de Audiência', 'Conciliação inexitosa. Aberto prazo para contestação.'),

-- Trâmites Processo 4
(4, '2025-08-10 16:20:00-03', 'Mandado de Segurança', 'Impetrado mandado de segurança contra o Estado de SC.'),
(4, '2025-09-01 10:00:00-03', 'Informações', 'Autoridade coatora presta informações.'),
(4, '2025-10-15 14:00:00-03', 'Parecer MP', 'Ministério Público emite parecer favorável à concessão.'),
(4, '2026-01-20 13:45:00-03', 'Sentença', 'Concedida a segurança pleiteada.'),

-- Trâmites Processo 5
(5, '2026-05-20 10:15:00-03', 'Reclamação Trabalhista', 'Ajuizada reclamação trabalhista contra Tech Soluções Ltda.'),
(5, '2026-06-10 15:30:00-03', 'Despacho', 'Processo suspenso por 30 dias para tentativa de acordo entre as partes. Perito nomeado.'),

-- Trâmites Processo 6
(6, '2026-02-10 11:00:00-03', 'Petição Inicial', 'Execução fiscal de IPTU distribuída.'),
(6, '2026-04-05 09:00:00-03', 'Mandado', 'Expedido mandado de penhora e avaliação.'),

-- Trâmites Processo 7
(7, '2026-06-05 14:10:00-03', 'Petição Inicial', 'Ação de despejo protocolada pelo CondomínioEdifício Central.');


-- ==============================================================================
-- 1. NOVAS TABELAS E RELACIONAMENTOS (EXTENSÃO DO MODELO)
-- ==============================================================================

-- Tabela 6: Advogado
-- Especialização da tabela Pessoa (Herança/Relacionamento 1:1)
CREATE TABLE Advogado (
    fk_id_pessoa INT PRIMARY KEY,
    oab VARCHAR(20) UNIQUE NOT NULL,
    area_atuacao VARCHAR(50),
    
    CONSTRAINT fk_advogado_pessoa 
        FOREIGN KEY (fk_id_pessoa) 
        REFERENCES Pessoa(id_pessoa)
        ON DELETE RESTRICT
);

-- Tabela 7: Lei (Representando a Jurisprudência / Legislação)
CREATE TABLE Lei (
    id_lei SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    descricao TEXT NOT NULL
);

-- Tabela 8 (Nova - Essencial): Vinculo de Advogados no Processo
-- Liga o Advogado ao Processo e define quem ele está defendendo
CREATE TABLE Processo_Advogado (
    fk_id_advogado INT NOT NULL,
    fk_id_processo INT NOT NULL,
    fk_id_cliente INT NOT NULL, -- Pessoa (Cliente) que o advogado representa neste processo
    
    CONSTRAINT fk_proc_adv_advogado 
        FOREIGN KEY (fk_id_advogado) REFERENCES Advogado(fk_id_pessoa) ON DELETE RESTRICT,
    CONSTRAINT fk_proc_adv_processo 
        FOREIGN KEY (fk_id_processo) REFERENCES Processo(id_processo) ON DELETE CASCADE,
    CONSTRAINT fk_proc_adv_cliente 
        FOREIGN KEY (fk_id_cliente) REFERENCES Pessoa(id_pessoa) ON DELETE RESTRICT,
        
    PRIMARY KEY (fk_id_advogado, fk_id_processo, fk_id_cliente)
);

-- Tabela 9 (Nova - Essencial): Fundamentação Jurídica do Processo
-- Liga as leis invocas/utilizadas ao processo correspondente
CREATE TABLE Processo_Lei (
    fk_id_processo INT NOT NULL,
    fk_id_lei INT NOT NULL,
    artigo_paragrafo_especifico VARCHAR(100), -- Ex: "Art. 5º, inciso X" ou "Art. 186"
    
    CONSTRAINT fk_proclei_processo FOREIGN KEY (fk_id_processo) REFERENCES Processo(id_processo) ON DELETE CASCADE,
    CONSTRAINT fk_proclei_lei FOREIGN KEY (fk_id_lei) REFERENCES Lei(id_lei) ON DELETE RESTRICT,
    PRIMARY KEY (fk_id_processo, fk_id_lei)
);

-- Índices de Performance para as novas tabelas de junção
CREATE INDEX idx_proc_adv_processo ON Processo_Advogado(fk_id_processo);
CREATE INDEX idx_proc_lei_processo ON Processo_Lei(fk_id_processo);


-- ==============================================================================
-- 2. POVOAMENTO DOS NOVOS DADOS
-- ==============================================================================

-- Inserindo Pessoas que serão Advogados (CPFs alterados para evitar conflito com dados anteriores)
INSERT INTO Pessoa (primeiro_nome, ultimo_nome, cpf_cnpj, tipo_pessoa, sexo, data_nascimento) VALUES
('Carlos Eduardo', 'Pinheiro', '111.555.333-44', 'Física', 'M', '1980-01-01'),
('Mariana', 'Costa', '222.666.444-55', 'Física', 'F', '1985-02-02'),
('Felipe', 'Ramos', '333.777.555-66', 'Física', 'M', '1990-03-03'),
('Patrícia', 'Antunes', '444.888.666-77', 'Física', 'F', '1988-05-12'); -- Advogada extra

-- Vinculando na tabela de Advogados usando subqueries seguras baseadas nos novos CPFs
INSERT INTO Advogado (fk_id_pessoa, oab, area_atuacao) VALUES
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '111.555.333-44'), 'OAB/SC 12.345', 'Direito Civil'),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '222.666.444-55'), 'OAB/SP 67.890', 'Direito do Trabalho'),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '333.777.555-66'), 'OAB/PR 51.100', 'Direito Empresarial'),
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '444.888.666-77'), 'OAB/SC 99.123', 'Direito Tributário');

-- Inserindo Leis / Jurisprudência adicionais para cobrir os processos antigos
INSERT INTO Lei (titulo, descricao) VALUES
('Lei nº 13.709 (LGPD)', 'Lei Geral de Proteção de Dados Pessoais de 2018.'),
('Artigo 5º da Constituição', 'Dos Direitos e Garantias Fundamentais do cidadão.'),
('Lei nº 10.406 (Código Civil)', 'Regulamenta as relações civis de pessoas e bens.'),
('Decreto-Lei nº 5.452 (CLT)', 'Consolidação das Leis do Trabalho.'),
('Lei nº 8.245 (Lei do Inquilinato)', 'Dispõe sobre as locações dos imóveis urbanos e os procedimentos a elas pertinentes.');

-- Vinculando Advogados aos Processos e Clientes existentes
-- Relembrando IDs do histórico: Proc 1 (ABC vs Carlos Mendes), Proc 5 (Roberto vs Tech Soluções), Proc 7 (Condomínio vs Adriano e Herton)
INSERT INTO Processo_Advogado (fk_id_advogado, fk_id_processo, fk_id_cliente) VALUES
-- Advogado Carlos Pinheiro (id_pessoa via CPF) defendendo Carlos Mendes (id_pessoa=4) no Processo 1
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '111.555.333-44'), 1, 4),

-- Advogada Mariana Costa defendendo Roberto (id_pessoa=10) no Processo 5 (Trabalhista)
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '222.666.444-55'), 5, 10),

-- Advogado Felipe Ramos defendendo Tech Soluções Ltda (id_pessoa=11) no Processo 5 (Trabalhista)
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '333.777.555-66'), 5, 11),

-- Advogada Patrícia Antunes defendendo Adriano Silva (id_pessoa=1) no Processo 7 (Despejo)
((SELECT id_pessoa FROM Pessoa WHERE cpf_cnpj = '444.888.666-77'), 7, 1);

-- Vinculando Leis aos Processos (Fundamentação)
INSERT INTO Processo_Lei (fk_id_processo, fk_id_lei, artigo_paragrafo_especifico) VALUES
(1, (SELECT id_lei FROM Lei WHERE titulo = 'Lei nº 10.406 (Código Civil)'), 'Art. 389 (Inadimplemento das Obrigações)'), -- Processo 1 usa Código Civil
(5, (SELECT id_lei FROM Lei WHERE titulo = 'Decreto-Lei nº 5.452 (CLT)'), 'Art. 477 (Verbas Rescisórias)'),          -- Processo 5 usa CLT
(7, (SELECT id_lei FROM Lei WHERE titulo = 'Lei nº 8.245 (Lei do Inquilinato)'), 'Art. 59 (Do Despejo por falta de pgto)');  -- Processo 7 usa Lei do Inquilinato


-- ==============================================================================
-- 3. ADIÇÃO DE TRÂMITES COMPLEMENTARES (PROCESSOS 6 E 7)
-- ==============================================================================

-- Trâmites adicionais para movimentar o histórico
INSERT INTO Tramite (fk_id_processo, data_hora, tipo, descricao) VALUES
-- Continuação do Processo 6 (Execução Fiscal)
(6, '2026-05-18 10:00:00-03', 'Penhora', 'Aviso de bloqueio judicial de ativos financeiros via SISBAJUD (valores parciais).'),

-- Continuação do Processo 7 (Ação de Despejo)
(7, '2026-06-15 16:30:00-03', 'Despacho', 'Concedida a liminar para desocupação em 15 dias sob pena de despejo coercitivo.'),
(7, '2026-06-22 11:20:00-03', 'Citação e Intimação', 'Mandado cumprido pelo Oficial de Justiça no endereço do imóvel.');