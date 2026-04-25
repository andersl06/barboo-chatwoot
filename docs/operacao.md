# Operacao

## Subir Ambiente

```bash
./scripts/prepare-local.sh
```

## Verificar Saude

```bash
docker compose -f compose.local.yml ps
docker compose -f compose.local.yml logs -f chatwoot-web
docker compose -f compose.local.yml logs -f chatwoot-worker
```

## Preparar Banco / Migrations

```bash
docker compose -f compose.local.yml run --rm chatwoot-web bundle exec rails db:chatwoot_prepare
```

## Desligar Corretamente

```bash
docker compose -f compose.local.yml down
```

## Backup

```bash
./scripts/backup.sh
```

## Restore

Dry-run:

```bash
./scripts/restore.sh --db backups/chatwoot_db_YYYYMMDD_HHMMSSZ.sql.gz
```

Aplicar:

```bash
./scripts/restore.sh --db backups/chatwoot_db_YYYYMMDD_HHMMSSZ.sql.gz --storage backups/chatwoot_storage_YYYYMMDD_HHMMSSZ.tar.gz --yes
```

## Auditoria E Limpeza Docker

Auditoria:

```bash
./scripts/audit-docker.sh
```

Limpeza conservadora:

```bash
./scripts/cleanup-docker-safe.sh
./scripts/cleanup-docker-safe.sh --yes
```
