#!/bin/bash

# === n8n Auto Installer - PRO VERSION V2 ===
# By OpenAI Assistant - Customized for Community Sharing

# Mau sac
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Kiem tra quyen root
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}Loi: Ban phai chay script nay bang quyen root!${NC}"
   exit 1
fi

clear
echo -e "${GREEN}=== Bat dau cai dat n8n PRO - Final Version ===${NC}"

# Nhap domain
echo "Nhap domain hoac subdomain (vi du: n8n.tenmien.com):"
read DOMAIN_NAME

# Tu dong tao thong tin
POSTGRES_DB="n8n_$(openssl rand -hex 4)"
POSTGRES_USER="n8nuser_$(openssl rand -hex 2)"
POSTGRES_PASSWORD="$(openssl rand -base64 12)"
N8N_BASIC_USER="admin_$(openssl rand -hex 2)"
N8N_BASIC_PASSWORD="$(openssl rand -base64 12)"
N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)

INSTALL_DIR="/opt/n8n"
BACKUP_DIR="/opt/backups"
TIMEZONE="Asia/Ho_Chi_Minh"

# Cap nhat he thong
apt update && apt upgrade -y

# Cai dat goi can thiet
apt install -y curl sudo ufw nginx certbot python3-certbot-nginx docker.io docker-compose
systemctl start docker
systemctl enable docker

# Kiem tra docker
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}Docker khong duoc cai dat dung. Thoat.${NC}"
    exit 1
fi

# Tuong lua
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw --force enable

# Xoa cai dat cu (neu co)
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${RED}Phat hien n8n cu, dang xoa...${NC}"
    cd $INSTALL_DIR
    docker-compose down
    cd /
    rm -rf $INSTALL_DIR
fi
rm -f /etc/nginx/sites-available/n8n
rm -f /etc/nginx/sites-enabled/n8n

# Tao dummy nginx config de certbot hoat dong
echo -e "${GREEN}Tao file nginx tam thoi cho certbot...${NC}"
cat > /etc/nginx/sites-available/n8n <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;
    location / {
        return 200 'n8n install in progress';
    }
}
EOF
ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/ || true
nginx -t && systemctl reload nginx

# Lay SSL
echo -e "${GREEN}Dang lay SSL Let's Encrypt...${NC}"
certbot --nginx --non-interactive --agree-tos -m admin@$DOMAIN_NAME -d $DOMAIN_NAME

# Tao folder install
mkdir -p $INSTALL_DIR $BACKUP_DIR
cd $INSTALL_DIR

# Tao file .env
cat > .env <<EOF
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
DOMAIN_NAME=$DOMAIN_NAME
N8N_BASIC_AUTH_USER=$N8N_BASIC_USER
N8N_BASIC_AUTH_PASSWORD=$N8N_BASIC_PASSWORD
GENERIC_TIMEZONE=$TIMEZONE
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY
EOF

# Tao file docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  postgres:
    image: postgres:14
    restart: always
    environment:
      POSTGRES_USER: \${POSTGRES_USER}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      POSTGRES_DB: \${POSTGRES_DB}
    volumes:
      - ./postgres_data:/var/lib/postgresql/data

  n8n:
    image: docker.n8n.io/n8nio/n8n
    restart: always
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=\${POSTGRES_DB}
      - DB_POSTGRESDB_USER=\${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=\${POSTGRES_PASSWORD}
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
    ports:
      - "5678:5678"
    volumes:
      - ./n8n_data:/home/node/.n8n
    depends_on:
      - postgres
EOF

# Khoi dong container
docker-compose up -d

# Cap nhat lai nginx proxy chinh thuc
cat > /etc/nginx/sites-available/n8n <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN_NAME;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

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

# Backup script
cat > /usr/local/bin/backup_n8n.sh <<EOF
#!/bin/bash
DATE=\$(date +%F)
cd $INSTALL_DIR
tar -czf $BACKUP_DIR/n8n_data_\$DATE.tar.gz ./n8n_data
docker exec n8n_postgres_1 pg_dump -U $POSTGRES_USER $POSTGRES_DB > $BACKUP_DIR/n8n_db_\$DATE.sql
find $BACKUP_DIR/ -type f -mtime +7 -exec rm {} \\;
EOF

chmod +x /usr/local/bin/backup_n8n.sh

# Cronjob backup
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup_n8n.sh") | crontab -

# Hoan tat
echo -e "${GREEN}=== CAI DAT HOAN TAT! ===${NC}"
echo -e "👉 Truy cap n8n: https://$DOMAIN_NAME"
echo -e ""
echo -e "=== THONG TIN DANG NHAP ==="
echo -e "Username: $N8N_BASIC_USER"
echo -e "Password: $N8N_BASIC_PASSWORD"
echo -e ""
echo -e "=== KET NOI DATABASE (Node PostgreSQL) ==="
echo -e "Host: postgres"
echo -e "Database: $POSTGRES_DB"
echo -e "User: $POSTGRES_USER"
echo -e "Password: $POSTGRES_PASSWORD"
echo -e ""
echo -e "${GREEN}Backup tu dong tai: $BACKUP_DIR (giu 7 ngay gan nhat).${NC}"
