from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import text
from backend.database import SessionLocal
from typing import Optional

router = APIRouter()


# ============================================================
# MODELOS
# ============================================================

class UserCreate(BaseModel):
    nome: str = Field(min_length=1, max_length=100)
    email: str = Field(min_length=3, max_length=150)
    data_nascimento: str
    pais: str = Field(default="BR", min_length=2, max_length=2)


class WatchCreate(BaseModel):
    id_perfil: int
    id_conteudo: int
    id_episodio: Optional[int] = None
    tempo_assistido_min: int = Field(default=0, ge=0)
    concluido: bool = False


# ============================================================
# FUNÇÃO AUXILIAR PARA CONSULTAS
# ============================================================

def query(sql, params=None):
    with SessionLocal() as db:
        result = db.execute(
            text(sql),
            params or {}
        ).fetchall()

        return [dict(row._mapping) for row in result]


# ============================================================
# HEALTH CHECK
# ============================================================

@router.get("/health")
def health():
    try:
        query("SELECT 1 AS ok")

        return {
            "status": "ok",
            "database": "conectado"
        }

    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Banco indisponível: {e}"
        )


# ============================================================
# DASHBOARD
# ============================================================

@router.get("/dashboard")
def dashboard():

    rows = query("""
        SELECT 'usuarios' AS tabela, COUNT(*) AS total
        FROM usuario

        UNION ALL

        SELECT 'conteudos', COUNT(*)
        FROM conteudo

        UNION ALL

        SELECT 'planos', COUNT(*)
        FROM plano

        UNION ALL

        SELECT 'assinaturas', COUNT(*)
        FROM assinatura

        UNION ALL

        SELECT 'perfis', COUNT(*)
        FROM perfil

        UNION ALL

        SELECT 'visualizacoes', COUNT(*)
        FROM historico_visualizacao
    """)

    return {
        r["tabela"]: r["total"]
        for r in rows
    }


# ============================================================
# CATÁLOGO DE CONTEÚDOS
# ============================================================

@router.get("/conteudos")
def conteudos(
    tipo: Optional[str] = None,
    genero: Optional[str] = None
):

    sql = """
        SELECT DISTINCT
            c.id_conteudo,
            c.titulo,
            c.tipo,
            c.ano_lancamento,
            c.classificacao_indicativa,
            c.duracao_min,
            c.sinopse,
            c.data_adicao_catalogo

        FROM conteudo c

        LEFT JOIN conteudo_genero cg
            ON cg.id_conteudo = c.id_conteudo

        LEFT JOIN genero g
            ON g.id_genero = cg.id_genero

        WHERE
            (:tipo IS NULL OR c.tipo = :tipo)
            AND
            (:genero IS NULL OR g.nome_genero = :genero OR g.nome_genero IS NULL)

        ORDER BY c.titulo
    """

    return query(
        sql,
        {
            "tipo": tipo.upper() if tipo else None,
            "genero": genero.upper() if genero else None
        }
    )


# ============================================================
# DETALHES DE UM CONTEÚDO
# ============================================================

@router.get("/conteudos/{id_conteudo}")
def conteudo(id_conteudo: int):

    rows = query("""
        SELECT
            c.*,

            GROUP_CONCAT(
                g.nome_genero
                ORDER BY g.nome_genero
                SEPARATOR ', '
            ) AS generos

        FROM conteudo c

        LEFT JOIN conteudo_genero cg
            ON cg.id_conteudo = c.id_conteudo

        LEFT JOIN genero g
            ON g.id_genero = cg.id_genero

        WHERE c.id_conteudo = :id

        GROUP BY c.id_conteudo
    """, {
        "id": id_conteudo
    })

    if not rows:
        raise HTTPException(
            status_code=404,
            detail="Conteúdo não encontrado"
        )

    result = rows[0]

    # Se for série, busca os episódios
    if result["tipo"] == "SERIE":

        result["episodios"] = query("""
            SELECT
                id_episodio,
                numero_temporada,
                numero_episodio,
                titulo_episodio,
                duracao_min,
                data_lancamento

            FROM episodio

            WHERE id_conteudo = :id

            ORDER BY
                numero_temporada,
                numero_episodio
        """, {
            "id": id_conteudo
        })

    return result


# ============================================================
# GÊNEROS
# ============================================================

@router.get("/generos")
def generos():

    return query("""
        SELECT
            id_genero,
            nome_genero

        FROM genero

        ORDER BY nome_genero
    """)


# ============================================================
# USUÁRIOS
# ============================================================

@router.get("/usuarios")
def usuarios():

    return query("""
        SELECT
            id_usuario,
            nome,
            email,
            telefone,
            data_nascimento,
            pais,
            data_cadastro

        FROM usuario

        ORDER BY nome
    """)


# ============================================================
# CRIAR USUÁRIO
# ============================================================

