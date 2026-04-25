#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-barboo-chatwoot}"
APPLY=0
INCLUDE_GLOBAL_UNUSED_IMAGES=0
INCLUDE_GLOBAL_BUILDER_CACHE=0

usage() {
  cat <<'EOF'
Uso:
  ./scripts/cleanup-docker-safe.sh [opcoes]

Opcoes:
  --yes                           aplica remocoes (padrao: dry-run)
  --include-global-unused-images  inclui imagens sem container associado
  --include-global-builder-cache  inclui docker builder prune (cache antigo)
  --project-name <nome>           nome logico do projeto (default: barboo-chatwoot)
  -h, --help                      ajuda

Observacoes de seguranca:
  - Sem --yes, nada e removido.
  - Sem flags globais, remove apenas dangling images e recursos do projeto alvo.
  - Nao remove containers em execucao.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)
      APPLY=1
      shift
      ;;
    --include-global-unused-images)
      INCLUDE_GLOBAL_UNUSED_IMAGES=1
      shift
      ;;
    --include-global-builder-cache)
      INCLUDE_GLOBAL_BUILDER_CACHE=1
      shift
      ;;
    --project-name)
      PROJECT_NAME="${2:-}"
      shift 2
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

if ! command -v docker >/dev/null 2>&1; then
  echo "ERRO: docker nao encontrado."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERRO: daemon Docker indisponivel."
  exit 1
fi

run_cmd() {
  if [[ "$APPLY" -eq 1 ]]; then
    echo "+ $*"
    "$@"
  else
    echo "[dry-run] $*"
  fi
}

echo "Projeto alvo: $PROJECT_NAME"
if [[ "$APPLY" -eq 0 ]]; then
  echo "Modo: dry-run"
else
  echo "Modo: apply"
fi
echo

# 1) Dangling images (seguro e conservador)
run_cmd docker image prune -f

# 2) Containers stopped do projeto alvo (somente escopo do projeto)
mapfile -t PROJECT_STOPPED < <(docker ps -aq \
  --filter "label=com.docker.compose.project=${PROJECT_NAME}" \
  --filter "status=exited")
if [[ "${#PROJECT_STOPPED[@]}" -gt 0 ]]; then
  run_cmd docker rm "${PROJECT_STOPPED[@]}"
else
  echo "Nenhum container stopped do projeto ${PROJECT_NAME}."
fi

# 3) Networks custom do projeto alvo sem container
mapfile -t PROJECT_NETWORKS < <(docker network ls --filter type=custom --format '{{.Name}}' | grep -E "^${PROJECT_NAME}" || true)
for net in "${PROJECT_NETWORKS[@]:-}"; do
  if [[ -z "${net}" ]]; then
    continue
  fi
  count="$(docker network inspect "$net" --format '{{len .Containers}}')"
  if [[ "$count" = "0" ]]; then
    run_cmd docker network rm "$net"
  fi
done

# 4) Volumes do projeto alvo sem uso
mapfile -t PROJECT_VOLUMES < <(docker volume ls -q --filter "label=com.docker.compose.project=${PROJECT_NAME}")
for vol in "${PROJECT_VOLUMES[@]:-}"; do
  if [[ -z "${vol}" ]]; then
    continue
  fi
  attached="$(docker ps -a --filter "volume=${vol}" --format '{{.Names}}')"
  if [[ -z "$attached" ]]; then
    run_cmd docker volume rm "$vol"
  fi
done

# 5) Opcional: imagens sem container associado (global)
if [[ "$INCLUDE_GLOBAL_UNUSED_IMAGES" -eq 1 ]]; then
  mapfile -t USED_IMAGES < <(docker ps -a --format '{{.Image}}' | sort -u)
  mapfile -t ALL_IMAGES < <(docker images --format '{{.Repository}}:{{.Tag}}' | sort -u)
  UNUSED=()
  for image in "${ALL_IMAGES[@]}"; do
    if [[ "$image" = "<none>:<none>" ]]; then
      continue
    fi
    if ! printf '%s\n' "${USED_IMAGES[@]}" | grep -Fxq "$image"; then
      UNUSED+=("$image")
    fi
  done
  if [[ "${#UNUSED[@]}" -gt 0 ]]; then
    run_cmd docker rmi "${UNUSED[@]}"
  else
    echo "Nenhuma imagem global sem container associado."
  fi
fi

# 6) Opcional: cache de build
if [[ "$INCLUDE_GLOBAL_BUILDER_CACHE" -eq 1 ]]; then
  run_cmd docker builder prune -f --filter until=240h
fi

echo
echo "Concluido."
