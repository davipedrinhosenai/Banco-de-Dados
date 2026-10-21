CREATE TABLE pacientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    cpf VARCHAR(11) UNIQUE NOT NULL,
    data_nascimento DATE NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE especialidades (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE medicos (
    id SERIAL PRIMARY KEY,
    especialidade_id INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    crm VARCHAR(20) UNIQUE NOT NULL,
    valor_consulta NUMERIC(10, 2) NOT NULL CHECK (valor_consulta > 0),
    
    CONSTRAINT fk_medico_especialidade 
        FOREIGN KEY (especialidade_id) 
        REFERENCES especialidades(id) 
        ON DELETE RESTRICT
);

CREATE TABLE consultas (
    id SERIAL PRIMARY KEY,
    medico_id INT NOT NULL,
    paciente_id INT NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'Agendada' CHECK (status IN ('Agendada', 'Realizada', 'Cancelada')),
    
    CONSTRAINT fk_consulta_medico 
        FOREIGN KEY (medico_id) 
        REFERENCES medicos(id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_consulta_paciente 
        FOREIGN KEY (paciente_id) 
        REFERENCES pacientes(id) 
        ON DELETE CASCADE
);

CREATE TABLE exames_consulta (
    id SERIAL PRIMARY KEY,
    consulta_id INT NOT NULL,
    nome_exame VARCHAR(100) NOT NULL,
    valor_exame NUMERIC(10, 2) NOT NULL CHECK (valor_exame >= 0),
    
    CONSTRAINT fk_exame_consulta 
        FOREIGN KEY (consulta_id) 
        REFERENCES consultas(id) 
        ON DELETE CASCADE
);

INSERT INTO especialidades (nome) VALUES 
('Cardiologia'),
('Pediatria'),
('Dermatologia');

INSERT INTO medicos (especialidade_id, nome, crm, valor_consulta) VALUES 
(1, 'Dra. Manuela Urbano', 'CRM/SC 123456', 350.00),
(2, 'Dr. Miguel Guirado', 'CRM/SC 654321', 250.00),
(3, 'Dr. Lucca Felicio', 'CRM/SC 789123', 300.00);

INSERT INTO pacientes (nome, email, cpf, data_nascimento) VALUES 
('Guilherme Ribeiro', 'gui.ribeiro@email.com', '11122233344', '1985-05-12'),
('Nicolas Gabriel', 'nicolas.gabriel@email.com', '55566677788', '2010-08-25'),
('João Gabriel', 'joao.gabriel@email.com', '99900011122', '1998-11-03');

INSERT INTO consultas (medico_id, paciente_id, data_hora, status) VALUES 
(1, 1, '2026-03-10 09:00:00', 'Realizada'),
(1, 3, '2026-03-10 10:30:00', 'Realizada'),
(2, 2, '2026-03-11 14:00:00', 'Realizada'),
(3, 1, '2026-03-12 11:00:00', 'Agendada');

INSERT INTO exames_consulta (consulta_id, nome_exame, valor_exame) VALUES 
(1, 'Eletrocardiograma', 120.00),
(1, 'Ecocardiograma', 250.00),
(2, 'Hemograma Completo', 45.00),
(3, 'Exame de Urina', 30.00);

-- =================================================================
-- CONSULTAS ORIGINAIS
-- =================================================================

-- 1.
SELECT 
    medicos.nome AS medico,
    medicos.crm,
    especialidades.nome AS especialidade,
    medicos.valor_consulta
FROM medicos
INNER JOIN especialidades ON medicos.especialidade_id = especialidades.id
ORDER BY medicos.valor_consulta DESC;

-- 2.
SELECT 
    consultas.id AS consulta_id,
    consultas.data_hora,
    medicos.nome AS medico,
    especialidades.nome AS especialidade,
    consultas.status
FROM consultas
INNER JOIN pacientes ON consultas.paciente_id = pacientes.id
INNER JOIN medicos ON consultas.medico_id = medicos.id
INNER JOIN especialidades ON medicos.especialidade_id = especialidades.id
WHERE pacientes.nome = 'Carlos Silva'
ORDER BY consultas.data_hora ASC;

-- 3.
SELECT 
    consultas.id AS consulta_id,
    pacientes.nome AS paciente,
    medicos.nome AS medico,
    medicos.valor_consulta,
    COALESCE(SUM(exames_consulta.valor_exame), 0.00) AS total_exames,
    (medicos.valor_consulta + COALESCE(SUM(exames_consulta.valor_exame), 0.00)) AS valor_total_atendimento
FROM consultas
INNER JOIN pacientes ON consultas.paciente_id = pacientes.id
INNER JOIN medicos ON consultas.medico_id = medicos.id
LEFT JOIN exames_consulta ON consultas.id = exames_consulta.consulta_id
GROUP BY consultas.id, pacientes.nome, medicos.nome, medicos.valor_consulta
ORDER BY consultas.id;

-- 4.
SELECT 
    medicos.nome AS medico,
    medicos.crm,
    especialidades.nome AS especialidade,
    medicos.valor_consulta
FROM medicos
INNER JOIN especialidades ON medicos.especialidade_id = especialidades.id
WHERE medicos.valor_consulta > 300.00;

-- 5.
SELECT 
    especialidades.nome AS especialidade,
    COUNT(consultas.id) AS quantidade_consultas,
    COALESCE(SUM(medicos.valor_consulta), 0.00) AS faturamento_consultas
FROM especialidades
INNER JOIN medicos ON especialidades.id = medicos.especialidade_id
LEFT JOIN consultas ON medicos.id = consultas.medico_id AND consultas.status = 'Realizada'
GROUP BY especialidades.id, especialidades.nome
ORDER BY faturamento_consultas DESC;

-- =================================================================
-- CRIAÇÃO E CHAMADA DAS VIEWS
-- =================================================================

-- View 1: Médicos e Especialidades
CREATE OR REPLACE VIEW vw_medicos_especialidades AS
SELECT 
    medicos.nome AS medico,
    medicos.crm,
    especialidades.nome AS especialidade,
    medicos.valor_consulta
FROM medicos
INNER JOIN especialidades ON medicos.especialidade_id = especialidades.id;

-- Execução da View 1:
SELECT * FROM vw_medicos_especialidades ORDER BY valor_consulta DESC;


-- View 2: Histórico de Consultas dos Pacientes
CREATE OR REPLACE VIEW vw_historico_consultas_pacientes AS
SELECT 
    consultas.id AS consulta_id,
    pacientes.nome AS paciente,
    consultas.data_hora,
    medicos.nome AS medico,
    especialidades.nome AS especialidade,
    consultas.status
FROM consultas
INNER JOIN pacientes ON consultas.paciente_id = pacientes.id
INNER JOIN medicos ON consultas.medico_id = medicos.id
INNER JOIN especialidades ON medicos.especialidade_id = especialidades.id;

-- Execução da View 2 (Filtrando por paciente específico):
SELECT consulta_id, data_hora, medico, especialidade, status
FROM vw_historico_consultas_pacientes
WHERE paciente = 'Carlos Silva'
ORDER BY data_hora ASC;


-- View 3: Valor Total dos Atendimentos
CREATE OR REPLACE VIEW vw_valor_total_atendimentos AS
SELECT 
    consultas.id AS consulta_id,
    pacientes.nome AS paciente,
    medicos.nome AS medico,
    medicos.valor_consulta,
    COALESCE(SUM(exames_consulta.valor_exame), 0.00) AS total_exames,
    (medicos.valor_consulta + COALESCE(SUM(exames_consulta.valor_exame), 0.00)) AS valor_total_atendimento
FROM consultas
INNER JOIN pacientes ON consultas.paciente_id = pacientes.id
INNER JOIN medicos ON consultas.medico_id = medicos.id
LEFT JOIN exames_consulta ON consultas.id = exames_consulta.consulta_id
GROUP BY consultas.id, pacientes.nome, medicos.nome, medicos.valor_consulta;

-- Execução da View 3:
SELECT * FROM vw_valor_total_atendimentos ORDER BY consulta_id;


-- View 4: Médicos com Consulta Acima de R$ 300,00
CREATE OR REPLACE VIEW vw_medicos_consulta_acima_300 AS
SELECT 
    medicos.nome AS medico,
    medicos.crm,
    especialidades.nome AS especialidade,
    medicos.valor_consulta
FROM medicos
INNER JOIN especialidades ON medicos.especialidade_id = especialidades.id
WHERE medicos.valor_consulta > 300.00;

-- Execução da View 4:
SELECT * FROM vw_medicos_consulta_acima_300;


-- View 5: Faturamento por Especialidade
CREATE OR REPLACE VIEW vw_faturamento_por_especialidade AS
SELECT 
    especialidades.nome AS especialidade,
    COUNT(consultas.id) AS quantidade_consultas,
    COALESCE(SUM(medicos.valor_consulta), 0.00) AS faturamento_consultas
FROM especialidades
INNER JOIN medicos ON especialidades.id = medicos.especialidade_id
LEFT JOIN consultas ON medicos.id = consultas.medico_id AND consultas.status = 'Realizada'
GROUP BY especialidades.id, especialidades.nome;

-- Execução da View 5:
SELECT * FROM vw_faturamento_por_especialidade ORDER BY faturamento_consultas DESC;
