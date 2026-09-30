#!/usr/bin/env bash
# =====================================================================
#  STREAMFLIX · stop.sh — desfaz o start.sh, na ordem inversa
#
#    ./stop.sh            para a API e o container do MySQL (dados preservados)
#    ./stop.sh --keep-db  para só a API; deixa o MySQL ligado
#    ./stop.sh --down     para a API e REMOVE o container (o volume com os dados fica)
#    ./stop.sh --purge    para tudo e APAGA o volume — o próximo start.sh recria o banco
#    PORT=8080 ./stop.sh  se a API foi iniciada em outra porta
#
#  Para subir de novo:  ./start.sh
# =====================================================================
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8000}"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-a1_mysql}"
STATE_DIR=".streamflix"
PID_FILE="$STATE_DIR/api.pid"

KEEP_DB=false; DOWN=false; PURGE=false
for arg in "$@"; do
  case "$arg" in
    --keep-db) KEEP_DB=true ;;
    --down)    DOWN=true ;;
    --purge)   PURGE=true; DOWN=true ;;
    --port=*)  PORT="${arg#--port=}" ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "opção desconhecida: $arg (use --help)"; exit 2 ;;
  esac
done

if [ -t 1 ]; then B=$'\033[1m'; D=$'\033[2m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; N=$'\033[0m'; else B=; D=; G=; Y=; R=; C=; N=; fi
step() { printf "\n${B}${C}■ %s${N}\n" "$*"; }
ok()   { printf "  ${G}✔${N} %s\n" "$*"; }
info() { printf "  ${D}·${N} %s\n" "$*"; }
warn() { printf "  ${Y}!${N} %s\n" "$*"; }

printf "\n${B}══════════════════════════════════════════════${N}\n"
printf "${B}   ■ STREAMFLIX · encerrando${N}\n"
printf "${B}══════════════════════════════════════════════${N}\n"

# ---------------------------------------------------------------- 1. API
step "API FastAPI (porta $PORT)"
parou=false

# 1a. pelo pid salvo pelo start.sh
if [ -f "$PID_FILE" ]; then
  PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8; do kill -0 "$PID" 2>/dev/null || break; sleep 0.5; done
    kill -0 "$PID" 2>/dev/null && kill -9 "$PID" 2>/dev/null
    ok "API encerrada (pid $PID)"
    parou=true
  fi
  rm -f "$PID_FILE"
fi

# 1b. qualquer uvicorn deste projeto que tenha sobrado (ex.: modo --dev em outro terminal)
if command -v pgrep >/dev/null 2>&1; then
  for p in $(pgrep -f "uvicorn backend.main:app" 2>/dev/null || true); do
    [ "$p" = "$$" ] && continue
    kill "$p" 2>/dev/null && { info "uvicorn extra encerrado (pid $p)"; parou=true; }
  done
fi

# 1c. porta ainda ocupada?
if command -v lsof >/dev/null 2>&1; then
  PIDS="$(lsof -ti "tcp:$PORT" 2>/dev/null || true)"
  if [ -n "$PIDS" ]; then
    sleep 1
    PIDS="$(lsof -ti "tcp:$PORT" 2>/dev/null || true)"
    for p in $PIDS; do kill "$p" 2>/dev/null && { info "processo na porta $PORT encerrado (pid $p)"; parou=true; }; done
  fi
fi
$parou || info "nenhuma API rodando"

# ---------------------------------------------------------------- 2. MySQL
step "MySQL (container $MYSQL_CONTAINER)"
if $KEEP_DB; then
  info "--keep-db: MySQL continua ligado"
elif ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  warn "Docker não está acessível — nada a parar"
else
  if docker compose version >/dev/null 2>&1; then COMPOSE="docker compose"; else COMPOSE="docker-compose"; fi
  if $PURGE; then
    warn "--purge: removendo container E volume (todos os dados serão apagados)…"
    $COMPOSE down -v --remove-orphans 2>&1 | sed 's/^/  /'
    ok "MySQL removido junto com os dados — ./start.sh recria o banco do zero"
  elif $DOWN; then
    $COMPOSE down --remove-orphans 2>&1 | sed 's/^/  /'
    ok "Container removido (o volume a1_mysql_data com os dados foi preservado)"
  else
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$MYSQL_CONTAINER"; then
      $COMPOSE stop 2>&1 | sed 's/^/  /'
      ok "MySQL parado (dados preservados no volume)"
    else
      info "container já estava parado"
    fi
  fi
fi

printf "\n${B}${G}   ✔ Tudo encerrado.${N}  ${D}Para voltar: ./start.sh${N}\n\n"
