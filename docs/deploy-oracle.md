# Deploy Chatwoot — Oracle Cloud Free Tier

Guia completo para subir o barboo-chatwoot em uma VM da Oracle Cloud (Always Free).

---

## 1. Criar a VM Instance (configuração correta)

### 1.1 Trocar o Shape — OBRIGATÓRIO

O shape **VM.Standard.E2.1.Micro (1 GB RAM) NÃO é suficiente** para Chatwoot.
Rails + Sidekiq + Postgres + Redis consomem ~1.5–2 GB.

Na tela de criação da instância, clique em **"Change shape"** e selecione:

| Campo | Valor |
|---|---|
| Shape series | Ampere (ARM) |
| Shape name | `VM.Standard.A1.Flex` |
| OCPU count | `2` |
| Memory (GB) | `4` |

Isso ainda é **Always Free** (limite: 4 OCPU + 24 GB total entre instâncias A1).

### 1.2 Imagem do SO

Mantenha **Oracle Linux 9** (padrão) — é totalmente suportada.

### 1.3 SSH Key

Em "Add SSH keys":
- Selecione **"Paste public keys"**
- Cole sua chave pública (`~/.ssh/id_rsa.pub` ou `~/.ssh/id_ed25519.pub`)
- Se não tiver uma: `ssh-keygen -t ed25519 -C "oracle-chatwoot"`

### 1.4 Boot Volume

No mínimo **50 GB** (o padrão free tier é 47 GB, suficiente).

### 1.5 Criar a instância

Clique em **"Create"** e aguarde o estado mudar para `RUNNING`.
Anote o **IP público** da instância.

---

## 2. Abrir Portas na Oracle Cloud (Security List)

> Passo crítico — sem isso, HTTP/HTTPS não chegam à VM mesmo com o firewall da VM liberado.

No menu Oracle Cloud:
**Networking → Virtual Cloud Networks → [sua VCN] → Security Lists → Default Security List**

Clique em **"Add Ingress Rules"** e adicione:

| Source CIDR | Protocol | Port | Descrição |
|---|---|---|---|
| `0.0.0.0/0` | TCP | `80` | HTTP |
| `0.0.0.0/0` | TCP | `443` | HTTPS |

A porta 22 (SSH) já vem liberada por padrão.

---

## 3. Configurar a VM (pós-login)

Conecte via SSH:
```bash
ssh -i ~/.ssh/id_ed25519 opc@<IP_PUBLICO>
```

### 3.1 Atualizar o sistema

```bash
sudo dnf update -y
```

### 3.2 Abrir portas no firewall da VM (Oracle Linux usa firewalld)

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

### 3.3 Instalar Docker

```bash
sudo dnf install -y dnf-utils
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker opc
```

Faça logout e login novamente para o grupo `docker` ter efeito:
```bash
exit
ssh -i ~/.ssh/id_ed25519 opc@<IP_PUBLICO>
```

Teste:
```bash
docker run --rm hello-world
```

### 3.4 Instalar Nginx e Certbot

```bash
sudo dnf install -y nginx
sudo dnf install -y epel-release
sudo dnf install -y certbot python3-certbot-nginx
sudo systemctl enable nginx
```

### 3.5 Configurar SWAP (recomendado com 4 GB RAM)

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## 4. Clonar o Repositório

```bash
cd /opt
sudo mkdir chatwoot
sudo chown opc:opc chatwoot
cd chatwoot
git clone <URL_DO_SEU_REPO> .
```

---

## 5. Configurar o `.env` de Produção

```bash
cp .env.example .env
nano .env   # ou vim .env
```

Gere os segredos:
```bash
# SECRET_KEY_BASE
openssl rand -hex 64

# ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
openssl rand -hex 32

# ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
openssl rand -hex 32

# ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
openssl rand -hex 32

# POSTGRES_PASSWORD
openssl rand -hex 24

# REDIS_PASSWORD
openssl rand -hex 24
```

Valores obrigatórios a configurar no `.env`:

```dotenv
# Trocar pela URL real do seu domínio
FRONTEND_URL=https://chat.seudominio.com.br
HELPCENTER_URL=https://chat.seudominio.com.br

FORCE_SSL=true

SECRET_KEY_BASE=<gerado acima>
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=<gerado acima>
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=<gerado acima>
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=<gerado acima>

POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=<gerado acima>

REDIS_URL=redis://redis:6379/0
REDIS_PASSWORD=<gerado acima>

# E-mail (configure com seu provedor SMTP)
MAILER_SENDER_EMAIL=Chatwoot <no-reply@seudominio.com.br>
SMTP_ADDRESS=smtp.seu-provedor.com
SMTP_PORT=587
SMTP_USERNAME=seu@email.com
SMTP_PASSWORD=senha_smtp
```

---

## 6. Configurar Nginx com SSL

### 6.1 Obter certificado SSL (antes de subir o Chatwoot)

Certifique-se de que o DNS do seu domínio já aponta para o IP da VM.

