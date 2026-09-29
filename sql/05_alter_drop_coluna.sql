-- A1 - Plataforma de Streaming - Fatec Cotia (Bancos e Armazens de Dados)
-- Arquivo: 05_alter_drop_coluna.sql   |   Item do trabalho: 9.6
-- Rode este arquivo inteiro e tire o print do resultado.

USE streaming_db;

-- =====================================================================
-- 9.6  EXCLUIR UMA COLUNA
--      Justificativa: o nome do genero ja e autoexplicativo; a descricao
--      nao era usada pela interface e foi removida.
-- =====================================================================
ALTER TABLE genero
    DROP COLUMN descricao;

DESCRIBE genero;
SELECT * FROM genero;
