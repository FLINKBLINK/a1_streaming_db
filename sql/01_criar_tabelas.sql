-- A1 - Plataforma de Streaming - Fatec Cotia (Bancos e Armazens de Dados)
-- Arquivo: 01_criar_tabelas.sql   |   Item do trabalho: 9.2
-- Rode este arquivo inteiro e tire o print do resultado.

USE streaming_db;

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
