-- A1 - Plataforma de Streaming - Fatec Cotia (Bancos e Armazens de Dados)
-- Arquivo: 03_alter_add_coluna.sql   |   Item do trabalho: 9.4
-- Rode este arquivo inteiro e tire o print do resultado.

USE streaming_db;

-- =====================================================================
-- 9.4  INSERIR UMA NOVA COLUNA
--      Justificativa: a plataforma passou a enviar codigo de verificacao
--      por SMS, entao o usuario precisa de um telefone de contato.
-- =====================================================================
ALTER TABLE usuario
    ADD COLUMN telefone VARCHAR(20) NULL AFTER email;

DESCRIBE usuario;
