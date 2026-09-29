-- A1 - Plataforma de Streaming - Fatec Cotia (Bancos e Armazens de Dados)
-- Arquivo: 02_inserir_registros.sql   |   Item do trabalho: 9.3
-- Rode este arquivo inteiro e tire o print do resultado.

USE streaming_db;

-- =====================================================================
-- 9.3  INSERIR 10 REGISTROS EM CADA TABELA
-- =====================================================================

-- PLANO (10)
INSERT INTO plano (nome_plano, preco_mensal, qualidade_maxima, telas_simultaneas, permite_download) VALUES
('Basico com Anuncios', 18.90, 'SD',      1, FALSE),
('Basico',              25.90, 'HD',      1, TRUE),
('Padrao',              39.90, 'FULL_HD', 2, TRUE),
('Premium',             55.90, '4K',      4, TRUE),
('Familia',             69.90, '4K',      6, TRUE),
('Estudante',           19.90, 'HD',      1, TRUE),
('Mobile',              14.90, 'SD',      1, TRUE),
('Kids',                12.90, 'HD',      1, FALSE),
('Anual Padrao',        34.90, 'FULL_HD', 2, TRUE),
('Anual Premium',       49.90, '4K',      4, TRUE);

-- USUARIO (10) - senha guardada como hash SHA-256
INSERT INTO usuario (nome, email, senha_hash, data_nascimento, pais, data_cadastro) VALUES
('Ana Souza',        'ana.souza@email.com',        SHA2('Ana@2025',      256), '1990-05-14', 'BR', '2025-01-10 09:15:00'),
('Bruno Lima',       'bruno.lima@email.com',       SHA2('Bruno@2024',    256), '1985-11-02', 'BR', '2024-03-15 20:40:00'),
('Carla Mendes',     'carla.mendes@email.com',     SHA2('Carla@2025',    256), '1998-03-27', 'BR', '2025-02-20 14:05:00'),
('Diego Ferreira',   'diego.ferreira@email.com',   SHA2('Diego@2025',    256), '1992-08-09', 'BR', '2025-05-05 18:30:00'),
('Elisa Costa',      'elisa.costa@email.com',      SHA2('Elisa@2025',    256), '2001-01-30', 'PT', '2025-06-01 11:00:00'),
('Felipe Rocha',     'felipe.rocha@email.com',     SHA2('Felipe@2025',   256), '1979-06-18', 'BR', '2025-07-12 22:10:00'),
('Gabriela Nunes',   'gabriela.nunes@email.com',   SHA2('Gabi@2025',     256), '1995-12-05', 'BR', '2025-08-08 08:45:00'),
('Henrique Alves',   'henrique.alves@email.com',   SHA2('Henrique@2025', 256), '1988-09-21', 'AR', '2025-09-09 19:20:00'),
('Isabela Martins',  'isabela.martins@email.com',  SHA2('Isa@2026',      256), '2003-04-11', 'BR', '2026-02-14 10:00:00'),
('Joao Pereira',     'joao.pereira@email.com',     SHA2('Joao@2026',     256), '1983-07-07', 'BR', '2026-09-01 07:55:00');

-- ASSINATURA (10)
-- Bruno (2) tem uma assinatura cancelada e outra ativa -> mostra o (0,N)
-- Joao (10) ainda nao assinou nada                     -> mostra o minimo 0
-- Plano 'Anual Padrao' (9) nao tem assinantes           -> mostra o minimo 0 do plano
INSERT INTO assinatura (id_usuario, id_plano, data_inicio, data_fim, status, forma_pagamento) VALUES
(1,  4,  '2025-01-10', NULL,         'ATIVA',     'CARTAO'),
(2,  2,  '2024-03-15', '2025-02-28', 'CANCELADA', 'BOLETO'),
(2,  3,  '2025-03-01', NULL,         'ATIVA',     'PIX'),
(3,  6,  '2025-02-20', NULL,         'ATIVA',     'PIX'),
(4,  5,  '2025-05-05', NULL,         'ATIVA',     'CARTAO'),
(5,  10, '2025-06-01', '2026-05-31', 'ATIVA',     'CARTAO'),
(6,  1,  '2025-07-12', NULL,         'SUSPENSA',  'BOLETO'),
(7,  7,  '2025-08-08', NULL,         'ATIVA',     'PIX'),
(8,  3,  '2025-09-09', '2026-01-09', 'CANCELADA', 'CARTAO'),
(9,  8,  '2026-02-14', NULL,         'ATIVA',     'PIX');

