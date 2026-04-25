# Seguranca

## Regras Fundamentais

- nunca versionar segredos
- nunca expor Postgres/Redis diretamente na internet
- usar HTTPS obrigatorio em producao
- separar claramente ambiente local e producao

## Checklist Antes De Produzir

1. `SECRET_KEY_BASE` forte e unico
2. chaves de Active Record Encryption fortes e unicas
3. `ENABLE_ACCOUNT_SIGNUP=false` (exceto necessidade explicita)
4. `FORCE_SSL=true`
5. dominio dedicado (ex.: `chat.barboo.com.br`)
6. banco/redis gerenciados com credenciais proprias
7. politicas de backup e restore testadas
8. storage de anexos fora do disco local do container
9. logs centralizados sem dados sensiveis
10. rotacao de segredos documentada

## Rotacao De Segredos

Recomendacao:

- trimestral para segredos de app
- imediata em caso de suspeita de vazamento
- apos troca:
  1. atualizar variaveis no provider
  2. reiniciar web e worker
  3. validar login e jobs

## Proxy Reverso

- manter app atras de Nginx/edge proxy
- encaminhar headers `X-Forwarded-*`
- limitar `client_max_body_size` conforme necessidade

## O Que Nao Expor

- porta do Postgres
- porta do Redis
- arquivos de backup sem criptografia
- arquivos `.env` em qualquer repositorio remoto
