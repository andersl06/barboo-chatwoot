# barboo-chatwoot

Projeto de infraestrutura isolado para Chatwoot self-hosted com Docker, preparado para:

- execucao local segura (`web + worker + postgres + redis`)
- transicao para deploy em Railway (`web + worker`, com Postgres/Redis gerenciados)

Este repositorio nao faz parte do app principal Barboo.

## Visao Geral Da Arquitetura

- Local:
  - `chatwoot-web` (Rails)
  - `chatwoot-worker` (Sidekiq)
  - `postgres` (dados locais persistentes)
  - `redis` (fila/cache locais persistentes)
- Producao (Railway):
  - `chatwoot-web` e `chatwoot-worker` em container
  - `POSTGRES_HOST` apontando para Postgres gerenciado
  - `REDIS_URL` apontando para Redis gerenciado
  - storage recomendado fora do container (ex.: S3 compatível)

## Pre-Requisitos

- Docker Desktop / Docker Engine + Compose v2
- Bash (Git Bash ou WSL no Windows) para executar scripts `./scripts/*.sh`
- `openssl` (recomendado, para gerar segredos)

## Estrutura

```text
.
|-- README.md
|-- .env.example
|-- .gitignore
|-- compose.local.yml
|-- compose.prod.example.yml
|-- docker/
|   |-- chatwoot/
|   |   |-- Dockerfile
|   |   `-- entrypoints/
|   |       `-- chatwoot-entrypoint.sh
|   `-- nginx/
|       `-- default.conf.example
|-- scripts/
|   |-- audit-docker.sh
|   |-- cleanup-docker-safe.sh
|   |-- prepare-local.sh
|   |-- prepare-railway.md
|   |-- backup.sh
|   `-- restore.sh
`-- docs/
    |-- arquitetura.md
    |-- deploy-local.md
    |-- deploy-railway.md
    |-- seguranca.md
    |-- operacao.md
    `-- reports/
        |-- docker-audit-before-2026-04-21.md
        `-- docker-audit-after-2026-04-21.md
```

## Passo A Passo Local

1. Copie o arquivo de ambiente:
```bash
cp .env.example .env
```
2. Edite `.env` e troque placeholders (`CHANGE_ME`).
3. Suba local com script:
```bash
./scripts/prepare-local.sh
```
4. Acesse:
```text
http://localhost:3000
```

## Comandos Principais

- Auditoria Docker (somente leitura):
```bash
./scripts/audit-docker.sh
```

- Limpeza conservadora (dry-run):
```bash
./scripts/cleanup-docker-safe.sh
```

- Aplicar limpeza conservadora:
```bash
./scripts/cleanup-docker-safe.sh --yes
```

- Subir stack local manualmente:
```bash
docker compose -f compose.local.yml up -d --build
```

- Preparar banco (migrations/seed do Chatwoot):
```bash
docker compose -f compose.local.yml run --rm chatwoot-web bundle exec rails db:chatwoot_prepare
```

- Ver logs:
```bash
docker compose -f compose.local.yml logs -f chatwoot-web
docker compose -f compose.local.yml logs -f chatwoot-worker
```

- Parar sem apagar volumes:
```bash
docker compose -f compose.local.yml down
```

## Troubleshooting Rapido

- `chatwoot-web` nao sobe:
  - valide `.env` (principalmente `SECRET_KEY_BASE`, `POSTGRES_*`, `REDIS_*`)
  - rode `db:chatwoot_prepare`
- erro de conexao no Postgres:
  - confira `POSTGRES_HOST=postgres` no local
  - veja healthcheck: `docker compose -f compose.local.yml ps`
- erro de Redis auth:
  - `REDIS_PASSWORD` deve ser identico no `.env` e no container `redis`

## Proximos Passos Para Railway

- Ler [`docs/deploy-railway.md`](docs/deploy-railway.md)
- Ler [`scripts/prepare-railway.md`](scripts/prepare-railway.md)
- Usar `compose.prod.example.yml` como referencia de separacao `web` e `worker`

## Seguranca

- nao commitar `.env`
- rotacionar segredos periodicamente
- usar dominio dedicado (ex.: `chat.barboo.com.br`)
- forcar HTTPS em producao (`FORCE_SSL=true`)
- expor apenas o necessario (no local, apenas `127.0.0.1:3000`)

Checklist detalhado em [`docs/seguranca.md`](docs/seguranca.md).

## Nunca Deve Ser Commitado

- `.env`
- backups em `backups/`
- segredos, tokens, chaves privadas
- dumps de banco contendo dados reais
