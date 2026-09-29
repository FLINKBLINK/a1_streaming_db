-- A1 - Plataforma de Streaming - Fatec Cotia (Bancos e Armazens de Dados)
-- Arquivo: 04_alter_rename_coluna.sql   |   Item do trabalho: 9.5
-- Rode este arquivo inteiro e tire o print do resultado.

USE streaming_db;

-- =====================================================================
-- 9.5  ALTERAR O NOME DE UMA COLUNA EXISTENTE
--      Justificativa: deixar explicito que a data se refere a entrada do
--      titulo no catalogo (e nao a data de lancamento).
-- =====================================================================
ALTER TABLE conteudo
    RENAME COLUMN data_adicao TO data_adicao_catalogo;

-- (se o MySQL for 5.7, use a forma abaixo em vez da anterior)
-- ALTER TABLE conteudo CHANGE COLUMN data_adicao data_adicao_catalogo DATE NOT NULL;

DESCRIBE conteudo;
