#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-compose.local.yml}"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERRO: docker nao encontrado."
  exit 1
fi

if [ ! -f ".env" ]; then
  cp .env.example .env
  echo "Arquivo .env criado a partir de .env.example"
fi

replace_secret_if_placeholder() {
  local key="$1"
  local placeholder
  placeholder="$(grep -E "^${key}=" .env | cut -d '=' -f2- || true)"
  if [[ -z "$placeholder" || "$placeholder" == "CHANGE_ME" ]]; then
    if command -v openssl >/dev/null 2>&1; then
      local value
      value="$(openssl rand -hex 32)"
      if sed --version >/dev/null 2>&1; then
        sed -i "s#^${key}=.*#${key}=${value}#g" .env
      else
        sed -i '' "s#^${key}=.*#${key}=${value}#g" .env
      fi
      echo "Gerado valor automatico para ${key}"
    else
      echo "ATENCAO: openssl nao encontrado. Defina ${key} manualmente em .env"
    fi
  fi
}

replace_secret_if_placeholder "SECRET_KEY_BASE"
replace_secret_if_placeholder "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"
replace_secret_if_placeholder "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"
replace_secret_if_placeholder "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"
replace_secret_if_placeholder "POSTGRES_PASSWORD"
replace_secret_if_placeholder "REDIS_PASSWORD"

echo
echo "1/4 Subindo dependencias..."
docker compose -f "$COMPOSE_FILE" up -d postgres redis

echo
echo "2/4 Preparando banco..."
docker compose -f "$COMPOSE_FILE" run --rm chatwoot-web bundle exec rails db:chatwoot_prepare

echo
echo "3/4 Subindo aplicacao..."
docker compose -f "$COMPOSE_FILE" up -d --build chatwoot-web chatwoot-worker

echo
echo "4/4 Estado dos servicos:"
docker compose -f "$COMPOSE_FILE" ps

echo
echo "Chatwoot local pronto em: http://localhost:${CHATWOOT_WEB_PORT:-3000}"
