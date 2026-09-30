#!/usr/bin/env bash
# =====================================================================
#  STREAMFLIX · start.sh — sobe TUDO com um comando
#
#    ./start.sh              sobe MySQL (Docker) → cria o banco se estiver vazio
#                            → prepara o Python → inicia a API → abre o navegador
#    ./start.sh --reset      recria o banco do zero (roda os scripts 00 → 07 de novo)
#    ./start.sh --dev        API em primeiro plano com auto-reload (Ctrl+C encerra)
#    ./start.sh --no-browser não abre o navegador
#    ./start.sh --purge      apaga container + volume do MySQL antes de subir
#    PORT=8080 ./start.sh    usa outra porta para o site
#
#  Para parar tudo:  ./stop.sh
#  Compatível com macOS (bash 3.2) e Linux. Não altera os scripts de sql/.
# =====================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# ---------------------------------------------------------------- config
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8000}"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-a1_mysql}"
MYSQL_PORT="${MYSQL_PORT:-3307}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-fatec123}"
MYSQL_DATABASE="${MYSQL_DATABASE:-streaming_db}"
STATE_DIR=".streamflix"
PID_FILE="$STATE_DIR/api.pid"
LOG_FILE="$STATE_DIR/api.log"
SQL_SCRIPTS="00_criar_banco 01_criar_tabelas 02_inserir_registros 03_alter_add_coluna 04_alter_rename_coluna 05_alter_drop_coluna 06_update 07_delete"

RESET=false; PURGE=false; DEV=false; OPEN_BROWSER=true

for arg in "$@"; do
  case "$arg" in
    --reset)      RESET=true ;;
    --purge)      PURGE=true; RESET=true ;;
    --dev)        DEV=true ;;
    --no-browser) OPEN_BROWSER=false ;;
    --port=*)     PORT="${arg#--port=}" ;;
    -h|--help)    sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "opção desconhecida: $arg (use --help)"; exit 2 ;;
  esac
done

# ---------------------------------------------------------------- saída bonita
if [ -t 1 ]; then B=$'\033[1m'; D=$'\033[2m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; N=$'\033[0m'; else B=; D=; G=; Y=; R=; C=; N=; fi
step() { printf "\n${B}${C}▶ %s${N}\n" "$*"; }
ok()   { printf "  ${G}✔${N} %s\n" "$*"; }
info() { printf "  ${D}·${N} %s\n" "$*"; }
warn() { printf "  ${Y}!${N} %s\n" "$*"; }
die()  { printf "\n  ${R}✖ %b${N}\n\n" "$*" >&2; exit 1; }
wait_dots() { printf "  ${D}%s${N}" "$1"; }

printf "\n${B}══════════════════════════════════════════════${N}\n"
printf "${B}   ▶ STREAMFLIX · A1 streaming_db · iniciando${N}\n"
printf "${B}══════════════════════════════════════════════${N}\n"
mkdir -p "$STATE_DIR"

# ---------------------------------------------------------------- 1. Docker
step "Docker"
command -v docker >/dev/null 2>&1 || die "Docker não encontrado. Instale o Docker Desktop: https://www.docker.com/products/docker-desktop/"
if ! docker info >/dev/null 2>&1; then
  if [ "$(uname -s)" = "Darwin" ] && [ -d "/Applications/Docker.app" ]; then
    warn "Docker Desktop não está rodando — abrindo…"
    open -a Docker || true
    wait_dots "aguardando o Docker "
    for ((_i = 0; _i < 45; _i++)); do docker info >/dev/null 2>&1 && break; printf "."; sleep 2; done; echo
  fi
  docker info >/dev/null 2>&1 || die "O Docker não está rodando. Abra o Docker Desktop (baleia verde) e rode ./start.sh de novo."
fi
if docker compose version >/dev/null 2>&1; then COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then COMPOSE="docker-compose"
else die "Nem 'docker compose' nem 'docker-compose' disponíveis."; fi
[ -f docker-compose.yml ] || [ -f compose.yml ] || die "docker-compose.yml não encontrado em $PROJECT_DIR"
ok "Docker ok ($(docker --version | sed 's/,.*//'))"

# ---------------------------------------------------------------- 2. MySQL
step "MySQL 8 (container $MYSQL_CONTAINER · porta $MYSQL_PORT)"
if $PURGE; then
  warn "--purge: removendo container e volume (apaga TODOS os dados)…"
  $COMPOSE down -v --remove-orphans >/dev/null 2>&1 || true
fi
$COMPOSE up -d 2>&1 | sed 's/^/  /' || die "Falha no docker compose up. Veja: $COMPOSE logs"

wait_dots "aguardando o MySQL ficar saudável "
HEALTH="starting"
for ((_i = 0; _i < 60; _i++)); do
  HEALTH="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$MYSQL_CONTAINER" 2>/dev/null || echo starting)"
  [ "$HEALTH" = "healthy" ] && break
  printf "."; sleep 2
