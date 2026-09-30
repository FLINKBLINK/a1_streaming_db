from pathlib import Path

start = r'''#!/bin/bash

# ============================================================
# STREAMFLIX - INICIALIZAÇÃO AUTOMÁTICA
# ============================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo ""
echo "=========================================="
echo "       STREAMFLIX - INICIANDO"
echo "=========================================="
echo ""

# ------------------------------------------------------------
# 1. Verificar Docker
# ------------------------------------------------------------

if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker não foi encontrado."
    echo "Instale/abra o Docker Desktop e tente novamente."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "❌ O Docker Desktop não está iniciado."
    echo "Abra o Docker Desktop e execute o script novamente."
    exit 1
fi

echo "🐳 Docker: OK"

# ------------------------------------------------------------
# 2. Subir MySQL pelo Docker Compose
# ------------------------------------------------------------

if [ ! -f "docker-compose.yml" ] && [ ! -f "compose.yml" ]; then
    echo "❌ Não encontrei docker-compose.yml ou compose.yml nesta pasta:"
    echo "$PROJECT_DIR"
    echo ""
    echo "Coloque este script na mesma pasta do seu Docker Compose."
    exit 1
fi

echo "🐳 Subindo banco de dados..."

docker compose up -d

# ------------------------------------------------------------
# 3. Esperar MySQL ficar disponível na porta 3307
# ------------------------------------------------------------

echo "⏳ Aguardando MySQL ficar disponível..."

MYSQL_OK=false

for i in {1..30}; do
    if nc -z 127.0.0.1 3307 >/dev/null 2>&1; then
        MYSQL_OK=true
        break
    fi

    printf "."
    sleep 2
done

echo ""

if [ "$MYSQL_OK" = false ]; then
    echo "❌ O MySQL não ficou disponível na porta 3307."
    echo ""
    echo "Verifique:"
    echo "  docker compose ps"
    echo "  docker compose logs"
    exit 1
fi

echo "✅ MySQL disponível na porta 3307"

# ------------------------------------------------------------
# 4. Criar ambiente virtual Python se não existir
# ------------------------------------------------------------

if [ ! -d ".venv" ]; then
    echo "🐍 Criando ambiente virtual Python..."
    python3 -m venv .venv
fi

source .venv/bin/activate

echo "🐍 Python: $(python --version)"

# ------------------------------------------------------------
# 5. Instalar dependências
# ------------------------------------------------------------

if [ -f "requirements.txt" ]; then
    echo "📦 Verificando dependências..."
    python -m pip install -q -r requirements.txt
else
    echo "❌ requirements.txt não encontrado."
    exit 1
fi

# ------------------------------------------------------------
# 6. Criar .env automaticamente, se não existir
# ------------------------------------------------------------

if [ ! -f ".env" ]; then
    echo "⚙️ Criando arquivo .env..."

    cat > .env <<'EOF'
DATABASE_URL=mysql+pymysql://root:fatec123@127.0.0.1:3307/streaming_db
EOF

    echo "✅ .env criado"
else
    echo "⚙️ .env já existe"
fi

# ------------------------------------------------------------
# 7. Verificar se a porta 8000 já está ocupada
# ------------------------------------------------------------

if lsof -i :8000 >/dev/null 2>&1; then
    echo ""
    echo "⚠️ A porta 8000 já está sendo usada."

    PID=$(lsof -t -i :8000 | head -n 1)

    if [ -n "$PID" ]; then
        echo "Processo encontrado: $PID"
        echo "Encerrando processo anterior..."
        kill "$PID" 2>/dev/null || true
        sleep 2
    fi
fi

# ------------------------------------------------------------
# 8. Abrir navegador
# ------------------------------------------------------------

echo ""
echo "🌐 Abrindo StreamFlix..."
open "http://127.0.0.1:8000" >/dev/null 2>&1 || true

echo ""
echo "=========================================="
echo "       STREAMFLIX RODANDO"
echo "=========================================="
echo ""
echo "Site: http://127.0.0.1:8000"
echo "API:  http://127.0.0.1:8000/docs"
echo ""
echo "Para encerrar:"
echo "    CONTROL + C"
echo ""
echo "=========================================="
echo ""

# ------------------------------------------------------------
# 9. Iniciar FastAPI
# ------------------------------------------------------------

uvicorn backend.main:app --reload
'''

stop = r'''#!/bin/bash

echo ""
echo "🛑 Encerrando StreamFlix..."

if lsof -i :8000 >/dev/null 2>&1; then
    PIDS=$(lsof -t -i :8000)

    for PID in $PIDS; do
        kill "$PID" 2>/dev/null || true
    done

    echo "✅ FastAPI encerrado."
else
    echo "ℹ️ Nenhum FastAPI rodando na porta 8000."
fi

echo ""
echo "🐳 O MySQL continua ligado."
echo "Para desligar o banco também, use:"
echo "docker compose down"
echo ""
'''

readme = r'''# Como usar o StreamFlix

## Primeira vez

Coloque `start.sh` e `stop.sh` na mesma pasta do seu `docker-compose.yml`.

No terminal:

```bash
chmod +x start.sh stop.sh