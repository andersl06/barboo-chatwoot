# Deploy Railway

## Estrategia Recomendada

1. Build de uma unica imagem do Chatwoot (`docker/chatwoot/Dockerfile`)
2. Dois servicos no Railway usando a mesma imagem:
   - `chatwoot-web`
   - `chatwoot-worker`
3. Banco e Redis gerenciados (nao empacotar no mesmo compose de producao)

## Variaveis De Ambiente No Railway

Obrigatorias:

- `RAILS_ENV=production`
- `NODE_ENV=production`
- `INSTALLATION_ENV=docker`
- `FRONTEND_URL=https://chat.barboo.com.br`
- `SECRET_KEY_BASE`
- `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`
- `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`
- `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`
- `POSTGRES_HOST`
- `POSTGRES_PORT`
- `POSTGRES_DATABASE`
- `POSTGRES_USERNAME`
- `POSTGRES_PASSWORD`
- `REDIS_URL`
- `REDIS_PASSWORD` (se aplicavel)

Recomendadas:

- `FORCE_SSL=true`
- `ENABLE_ACCOUNT_SIGNUP=false`
- `ACTIVE_STORAGE_SERVICE=s3`
- `RAILS_LOG_TO_STDOUT=true`

## Comandos Por Servico

- `chatwoot-web`
```bash
bundle exec rails s -p ${PORT:-3000} -b 0.0.0.0
```

- `chatwoot-worker`
```bash
bundle exec sidekiq -C config/sidekiq.yml
```

## Migrations / Prepare

A cada deploy que altera schema:

```bash
bundle exec rails db:chatwoot_prepare
```

## Dominio Custom

1. criar `chat.barboo.com.br` no DNS apontando para Railway
2. habilitar TLS no Railway
3. validar redirecionamento HTTP -> HTTPS
4. confirmar `FRONTEND_URL` e `FORCE_SSL=true`
