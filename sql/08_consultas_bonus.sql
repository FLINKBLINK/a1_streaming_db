-- A1 - Plataforma de Streaming - Fatec Cotia (Bancos e Armazens de Dados)
-- Arquivo: 08_consultas_bonus.sql   |   Item do trabalho: bonus (opcional)
-- Rode este arquivo inteiro e tire o print do resultado.

USE streaming_db;

-- =====================================================================
-- BONUS (opcional) - consultas para mostrar o modelo funcionando
-- =====================================================================

-- Quem assistiu o que (JOIN em 5 tabelas)
SELECT u.nome            AS usuario,
       p.nome_perfil     AS perfil,
       c.titulo,
       c.tipo,
       CONCAT('T', e.numero_temporada, 'E', e.numero_episodio, ' - ', e.titulo_episodio) AS episodio,
       h.data_hora_inicio,
       h.tempo_assistido_min,
       h.concluido
  FROM historico_visualizacao h
  JOIN perfil   p ON p.id_perfil   = h.id_perfil
  JOIN usuario  u ON u.id_usuario  = p.id_usuario
  JOIN conteudo c ON c.id_conteudo = h.id_conteudo
  LEFT JOIN episodio e ON e.id_episodio = h.id_episodio
 ORDER BY h.data_hora_inicio;

-- Titulos por genero (mostra o genero sem titulo: Romance)
SELECT g.nome_genero, COUNT(cg.id_conteudo) AS qtd_titulos
  FROM genero g
  LEFT JOIN conteudo_genero cg ON cg.id_genero = g.id_genero
 GROUP BY g.nome_genero
 ORDER BY qtd_titulos DESC, g.nome_genero;

-- Receita mensal das assinaturas ativas por plano
SELECT pl.nome_plano, COUNT(a.id_assinatura) AS assinantes_ativos,
       SUM(pl.preco_mensal) AS receita_mensal
  FROM assinatura a
  JOIN plano pl ON pl.id_plano = a.id_plano
 WHERE a.status = 'ATIVA'
 GROUP BY pl.nome_plano
 ORDER BY receita_mensal DESC;