-- PERFIL (10) - todo usuario tem ao menos um perfil -> (1,N)
INSERT INTO perfil (id_usuario, nome_perfil, idioma_preferido, classificacao_maxima, perfil_infantil) VALUES
(1,  'Ana',       'pt-BR', '18', FALSE),
(2,  'Bruno',     'pt-BR', '18', FALSE),
(3,  'Carla',     'pt-BR', '16', FALSE),
(4,  'Diego',     'pt-BR', '18', FALSE),
(5,  'Elisa',     'pt-PT', '18', FALSE),
(6,  'Felipe',    'pt-BR', '18', FALSE),
(7,  'Gabi',      'pt-BR', '14', FALSE),
(8,  'Henrique',  'es-AR', '18', FALSE),
(9,  'Isa Kids',  'pt-BR', '10', TRUE),
(10, 'Joao',      'pt-BR', '18', FALSE);

-- GENERO (10)
INSERT INTO genero (nome_genero, descricao) VALUES
('Acao',              'Cenas de combate, perseguicao e alta adrenalina'),
('Aventura',          'Jornadas e exploracao de lugares desconhecidos'),
('Comedia',           'Humor e situacoes engracadas'),
('Drama',             'Conflitos emocionais e relacoes humanas'),
('Ficcao Cientifica', 'Tecnologia, espaco e futuros possiveis'),
('Terror',            'Medo, suspense sobrenatural e tensao'),
('Romance',           'Relacoes amorosas'),
('Documentario',      'Conteudo baseado em fatos reais'),
('Animacao',          'Producoes animadas para todas as idades'),
('Suspense',          'Misterio e tensao psicologica');

-- CONTEUDO (10) - 6 filmes (com duracao) e 4 series (duracao NULL, vem dos episodios)
INSERT INTO conteudo (titulo, tipo, ano_lancamento, classificacao_indicativa, duracao_min, sinopse, data_adicao) VALUES
('Horizonte Perdido',   'FILME', 2021, '14', 118,  'Um piloto precisa atravessar um deserto hostil para salvar sua equipe.',            '2025-01-05'),
('A Ultima Fronteira',  'FILME', 2019, '12', 105,  'Exploradores buscam uma cidade escondida na cordilheira.',                          '2025-01-05'),
('Codigo Vermelho',     'FILME', 2023, '16', 127,  'Uma analista descobre uma conspiracao dentro da propria agencia.',                  '2025-03-20'),
('O Jardim das Mares',  'FILME', 2018, 'L',  96,   'Uma familia reconstroi a vida em uma vila de pescadores.',                          '2025-04-11'),
('Noite sem Fim',       'FILME', 2022, '18', 111,  'Hospedes de uma pousada isolada enfrentam uma presenca misteriosa.',                '2025-06-30'),
('Risadas em Familia',  'FILME', 2020, 'L',  89,   'Tres irmaos tentam organizar a festa surpresa perfeita para os pais.',              '2025-07-15'),
('Cidade Fragmentada',  'SERIE', 2021, '16', NULL, 'Em uma metropole dividida por muros, uma investigadora persegue a verdade.',        '2025-02-01'),
('Alem do Cosmos',      'SERIE', 2022, '12', NULL, 'A tripulacao de uma nave colonial recebe um sinal de origem desconhecida.',         '2025-05-18'),
('Segredos da Serra',   'SERIE', 2023, '14', NULL, 'Serie documental sobre comunidades tradicionais da Serra da Mantiqueira.',          '2025-08-22'),
('Turma do Bairro',     'SERIE', 2019, 'L',  NULL, 'Animacao sobre um grupo de amigos e suas aventuras no bairro.',                     '2025-09-10');

