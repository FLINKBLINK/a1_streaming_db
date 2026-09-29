-- A1 - Plataforma de Streaming - Fatec Cotia (Bancos e Armazens de Dados)
-- Arquivo: 00_criar_banco.sql   |   Item do trabalho: 9.1
-- Rode este arquivo inteiro e tire o print do resultado.

-- =====================================================================
-- 9.1  CRIAR O BANCO DE DADOS
-- =====================================================================
DROP DATABASE IF EXISTS streaming_db;
CREATE DATABASE streaming_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE streaming_db;

-- print sugerido:
SHOW DATABASES LIKE 'streaming_db';
