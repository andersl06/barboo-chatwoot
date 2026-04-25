# Deploy Local

## 1) Preparar ambiente

```bash
cp .env.example .env
```

Edite `.env` e garanta que nao existe `CHANGE_ME`.

## 2) Subir stack

```bash
./scripts/prepare-local.sh
```

Fluxo executado pelo script:

1. sobe `postgres` e `redis`
2. executa `rails db:chatwoot_prepare`
3. sobe `chatwoot-web` e `chatwoot-worker`

## 3) Validar saude

```bash
docker compose -f compose.local.yml ps
docker compose -f compose.local.yml logs -f chatwoot-web
docker compose -f compose.local.yml logs -f chatwoot-worker
```

## 4) Acesso

- URL local: `http://localhost:3000`

## 5) Desligar com seguranca

```bash
docker compose -f compose.local.yml down
```

Para apagar tambem volumes locais (cuidado):

```bash
docker compose -f compose.local.yml down -v
```