-- CONTEUDO_GENERO (10) - todo titulo tem ao menos 1 genero -> (1,N)
-- 'Acao' aparece em 2 titulos; 'Romance' ainda nao tem titulo -> mostra o minimo 0 do genero
INSERT INTO conteudo_genero (id_conteudo, id_genero) VALUES
(1, 1),   -- Horizonte Perdido  -> Acao
(2, 2),   -- A Ultima Fronteira -> Aventura
(3, 1),   -- Codigo Vermelho    -> Acao
(4, 4),   -- O Jardim das Mares -> Drama
(5, 6),   -- Noite sem Fim      -> Terror
(6, 3),   -- Risadas em Familia -> Comedia
(7, 10),  -- Cidade Fragmentada -> Suspense
(8, 5),   -- Alem do Cosmos     -> Ficcao Cientifica
(9, 8),   -- Segredos da Serra  -> Documentario
(10, 9);  -- Turma do Bairro    -> Animacao

-- EPISODIO (10) - apenas para as 4 series (ids 7 a 10)
INSERT INTO episodio (id_conteudo, numero_temporada, numero_episodio, titulo_episodio, duracao_min, data_lancamento) VALUES
(7,  1, 1, 'Ruinas',       48, '2021-03-05'),
(7,  1, 2, 'O Muro',       45, '2021-03-12'),
(7,  1, 3, 'Vozes',        50, '2021-03-19'),
(8,  1, 1, 'Partida',      52, '2022-06-10'),
(8,  1, 2, 'Orbita',       49, '2022-06-17'),
(8,  1, 3, 'Sinal',        55, '2022-06-24'),
(9,  1, 1, 'A Trilha',     38, '2023-02-03'),
(9,  1, 2, 'Nevoa',        41, '2023-02-10'),
(10, 1, 1, 'Primeiro Dia', 22, '2019-09-01'),
(10, 1, 2, 'A Pipa',       23, '2019-09-08');

-- HISTORICO_VISUALIZACAO (10)
-- filmes: id_episodio = NULL | series: id_episodio preenchido
-- Perfil 'Joao' (10) nunca assistiu nada e o filme 4 nunca foi assistido -> minimo 0
INSERT INTO historico_visualizacao (id_perfil, id_conteudo, id_episodio, data_hora_inicio, tempo_assistido_min, concluido) VALUES
(1, 7,  1,    '2026-09-01 20:00:00', 48,  TRUE),
(1, 7,  2,    '2026-09-02 20:30:00', 45,  TRUE),
(2, 1,  NULL, '2026-09-03 21:00:00', 118, TRUE),
(3, 8,  4,    '2026-09-04 19:15:00', 30,  FALSE),
(4, 3,  NULL, '2026-09-05 22:10:00', 60,  FALSE),
(5, 2,  NULL, '2026-09-06 18:00:00', 105, TRUE),
(6, 9,  7,    '2026-09-07 20:45:00', 38,  TRUE),
(7, 6,  NULL, '2026-09-08 16:20:00', 89,  TRUE),
(8, 5,  NULL, '2026-09-09 23:00:00', 40,  FALSE),
(9, 10, 9,    '2026-09-10 10:00:00', 22,  TRUE);

-- prints sugeridos (contagem por tabela = 10):
SELECT 'usuario' AS tabela, COUNT(*) AS registros FROM usuario
UNION ALL SELECT 'plano',                  COUNT(*) FROM plano
UNION ALL SELECT 'assinatura',             COUNT(*) FROM assinatura
UNION ALL SELECT 'perfil',                 COUNT(*) FROM perfil
UNION ALL SELECT 'conteudo',               COUNT(*) FROM conteudo
UNION ALL SELECT 'genero',                 COUNT(*) FROM genero
UNION ALL SELECT 'conteudo_genero',        COUNT(*) FROM conteudo_genero
UNION ALL SELECT 'episodio',               COUNT(*) FROM episodio
UNION ALL SELECT 'historico_visualizacao', COUNT(*) FROM historico_visualizacao;

SELECT * FROM plano;
SELECT * FROM historico_visualizacao;
