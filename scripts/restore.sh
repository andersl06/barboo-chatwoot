#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-compose.local.yml}"
APPLY=0

usage() {
  cat <<'EOF'
Uso:
  ./scripts/restore.sh --db <arquivo.sql.gz> [--storage <arquivo.tar.gz>] [--yes]

Regras:
  - Sem --yes, fica em dry-run.
  - Restore de banco sobrescreve o estado atual do banco alvo.
EOF
}

DB_DUMP=""
STORAGE_DUMP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --db)
      DB_DUMP="${2:-}"
      shift 2
      ;;
    --storage)
      STORAGE_DUMP="${2:-}"
      shift 2
      ;;
    --yes)
      APPLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Opcao invalida: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$DB_DUMP" ]]; then
  echo "ERRO: informe --db <arquivo.sql.gz>"
  exit 1
fi

if [[ ! -f "$DB_DUMP" ]]; then
  echo "ERRO: arquivo de banco nao encontrado: $DB_DUMP"
  exit 1
fi

if [[ -n "$STORAGE_DUMP" && ! -f "$STORAGE_DUMP" ]]; then
  echo "ERRO: arquivo de storage nao encontrado: $STORAGE_DUMP"
  exit 1
fi

if [[ "$APPLY" -eq 0 ]]; then
  echo "[dry-run] Restauraria banco com: $DB_DUMP"
  if [[ -n "$STORAGE_DUMP" ]]; then
    echo "[dry-run] Restauraria storage com: $STORAGE_DUMP"
  fi
  echo "[dry-run] Execute novamente com --yes para aplicar."
  exit 0
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

echo "Subindo dependencias..."
docker compose -f "$COMPOSE_FILE" up -d postgres redis chatwoot-web

echo "Restaurando banco..."
gunzip -c "$DB_DUMP" | docker compose -f "$COMPOSE_FILE" exec -T postgres \
  psql -U "${POSTGRES_USERNAME:-postgres}" -d "${POSTGRES_DATABASE:-chatwoot}"

if [[ -n "$STORAGE_DUMP" ]]; then
  echo "Restaurando storage..."
  docker compose -f "$COMPOSE_FILE" exec -T chatwoot-web sh -lc 'rm -rf /app/storage/*'
  cat "$STORAGE_DUMP" | docker compose -f "$COMPOSE_FILE" exec -T chatwoot-web sh -lc 'tar xzf - -C /app'
fi

echo "Executando prepare de banco..."
docker compose -f "$COMPOSE_FILE" run --rm chatwoot-web bundle exec rails db:chatwoot_prepare

echo "Restore concluido."
