-- =====================================================================
--  FATEC COTIA - Ciencia de Dados - Bancos e Armazens de Dados (A1)
--  Tema ....: Plataforma de Streaming
--  Grupo ...: Lucas Rodrigues
--  SGBD ....: MySQL 8.0 ou superior (MySQL Workbench)
--
--  COMO USAR: execute um bloco por vez (selecione o bloco + Ctrl+Enter)
--  e tire o print do resultado de cada item (9.1 a 9.8) para o PPT.
--  Ordem dos INSERTs respeita as chaves estrangeiras.
-- =====================================================================


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


-- =====================================================================
-- 9.2  CRIAR AS TABELAS (tipos, tamanhos, PK, FK, restricoes)
-- =====================================================================

-- 1) USUARIO - titular da conta
CREATE TABLE usuario (
    id_usuario       INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    nome             VARCHAR(100)     NOT NULL,
    email            VARCHAR(150)     NOT NULL,
    senha_hash       CHAR(64)         NOT NULL COMMENT 'SHA-256 em hexadecimal',
    data_nascimento  DATE             NOT NULL,
    pais             CHAR(2)          NOT NULL DEFAULT 'BR' COMMENT 'ISO 3166-1 alpha-2',
    data_cadastro    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_usuario),
    UNIQUE KEY uk_usuario_email (email)
) ENGINE = InnoDB;

-- 2) PLANO - modalidades de assinatura
CREATE TABLE plano (
    id_plano           TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome_plano         VARCHAR(50)      NOT NULL,
    preco_mensal       DECIMAL(8,2)     NOT NULL,
    qualidade_maxima   ENUM('SD','HD','FULL_HD','4K') NOT NULL,
    telas_simultaneas  TINYINT UNSIGNED NOT NULL,
    permite_download   BOOLEAN          NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_plano),
    UNIQUE KEY uk_plano_nome (nome_plano),
    CONSTRAINT ck_plano_preco CHECK (preco_mensal > 0),
    CONSTRAINT ck_plano_telas CHECK (telas_simultaneas BETWEEN 1 AND 10)
) ENGINE = InnoDB;

-- 3) ASSINATURA - contratacao de um plano por um usuario
CREATE TABLE assinatura (
    id_assinatura    INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    id_usuario       INT UNSIGNED     NOT NULL,
    id_plano         TINYINT UNSIGNED NOT NULL,
    data_inicio      DATE             NOT NULL,
    data_fim         DATE             NULL,
    status           ENUM('ATIVA','SUSPENSA','CANCELADA') NOT NULL DEFAULT 'ATIVA',
    forma_pagamento  ENUM('CARTAO','PIX','BOLETO')        NOT NULL,
    PRIMARY KEY (id_assinatura),
    CONSTRAINT fk_assinatura_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_assinatura_plano   FOREIGN KEY (id_plano)
        REFERENCES plano (id_plano)     ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_assinatura_datas CHECK (data_fim IS NULL OR data_fim >= data_inicio)
) ENGINE = InnoDB;

-- 4) PERFIL - perfis dentro de uma conta
CREATE TABLE perfil (
    id_perfil             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    id_usuario            INT UNSIGNED  NOT NULL,
    nome_perfil           VARCHAR(50)   NOT NULL,
    idioma_preferido      CHAR(5)       NOT NULL DEFAULT 'pt-BR',
    classificacao_maxima  ENUM('L','10','12','14','16','18') NOT NULL DEFAULT '18',
    perfil_infantil       BOOLEAN       NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_perfil),
    UNIQUE KEY uk_perfil_usuario_nome (id_usuario, nome_perfil),
    CONSTRAINT fk_perfil_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- 5) CONTEUDO - titulo do catalogo (filme ou serie)
CREATE TABLE conteudo (
    id_conteudo               INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    titulo                    VARCHAR(150)  NOT NULL,
    tipo                      ENUM('FILME','SERIE') NOT NULL,
    ano_lancamento            YEAR          NOT NULL,
    classificacao_indicativa  ENUM('L','10','12','14','16','18') NOT NULL,
    duracao_min               SMALLINT UNSIGNED NULL COMMENT 'Preenchido apenas para FILME',
    sinopse                   TEXT          NULL,
    data_adicao               DATE          NOT NULL,
    PRIMARY KEY (id_conteudo)
) ENGINE = InnoDB;