done; echo
[ "$HEALTH" = "healthy" ] || die "MySQL não ficou saudável (estado: $HEALTH). Veja: $COMPOSE logs mysql"

# executa comandos SQL dentro do container (sem depender de cliente mysql no PC)
mysql_exec() { docker exec -i -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" "$MYSQL_CONTAINER" mysql -uroot -h127.0.0.1 --protocol=TCP "$@"; }

wait_dots "confirmando conexão TCP "
CONN=false
for ((_i = 0; _i < 30; _i++)); do
  if mysql_exec -e "SELECT 1" >/dev/null 2>&1; then CONN=true; break; fi
  printf "."; sleep 2
done; echo
$CONN || die "O MySQL respondeu ao ping mas não aceita conexões ainda. Tente de novo em alguns segundos."
ok "MySQL $(mysql_exec -N -e 'SELECT VERSION()' 2>/dev/null | head -n1) pronto em 127.0.0.1:$MYSQL_PORT"

# ---------------------------------------------------------------- 3. Scripts da A1 (só se necessário)
step "Banco $MYSQL_DATABASE"
TABELAS="$(mysql_exec -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$MYSQL_DATABASE'" 2>/dev/null | tr -d '[:space:]' || echo 0)"
TABELAS="${TABELAS:-0}"
if $RESET || [ "$TABELAS" = "0" ]; then
  if $RESET; then warn "--reset: recriando o banco do zero (os dados de teste serão apagados)."
  else info "Banco vazio — executando os scripts da A1 pela primeira vez."; fi
  for nome in $SQL_SCRIPTS; do
    arquivo="sql/${nome}.sql"
    [ -f "$arquivo" ] || die "Script não encontrado: $arquivo"
    printf "  ${D}▸ %-32s${N}" "$arquivo"
    if mysql_exec < "$arquivo" >/dev/null 2>"$STATE_DIR/sql_error.log"; then
      printf "${G}ok${N}\n"
    else
      echo; die "Erro ao executar $arquivo:\n$(cat "$STATE_DIR/sql_error.log")"
    fi
  done
  rm -f "$STATE_DIR/sql_error.log"
  ok "Scripts 00 → 07 executados (itens 9.1 a 9.8)"
else
  ok "Banco já possui $TABELAS tabelas — scripts não executados (use --reset para recriar)"
fi

# ---------------------------------------------------------------- 4. Python
step "Python"
PY=""
for c in python3 python; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)' 2>/dev/null; then PY="$c"; break; fi
done
[ -n "$PY" ] || die "Python 3.9+ não encontrado. Instale em https://www.python.org/downloads/"

if [ -x ".venv/bin/python" ]; then VENV_PY=".venv/bin/python"
elif [ -x ".venv/Scripts/python.exe" ]; then VENV_PY=".venv/Scripts/python.exe"
else
  info "criando ambiente virtual .venv…"
  "$PY" -m venv .venv || die "Não consegui criar o .venv"
  VENV_PY=".venv/bin/python"; [ -x "$VENV_PY" ] || VENV_PY=".venv/Scripts/python.exe"
fi

REQ_HASH="$( (md5 -q requirements.txt 2>/dev/null || md5sum requirements.txt | cut -d' ' -f1) )"
if [ "$(cat "$STATE_DIR/requirements.md5" 2>/dev/null || true)" != "$REQ_HASH" ] \
   || ! "$VENV_PY" -c "import fastapi, uvicorn, sqlalchemy, pymysql, dotenv" >/dev/null 2>&1; then
  info "instalando dependências (requirements.txt)…"
  "$VENV_PY" -m pip install -q -r requirements.txt || die "pip install falhou. Veja a mensagem acima."
  echo "$REQ_HASH" > "$STATE_DIR/requirements.md5"
fi
ok "$("$VENV_PY" --version 2>&1) · dependências ok"

# ---------------------------------------------------------------- 5. .env
if [ ! -f .env ]; then
  printf 'DATABASE_URL=mysql+pymysql://root:%s@127.0.0.1:%s/%s\n' "$MYSQL_ROOT_PASSWORD" "$MYSQL_PORT" "$MYSQL_DATABASE" > .env
  ok ".env criado"
else
  info ".env já existe"
fi

