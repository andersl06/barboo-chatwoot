# Prepare Railway

Este guia rapido conecta esta estrutura local a um deploy futuro no Railway.

## 1) Modelo de servicos

- Servico 1: `chatwoot-web` (comando Rails web)
- Servico 2: `chatwoot-worker` (comando Sidekiq)
- Dependencias externas:
  - Postgres gerenciado
  - Redis gerenciado

## 2) Build image

- Build a partir de `docker/chatwoot/Dockerfile`
- Mesma imagem para web e worker (mudando apenas `command`)

## 3) Variaveis obrigatorias no Railway

- `RAILS_ENV=production`
- `NODE_ENV=production`
- `INSTALLATION_ENV=docker`
- `FRONTEND_URL=https://chat.seu-dominio.com`
- `SECRET_KEY_BASE=<valor-forte>`
- `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=<valor-forte>`
- `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=<valor-forte>`
- `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=<valor-forte>`
- `POSTGRES_HOST=<host-do-railway-ou-servico-externo>`
- `POSTGRES_PORT=<porta>`
- `POSTGRES_DATABASE=<database>`
- `POSTGRES_USERNAME=<usuario>`
- `POSTGRES_PASSWORD=<senha>`
- `REDIS_URL=redis://<host>:<porta>/<db>`
- `REDIS_PASSWORD=<senha-se-existir>`

## 4) Comandos dos servicos

- Web:
  - `bundle exec rails s -p ${PORT:-3000} -b 0.0.0.0`
- Worker:
  - `bundle exec sidekiq -C config/sidekiq.yml`

## 5) Preparacao de banco no deploy

Executar uma vez por release:

```bash
bundle exec rails db:chatwoot_prepare
```

## 6) Storage recomendado

- Em producao, evite `ACTIVE_STORAGE_SERVICE=local`
- Preferir S3/compatibel para persistencia de anexos

## 7) Dominio custom

- Configurar CNAME para o endpoint do Railway
- Habilitar TLS e forcar `FORCE_SSL=true`