-- 6) GENERO - categorias do catalogo
CREATE TABLE genero (
    id_genero    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome_genero  VARCHAR(50)       NOT NULL,
    descricao    VARCHAR(255)      NULL,
    PRIMARY KEY (id_genero),
    UNIQUE KEY uk_genero_nome (nome_genero)
) ENGINE = InnoDB;

-- 7) CONTEUDO_GENERO - tabela associativa do relacionamento N:N
CREATE TABLE conteudo_genero (
    id_conteudo  INT UNSIGNED      NOT NULL,
    id_genero    SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (id_conteudo, id_genero),
    CONSTRAINT fk_cg_conteudo FOREIGN KEY (id_conteudo)
        REFERENCES conteudo (id_conteudo) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_cg_genero   FOREIGN KEY (id_genero)
        REFERENCES genero (id_genero)     ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- 8) EPISODIO - episodios de uma serie
CREATE TABLE episodio (
    id_episodio       INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    id_conteudo       INT UNSIGNED      NOT NULL,
    numero_temporada  TINYINT UNSIGNED  NOT NULL,
    numero_episodio   SMALLINT UNSIGNED NOT NULL,
    titulo_episodio   VARCHAR(150)      NOT NULL,
    duracao_min       SMALLINT UNSIGNED NOT NULL,
    data_lancamento   DATE              NULL,
    PRIMARY KEY (id_episodio),
    UNIQUE KEY uk_episodio_serie_temp_num (id_conteudo, numero_temporada, numero_episodio),
    CONSTRAINT fk_episodio_conteudo FOREIGN KEY (id_conteudo)
        REFERENCES conteudo (id_conteudo) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- 9) HISTORICO_VISUALIZACAO - cada reproducao feita por um perfil
CREATE TABLE historico_visualizacao (
    id_historico         BIGINT UNSIGNED   NOT NULL AUTO_INCREMENT,
    id_perfil            INT UNSIGNED      NOT NULL,
    id_conteudo          INT UNSIGNED      NOT NULL,
    id_episodio          INT UNSIGNED      NULL COMMENT 'NULL quando o conteudo e um FILME',
    data_hora_inicio     DATETIME          NOT NULL,
    tempo_assistido_min  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    concluido            BOOLEAN           NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_historico),
    UNIQUE KEY uk_hist_perfil_inicio (id_perfil, data_hora_inicio),
    CONSTRAINT fk_hist_perfil   FOREIGN KEY (id_perfil)
        REFERENCES perfil (id_perfil)     ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_hist_conteudo FOREIGN KEY (id_conteudo)
        REFERENCES conteudo (id_conteudo) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_hist_episodio FOREIGN KEY (id_episodio)
        REFERENCES episodio (id_episodio) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB;

-- prints sugeridos:
SHOW TABLES;
DESCRIBE assinatura;
DESCRIBE historico_visualizacao;


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


-- =====================================================================
-- 9.4  INSERIR UMA NOVA COLUNA
--      Justificativa: a plataforma passou a enviar codigo de verificacao
--      por SMS, entao o usuario precisa de um telefone de contato.
-- =====================================================================
ALTER TABLE usuario
    ADD COLUMN telefone VARCHAR(20) NULL AFTER email;

DESCRIBE usuario;


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


-- =====================================================================
-- 9.6  EXCLUIR UMA COLUNA
--      Justificativa: o nome do genero ja e autoexplicativo; a descricao
--      nao era usada pela interface e foi removida.
-- =====================================================================
ALTER TABLE genero
    DROP COLUMN descricao;

DESCRIBE genero;
SELECT * FROM genero;


-- =====================================================================
-- 9.7  ALTERAR UM DADO INSERIDO
--      Justificativa: reajuste de preco do plano Premium.
-- =====================================================================
SELECT id_plano, nome_plano, preco_mensal FROM plano WHERE id_plano = 4;   -- antes

UPDATE plano
   SET preco_mensal = 59.90
 WHERE id_plano = 4;

SELECT id_plano, nome_plano, preco_mensal FROM plano WHERE id_plano = 4;   -- depois


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
