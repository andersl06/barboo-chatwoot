#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-barboo-chatwoot}"
REPORT_DIR="${REPORT_DIR:-docs/reports}"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
REPORT_FILE="${REPORT_DIR}/docker-audit-${TIMESTAMP//:/-}.md"

mkdir -p "$REPORT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERRO: docker nao encontrado no PATH."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERRO: daemon Docker indisponivel."
  exit 1
fi

mapfile -t RUNNING_CONTAINERS < <(docker ps -q)
mapfile -t EXITED_CONTAINERS < <(docker ps -aq --filter status=exited)
mapfile -t DANGLING_IMAGES < <(docker images -q -f dangling=true)
mapfile -t ALL_IMAGES < <(docker images --format '{{.Repository}}:{{.Tag}}|{{.ID}}|{{.Size}}' | sort -u)
mapfile -t USED_IMAGES < <(docker ps -a --format '{{.Image}}' | sort -u)
mapfile -t CUSTOM_NETWORKS < <(docker network ls --filter type=custom --format '{{.Name}}')
mapfile -t VOLUMES < <(docker volume ls -q)

{
  echo "# Docker Audit"
  echo
  echo "- timestamp_utc: ${TIMESTAMP}"
  echo "- target_project: ${PROJECT_NAME}"
  echo
  echo "## A) Recursos Em Uso Por Outros Projetos"
  if [ "${#RUNNING_CONTAINERS[@]}" -eq 0 ]; then
    echo "- nenhum container rodando"
  else
    for cid in "${RUNNING_CONTAINERS[@]}"; do
      name="$(docker inspect -f '{{.Name}}' "$cid" | sed 's#^/##')"
      image="$(docker inspect -f '{{.Config.Image}}' "$cid")"
      project="$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$cid" 2>/dev/null || true)"
      project="${project:-sem-label-compose}"
      echo "- container: ${name} | image: ${image} | compose_project: ${project} | status: running"
    done
  fi
  echo
  echo "## B) Recursos Abandonados Ou Potencialmente Orfaos"
  if [ "${#EXITED_CONTAINERS[@]}" -eq 0 ]; then
    echo "- nenhum container exited"
  else
    for cid in "${EXITED_CONTAINERS[@]}"; do
      name="$(docker inspect -f '{{.Name}}' "$cid" | sed 's#^/##')"
      image="$(docker inspect -f '{{.Config.Image}}' "$cid")"
      status="$(docker inspect -f '{{.State.Status}}' "$cid")"
      project="$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$cid" 2>/dev/null || true)"
      echo "- container: ${name} | image: ${image} | compose_project: ${project:-sem-label-compose} | status: ${status}"
    done
  fi
  echo
  echo "### Imagens sem container associado"
  found_unused_image=0
  for line in "${ALL_IMAGES[@]}"; do
    image_ref="${line%%|*}"
    image_tail="${line#*|}"
    image_id="${image_tail%%|*}"
    image_size="${line##*|}"
    if [ "$image_ref" = "<none>:<none>" ]; then
      continue
    fi
    if ! printf '%s\n' "${USED_IMAGES[@]}" | grep -Fxq "$image_ref"; then
      echo "- image: ${image_ref} | id: ${image_id} | size: ${image_size}"
      found_unused_image=1
    fi
  done
  if [ "$found_unused_image" -eq 0 ]; then
    echo "- nenhuma imagem sem container associado"
  fi
  echo
  echo "### Redes custom sem containers"
  found_unused_network=0
  for net in "${CUSTOM_NETWORKS[@]}"; do
    count="$(docker network inspect "$net" --format '{{len .Containers}}')"
    if [ "$count" = "0" ]; then
      echo "- network: ${net}"
      found_unused_network=1
    fi
  done
  if [ "$found_unused_network" -eq 0 ]; then
    echo "- nenhuma rede custom sem uso"
  fi
  echo
  echo "### Volumes sem containers"
  found_unused_volume=0
  for vol in "${VOLUMES[@]}"; do
    attached="$(docker ps -a --filter "volume=${vol}" --format '{{.Names}}')"
    if [ -z "$attached" ]; then
      echo "- volume: ${vol}"
      found_unused_volume=1
    fi
  done
  if [ "$found_unused_volume" -eq 0 ]; then
    echo "- nenhum volume sem uso"
  fi
  echo
  echo "## C) Candidatos A Limpeza Conservadora"
  if [ "${#DANGLING_IMAGES[@]}" -eq 0 ]; then
    echo "- dangling images: nenhum"
  else
    echo "- dangling images:"
    for id in "${DANGLING_IMAGES[@]}"; do
      echo "  - ${id}"
    done
  fi
  echo "- stopped containers: revisar manualmente antes de remover"
  echo "- build cache: pode ser limpo com impacto apenas em tempo de rebuild"
  echo
  echo "## Comandos Sugeridos (nao executados por este script)"
  echo "1. ./scripts/cleanup-docker-safe.sh"
  echo "2. ./scripts/cleanup-docker-safe.sh --yes"
  echo "3. ./scripts/cleanup-docker-safe.sh --yes --include-global-unused-images"
  echo "4. ./scripts/cleanup-docker-safe.sh --yes --include-global-builder-cache"
} | tee "$REPORT_FILE"

echo
echo "Relatorio salvo em: $REPORT_FILE"