```bash
# Inicie o nginx temporariamente para o certbot validar
sudo systemctl start nginx

# Gere o certificado
sudo certbot --nginx -d chat.seudominio.com.br
```

### 6.2 Copiar e ajustar o config do Nginx

```bash
sudo cp /opt/chatwoot/docker/nginx/default.conf.example /etc/nginx/conf.d/chatwoot.conf
sudo nano /etc/nginx/conf.d/chatwoot.conf
```

Troque `chat.barboo.com.br` pelo seu domínio em todas as linhas.
O certbot já adiciona os caminhos dos certificados automaticamente se você usou `--nginx`.
Se ajustar manualmente, os caminhos serão:
```
/etc/letsencrypt/live/chat.seudominio.com.br/fullchain.pem
/etc/letsencrypt/live/chat.seudominio.com.br/privkey.pem
```

Teste e recarregue:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 6.3 Renovação automática do SSL

```bash
sudo systemctl enable --now certbot-renew.timer
```

---

## 7. Build e Primeiro Deploy

### 7.1 Build da imagem

```bash
cd /opt/chatwoot
docker compose -f compose.oracle.yml build
```

> O build pode demorar 5–10 minutos na primeira vez.

### 7.2 Subir banco e redis primeiro

```bash
docker compose -f compose.oracle.yml up -d postgres redis
```

Aguarde os healthchecks passarem:
```bash
docker compose -f compose.oracle.yml ps
```

### 7.3 Preparar o banco (migrations + seed)

```bash
docker compose -f compose.oracle.yml run --rm chatwoot-web \
  bundle exec rails db:chatwoot_prepare
```

### 7.4 Subir todos os serviços

```bash
docker compose -f compose.oracle.yml up -d
```

### 7.5 Verificar status

```bash
docker compose -f compose.oracle.yml ps
docker compose -f compose.oracle.yml logs -f chatwoot-web
```

---

## 8. Criar conta de administrador

Após os containers estarem `healthy`:

```bash
docker compose -f compose.oracle.yml exec chatwoot-web \
  bundle exec rails c
```

No console Rails:
```ruby
# Criar superadmin
account = Account.create!(name: "Barboo", locale: "pt_BR")
user = User.create!(
  name: "Admin",
  email: "seu@email.com",
  password: "senha_forte_aqui",
  role: :administrator,
  account: account
)
AccountUser.create!(account: account, user: user, role: :administrator)
exit
```

Ou acesse `https://chat.seudominio.com.br` — o Chatwoot mostrará tela de setup na primeira vez.

---

## 9. Manter o stack ativo após reboot

O `restart: unless-stopped` no compose já garante reinício automático dos containers junto com o Docker. O Docker está configurado como `systemd` service com `enable`, então sobe com a VM.

Para garantir que o nginx também sobe:
```bash
sudo systemctl enable nginx
```

---

## 10. Comandos de Operação

```bash
# Ver logs em tempo real
docker compose -f compose.oracle.yml logs -f chatwoot-web
docker compose -f compose.oracle.yml logs -f chatwoot-worker

# Parar sem apagar dados
docker compose -f compose.oracle.yml down

# Reiniciar um serviço
docker compose -f compose.oracle.yml restart chatwoot-web

# Atualizar para nova versão do Chatwoot
# 1. Edite CHATWOOT_TAG no .env
# 2. Rebuild
docker compose -f compose.oracle.yml build --no-cache
docker compose -f compose.oracle.yml up -d
# 3. Rode migrations se houver
docker compose -f compose.oracle.yml exec chatwoot-web bundle exec rails db:migrate
```

---

## 11. Backup

Use o script já existente:
```bash
./scripts/backup.sh
```

Configure um cron para backups automáticos:
```bash
crontab -e
# Adicione: backup diário às 2h da manhã
0 2 * * * /opt/chatwoot/scripts/backup.sh >> /var/log/chatwoot-backup.log 2>&1
```

---

## Checklist Rápido

- [ ] Shape trocado para VM.Standard.A1.Flex (2 OCPU, 4 GB)
- [ ] Chave SSH configurada
- [ ] Ingress rules: portas 80 e 443 abertas na Security List da OCI
- [ ] DNS do domínio apontando para o IP da VM
- [ ] Docker instalado e usuário `opc` no grupo `docker`
- [ ] firewalld com HTTP/HTTPS liberados
- [ ] SWAP de 2 GB configurada
- [ ] `.env` preenchido com segredos reais (sem `CHANGE_ME`)
- [ ] `FRONTEND_URL` com o domínio real
- [ ] Certificado SSL gerado com certbot
- [ ] Nginx configurado e testado (`nginx -t`)
- [ ] `docker compose -f compose.oracle.yml build` concluído
- [ ] `db:chatwoot_prepare` executado com sucesso
- [ ] Todos os containers `healthy`
- [ ] Acesso via `https://chat.seudominio.com.br` funcionando