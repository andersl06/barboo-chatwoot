#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-compose.local.yml}"
BACKUP_DIR="${BACKUP_DIR:-backups}"

if [ ! -f ".env" ]; then
  echo "ERRO: .env nao encontrado."
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

mkdir -p "$BACKUP_DIR"
TS="$(date -u +%Y%m%d_%H%M%SZ)"
DB_FILE="${BACKUP_DIR}/chatwoot_db_${TS}.sql.gz"
STORAGE_FILE="${BACKUP_DIR}/chatwoot_storage_${TS}.tar.gz"

echo "Gerando backup do Postgres em ${DB_FILE}"
docker compose -f "$COMPOSE_FILE" exec -T postgres \
  pg_dump -U "${POSTGRES_USERNAME:-postgres}" "${POSTGRES_DATABASE:-chatwoot}" | gzip > "$DB_FILE"

echo "Gerando backup do storage em ${STORAGE_FILE}"
docker compose -f "$COMPOSE_FILE" exec -T chatwoot-web \
  sh -lc 'tar czf - -C /app storage' > "$STORAGE_FILE"

echo "Backup concluido:"
echo "- ${DB_FILE}"
echo "- ${STORAGE_FILE}"
