-- A1 - Plataforma de Streaming - Fatec Cotia (Bancos e Armazens de Dados)
-- Arquivo: 06_update.sql   |   Item do trabalho: 9.7
-- Rode este arquivo inteiro e tire o print do resultado.

USE streaming_db;

-- =====================================================================
-- 9.7  ALTERAR UM DADO INSERIDO
--      Justificativa: reajuste de preco do plano Premium.
-- =====================================================================
SELECT id_plano, nome_plano, preco_mensal FROM plano WHERE id_plano = 4;   -- antes

UPDATE plano
   SET preco_mensal = 59.90
 WHERE id_plano = 4;

SELECT id_plano, nome_plano, preco_mensal FROM plano WHERE id_plano = 4;   -- depois
