-- A1 - Plataforma de Streaming - Fatec Cotia (Bancos e Armazens de Dados)
-- Arquivo: 07_delete.sql   |   Item do trabalho: 9.8
-- Rode este arquivo inteiro e tire o print do resultado.

USE streaming_db;

-- =====================================================================
-- 9.8  EXCLUIR UM DADO INSERIDO
--      Justificativa: o usuario pediu para remover um item do seu historico.
-- =====================================================================
SELECT * FROM historico_visualizacao WHERE id_historico = 5;               -- antes

DELETE FROM historico_visualizacao
 WHERE id_historico = 5;

SELECT * FROM historico_visualizacao;                                      -- depois (9 registros)

-- DEMONSTRACAO DA RESTRICAO DE INTEGRIDADE (opcional, bom para a apresentacao):
-- a linha abaixo FALHA de proposito (erro 1451), pois o plano 4 tem assinaturas.
-- DELETE FROM plano WHERE id_plano = 4;