@router.post("/usuarios")
def criar_usuario(user: UserCreate):

    with SessionLocal() as db:

        try:

            result = db.execute(
                text("""
                    INSERT INTO usuario
                    (
                        nome,
                        email,
                        data_nascimento,
                        pais,
                        senha_hash
                    )

                    VALUES
                    (
                        :nome,
                        :email,
                        :data_nascimento,
                        :pais,
                        SHA2(
                            CONCAT(:nome, '@webapp'),
                            256
                        )
                    )
                """),
                user.dict()
            )

            db.commit()

            return {
                "id_usuario": result.lastrowid,
                "mensagem": "Usuário criado"
            }

        except Exception as e:

            db.rollback()

            raise HTTPException(
                status_code=400,
                detail=str(e)
            )


# ============================================================
# PERFIS
# ============================================================

@router.get("/perfis")
def perfis():

    return query("""
        SELECT
            p.id_perfil,
            p.nome_perfil,
            p.idioma_preferido,
            p.classificacao_maxima,
            p.perfil_infantil,

            u.id_usuario,
            u.nome AS usuario

        FROM perfil p

        JOIN usuario u
            ON u.id_usuario = p.id_usuario

        ORDER BY
            u.nome,
            p.nome_perfil
    """)


# ============================================================
# HISTÓRICO DE VISUALIZAÇÃO
# ============================================================

@router.get("/historico")
def historico(
    id_perfil: Optional[int] = None
):

    return query("""
        SELECT
            h.id_historico,
            h.id_perfil,

            u.nome AS usuario,

            p.nome_perfil,

            h.id_conteudo,

            c.titulo,
            c.tipo,

            h.id_episodio,

            e.numero_temporada,
            e.numero_episodio,
            e.titulo_episodio,

            h.data_hora_inicio,
            h.tempo_assistido_min,
            h.concluido

        FROM historico_visualizacao h

        JOIN perfil p
            ON p.id_perfil = h.id_perfil

        JOIN usuario u
            ON u.id_usuario = p.id_usuario

        JOIN conteudo c
            ON c.id_conteudo = h.id_conteudo

        LEFT JOIN episodio e
            ON e.id_episodio = h.id_episodio

        WHERE
            (
                :id_perfil IS NULL
                OR h.id_perfil = :id_perfil
            )

        ORDER BY
            h.data_hora_inicio DESC
    """, {
        "id_perfil": id_perfil
    })


# ============================================================
# REGISTRAR VISUALIZAÇÃO
# ============================================================

@router.post("/historico")
def registrar_visualizacao(
    item: WatchCreate
):

    with SessionLocal() as db:

        try:

            result = db.execute(
                text("""
                    INSERT INTO historico_visualizacao
                    (
                        id_perfil,
                        id_conteudo,
                        id_episodio,
                        data_hora_inicio,
                        tempo_assistido_min,
                        concluido
                    )

                    VALUES
                    (
                        :id_perfil,
                        :id_conteudo,
                        :id_episodio,
                        NOW(),
                        :tempo_assistido_min,
                        :concluido
                    )
                """),
                item.dict()
            )

            db.commit()

            return {
                "id_historico": result.lastrowid,
                "mensagem": "Visualização registrada"
            }

        except Exception as e:

            db.rollback()

            raise HTTPException(
                status_code=400,
                detail=str(e)
            )


# ============================================================
# ASSINATURAS
# ============================================================

@router.get("/assinaturas")
def assinaturas():

    return query("""
        SELECT
            a.id_assinatura,

            u.nome AS usuario,

            pl.nome_plano,
            pl.preco_mensal,
            pl.qualidade_maxima,
            pl.telas_simultaneas,
            pl.permite_download,

            a.data_inicio,
            a.data_fim,
            a.status,
            a.forma_pagamento

        FROM assinatura a

        JOIN usuario u
            ON u.id_usuario = a.id_usuario

        JOIN plano pl
            ON pl.id_plano = a.id_plano

        ORDER BY
            a.status,
            u.nome
    """)


# ============================================================
# RECEITA
# ============================================================

@router.get("/receita")
def receita():

    return query("""
        SELECT
            pl.nome_plano,

            COUNT(a.id_assinatura)
                AS assinantes_ativos,

            SUM(pl.preco_mensal)
                AS receita_mensal

        FROM assinatura a

        JOIN plano pl
            ON pl.id_plano = a.id_plano

        WHERE
            a.status = 'ATIVA'

        GROUP BY
            pl.nome_plano

        ORDER BY
            receita_mensal DESC
    """)


# ============================================================
# PLANOS
# ============================================================

@router.get("/planos")
def planos():

    return query("""
        SELECT
            id_plano,
            nome_plano,
            preco_mensal,
            qualidade_maxima,
            telas_simultaneas,
            permite_download

        FROM plano

        ORDER BY preco_mensal
    """)