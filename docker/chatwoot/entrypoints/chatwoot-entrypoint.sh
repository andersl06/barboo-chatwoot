#!/usr/bin/env sh
set -eu

if [ "${RAILS_ENV:-production}" = "production" ]; then
  if [ -z "${SECRET_KEY_BASE:-}" ] || [ "${SECRET_KEY_BASE:-}" = "CHANGE_ME" ]; then
    echo "ERROR: SECRET_KEY_BASE invalido. Configure um valor forte antes de subir."
    exit 1
  fi
fi

mkdir -p /app/tmp/pids /app/log

# Delegate lifecycle handling (migrations/wait logic) to official script.
exec docker/entrypoints/rails.sh "$@"
