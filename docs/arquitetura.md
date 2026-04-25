# Arquitetura

## Objetivo

Isolar o Chatwoot como stack propria, sem acoplamento ao app principal Barboo.

## Topologia Local (Docker Compose)

- `chatwoot-web`: interface web e API do Chatwoot
- `chatwoot-worker`: processamento assincrono (Sidekiq)
- `postgres`: banco local para desenvolvimento/teste
- `redis`: fila e cache local

Persistencia local:

- `postgres_data`: dados do banco
- `redis_data`: estado do Redis
- `storage_data`: anexos do Chatwoot

Rede:

- `barboo-chatwoot-net` (privada do compose)
- so `127.0.0.1:3000` exposto para acesso local

## Topologia Futura (Railway)

- `chatwoot-web` e `chatwoot-worker` em servicos separados
- Postgres gerenciado (externo ao compose)
- Redis gerenciado (externo ao compose)
- anexos em storage externo (S3/compatibel recomendado)

## Principios

- separar runtime local de runtime de producao
- segredos fora de versionamento
- minimizar superficie exposta
- scripts de operacao com dry-run como padrao quando ha risco
