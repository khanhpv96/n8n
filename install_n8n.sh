#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${GREEN}=== Bat dau cai dat n8n PRO - V6.2 ===${NC}"

if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}Can chay script bang quyen root!${NC}"
   exit 1
fi

read -p "Nhap domain hoac subdomain (VD: n8n.example.com): " DOMAIN_NAME

N8N_BASIC_USER="admin_$(openssl rand -hex 2)"
N8N_BASIC_PASSWORD="$(openssl rand -base64 12)"
N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)
INSTALL_DIR="/opt/n8n"
TIMEZONE="Asia/Ho_Chi_Minh"

echo -e "${GREEN}Kiem tra va go bo cai dat n8n cu neu ton tai...${NC}"
if [ -d "$INSTALL_DIR" ]; then
  cd $INSTALL_DIR
  docker compose down || true
  docker system prune -af || true
  rm -rf $INSTALL_DIR
fi

apt update && apt upgrade -y
apt remove -y docker docker.io docker-compose containerd runc || true

apt install -y ca-certificates curl gnupg lsb-release ufw nginx certbot python3-certbot-nginx software-properties-common
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo -e "${GREEN}Cau hinh DNS cho Docker...${NC}"
cat > /etc/docker/daemon.json <<EOF
{
  "dns": ["8.8.8.8", "1.1.1.1"]
}
EOF
systemctl restart docker

systemctl enable docker
if ! docker info >/dev/null 2>&1; then
  echo -e "${RED}Docker daemon khong hoat dong. Kiem tra lai.${NC}"
  exit 1
fi

ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw --force enable

rm -f /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/n8n
cat > /etc/nginx/sites-available/n8n <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;
    location / {
        return 200 'n8n install is setting up';
    }
    client_max_body_size 50M;
}
EOF
ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

certbot --nginx --non-interactive --agree-tos --register-unsafely-without-email -d $DOMAIN_NAME

mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

cat > .env <<EOF
DOMAIN_NAME=$DOMAIN_NAME
N8N_BASIC_AUTH_USER=$N8N_BASIC_USER
N8N_BASIC_AUTH_PASSWORD=$N8N_BASIC_PASSWORD
GENERIC_TIMEZONE=$TIMEZONE
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY
EXECUTIONS_DATA_SAVE_ON_SUCCESS=none
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EXECUTIONS_DATA_MAX_AGE=168
N8N_PAYLOAD_SIZE_MAX=50
EOF

cat > docker-compose.yml <<EOF
version: '3.8'

services:
  n8n:
    image: docker.n8n.io/n8nio/n8n
    restart: always
    dns:
      - 8.8.8.8
      - 1.1.1.1
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=\${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=\${N8N_BASIC_AUTH_PASSWORD}
      - N8N_HOST=\${DOMAIN_NAME}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://\${DOMAIN_NAME}/
      - GENERIC_TIMEZONE=\${GENERIC_TIMEZONE}
      - N8N_ENCRYPTION_KEY=\${N8N_ENCRYPTION_KEY}
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=\${EXECUTIONS_DATA_SAVE_ON_SUCCESS}
      - EXECUTIONS_DATA_SAVE_ON_ERROR=\${EXECUTIONS_DATA_SAVE_ON_ERROR}
      - EXECUTIONS_DATA_MAX_AGE=\${EXECUTIONS_DATA_MAX_AGE}
      - N8N_PAYLOAD_SIZE_MAX=\${N8N_PAYLOAD_SIZE_MAX}
    ports:
      - "5678:5678"
    volumes:
      - ./n8n_data:/home/node/.n8n
EOF

mkdir -p ./n8n_data
chown -R 1000:1000 ./n8n_data
docker compose up -d

cat > /etc/nginx/sites-available/n8n <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;
    return 301 https://\$host\$request_uri;
    client_max_body_size 50M;
}

server {
    listen 443 ssl;
    server_name $DOMAIN_NAME;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    client_max_body_size 50M;

    location / {
        proxy_pass http://localhost:5678/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
nginx -t && systemctl reload nginx

clear
echo -e "${GREEN}=== CAI DAT HOAN TAT! ===${NC}"
echo -e "👉 Truy cap n8n: https://$DOMAIN_NAME"
echo -e "👤 Username: $N8N_BASIC_USER"
echo -e "🔑 Password: $N8N_BASIC_PASSWORD"