# ---------------------------------------------------------------- 6. porta / instância anterior
step "API FastAPI (http://$HOST:$PORT)"
if [ -f "$PID_FILE" ]; then
  OLD="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [ -n "$OLD" ] && kill -0 "$OLD" 2>/dev/null; then
    info "encerrando a API anterior (pid $OLD)…"
    kill "$OLD" 2>/dev/null || true
    for _ in 1 2 3 4 5; do kill -0 "$OLD" 2>/dev/null || break; sleep 1; done
    kill -9 "$OLD" 2>/dev/null || true
  fi
  rm -f "$PID_FILE"
fi
port_in_use() {
  "$VENV_PY" - "$HOST" "$PORT" <<'PY'
import socket, sys
s = socket.socket(); s.settimeout(0.5)
sys.exit(0 if s.connect_ex((sys.argv[1], int(sys.argv[2]))) == 0 else 1)
PY
}
if port_in_use; then
  PIDS="$(lsof -ti "tcp:$PORT" 2>/dev/null || true)"
  if [ -n "$PIDS" ]; then
    warn "porta $PORT ocupada (pid $PIDS) — encerrando…"
    for p in $PIDS; do kill "$p" 2>/dev/null || true; done
    sleep 1
  fi
  port_in_use && die "A porta $PORT continua ocupada. Tente: PORT=8080 ./start.sh"
fi

# ---------------------------------------------------------------- 7. navegador
open_url() {
  case "$(uname -s)" in
    Darwin) open "$1" >/dev/null 2>&1 || true ;;
    Linux)  if command -v xdg-open >/dev/null 2>&1; then xdg-open "$1" >/dev/null 2>&1 || true
            elif command -v wslview >/dev/null 2>&1; then wslview "$1" >/dev/null 2>&1 || true; fi ;;
    MINGW*|MSYS*|CYGWIN*) start "$1" >/dev/null 2>&1 || true ;;
  esac
}

# ---------------------------------------------------------------- 8. sobe a API
if $DEV; then
  ok "modo --dev: uvicorn com --reload em primeiro plano (Ctrl+C encerra a API; o MySQL continua)"
  printf "\n  ${B}Site:${N} http://$HOST:$PORT     ${B}API:${N} http://$HOST:$PORT/docs\n\n"
  if $OPEN_BROWSER; then ( sleep 2; open_url "http://$HOST:$PORT" ) & fi
  exec "$VENV_PY" -m uvicorn backend.main:app --host "$HOST" --port "$PORT" --reload
fi

# roda em segundo plano, imune ao fechamento do terminal (equivalente a nohup)
( trap '' HUP; exec "$VENV_PY" -m uvicorn backend.main:app --host "$HOST" --port "$PORT" ) >"$LOG_FILE" 2>&1 </dev/null &
API_PID=$!
disown -h "$API_PID" 2>/dev/null || true
echo "$API_PID" > "$PID_FILE"

wait_dots "aguardando a API responder "
UP=false
for ((_i = 0; _i < 40; _i++)); do
  if "$VENV_PY" - "$HOST" "$PORT" <<'PY' 2>/dev/null
import sys, urllib.request, urllib.error
try:
    urllib.request.urlopen(f"http://{sys.argv[1]}:{sys.argv[2]}/api/health", timeout=2)
except urllib.error.HTTPError:
    pass            # respondeu (mesmo com 503) = API de pé
except Exception:
    sys.exit(1)
PY
  then UP=true; break; fi
  kill -0 "$API_PID" 2>/dev/null || { echo; die "A API encerrou logo após iniciar. Log:\n$(tail -n 30 "$LOG_FILE")"; }
  printf "."; sleep 1
done; echo
$UP || die "A API não respondeu em 40 s. Veja o log: $LOG_FILE"
ok "API rodando (pid $API_PID) · log em $LOG_FILE"

$OPEN_BROWSER && open_url "http://$HOST:$PORT"

printf "\n${B}${G}══════════════════════════════════════════════${N}\n"
printf "${B}${G}   ✔ STREAMFLIX RODANDO${N}\n"
printf "${B}${G}══════════════════════════════════════════════${N}\n\n"
printf "   ${B}Site:${N}   http://$HOST:$PORT\n"
printf "   ${B}API:${N}    http://$HOST:$PORT/docs\n"
printf "   ${B}MySQL:${N}  127.0.0.1:$MYSQL_PORT · root / $MYSQL_ROOT_PASSWORD · $MYSQL_DATABASE\n\n"
printf "   ${D}logs da API:${N}   tail -f $LOG_FILE\n"
printf "   ${D}parar tudo:${N}    ./stop.sh\n"
printf "   ${D}recriar banco:${N} ./start.sh --reset\n\n"
