# Docker Audit Before Cleanup (2026-04-21)

## Resumo Executivo

- Ambiente Docker ativo e funcional.
- Nao existe recurso do novo projeto `barboo-chatwoot` ainda.
- Quase todos os recursos atuais pertencem a outros projetos em execucao.
- Limpeza automatica global nao foi aplicada por seguranca operacional.

## A) Recursos Em Uso Por Outros Projetos (manter)

Containers em execucao:

1. `evolution` (`evoapicloud/evolution-api:latest`) | projeto compose: `evolution-n8n`
2. `n8n` (`n8nio/n8n:latest`) | projeto compose: `evolution-n8n`
3. `postgres` (`postgres:16-alpine`) | projeto compose: `evolution-n8n`
4. `openfinance-db` (`postgres:15`) | projeto compose: `open-finance-batch`
5. `cluster-api-api-1` (`cluster-api-api`) | projeto compose: `cluster-api`

Volumes vinculados a containers ativos:

- `evolution-n8n_evolution_data`
- `evolution-n8n_n8n_data`
- `evolution-n8n_postgres_data`
- `open-finance-batch_pgdata`

Redes custom ativas:

- `cluster-api_default`
- `evolution-n8n_evolution-n8n`
- `open-finance-batch_default`

## B) Recursos Abandonados Ou Potencialmente Orfaos (revisar manualmente)

Container parado:

- `barboo-postgres` (`postgres:15`) status `Exited (255) 3 weeks ago`
- volume associado: `ecc0a693f6303d872a414740ff456e8b14b484c6f996d918b69561f29554b863`

Imagens sem container associado:

- `n8nio/n8n:1.123.4`
- `atendai/evolution-api:latest`

Observacao:

- Esses recursos podem ser historico/rollback de projetos existentes.
- Sem confirmacao explicita, nao foram removidos automaticamente.

## C) Candidatos A Limpeza Conservadora

- dangling images: nenhuma
- redes custom sem uso: nenhuma
- volumes sem uso: nenhum

## Impacto Previsto De Limpeza

- `docker image prune -f`: impacto nulo no estado atual (nenhum dangling).
- `docker container prune -f`: NAO recomendado agora (pode remover `barboo-postgres`).
- remocao de imagens nao usadas: somente com aprovacao explicita.

## Decisao Operacional

- Limpeza global agressiva: nao executada.
- Estrategia adotada: criar projeto isolado de Chatwoot sem tocar em recursos ativos de terceiros.
