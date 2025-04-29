#!/bin/bash

# === n8n Auto Installer - PRO VERSION ===
# Customized by Khanh Pham
# Target: Ubuntu 20.04/22.04 Fresh Install

# === Colors ===
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# === Check Root ===
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}Error: You must run this script as root!${NC}"
   exit 1
fi

# === Check Curl ===
command -v curl >/dev/null 2>&1 || { echo -e "${RED}Error: curl is required but not installed. Aborting.${NC}"; exit 1; }

# === Variables ===
INSTALL_DIR="/opt/n8n"
BACKUP_DIR="/opt/backups"
POSTGRES_DB="n8n"
POSTGRES_USER="n8nuser"
TIMEZONE="Asia/Ho_Chi_Minh"
LOG_FILE="$INSTALL_DIR/install.log"

clear
echo -e "${GREEN}=== Welcome to n8n Auto Installer PRO ===${NC}"

# === Input Section ===
echo "Enter your domain or subdomain (example: n8n.yourdomain.com):"
read DOMAIN_NAME

echo "Enter Database Password (PostgreSQL):"
read POSTGRES_PASSWORD

echo "Enter n8n Basic Auth Username (example: admin):"
read N8N_BASIC_USER

echo "Enter n8n Basic Auth Password (example: strongpass123):"
read N8N_BASIC_PASSWORD

N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)

# === Update System ===
echo -e "${GREEN}Updating system and installing required packages...${NC}"
apt update && apt upgrade -y >> $LOG_FILE 2>&1
apt install -y curl sudo ufw nginx certbot python3-certbot-nginx docker.io docker-compose >> $LOG_FILE 2>&1

# === Setup Firewall ===
echo -e "${GREEN}Setting up firewall...${NC}"
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw --force enable

# === Create Directories ===
echo -e "${GREEN}Creating directories...${NC}"
mkdir -p $INSTALL_DIR $BACKUP_DIR
cd $INSTALL_DIR

# === Create .env File ===
echo -e "${GREEN}Creating environment configuration...${NC}"
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

# === Create docker-compose.yml ===
echo -e "${GREEN}Creating Docker Compose file...${NC}"
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

# === Start Services ===
echo -e "${GREEN}Starting Docker containers...${NC}"
docker-compose up -d >> $LOG_FILE 2>&1

# === Setup nginx Config ===
echo -e "${GREEN}Setting up nginx reverse proxy...${NC}"
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

ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/ || true
nginx -t && systemctl reload nginx

# === Obtain SSL Certificate ===
echo -e "${GREEN}Obtaining SSL Certificate with Certbot...${NC}"
certbot --nginx --non-interactive --agree-tos -m admin@$DOMAIN_NAME -d $DOMAIN_NAME

# === Setup Auto Backup Script ===
echo -e "${GREEN}Setting up auto backup script...${NC}"
cat > /usr/local/bin/backup_n8n.sh <<EOF
#!/bin/bash
DATE=\$(date +%F)
cd $INSTALL_DIR
tar -czf $BACKUP_DIR/n8n_data_\$DATE.tar.gz ./n8n_data
docker exec n8n_postgres_1 pg_dump -U $POSTGRES_USER $POSTGRES_DB > $BACKUP_DIR/n8n_db_\$DATE.sql
find $BACKUP_DIR/ -type f -mtime +7 -exec rm {} \;
EOF

chmod +x /usr/local/bin/backup_n8n.sh

# === Setup Cronjob ===
echo -e "${GREEN}Adding cronjob for daily backup at 2 AM...${NC}"
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup_n8n.sh") | crontab -

# === Finish ===
echo -e "${GREEN}=== Installation Completed Successfully! ===${NC}"
echo -e "${GREEN}Access your n8n instance at: https://$DOMAIN_NAME${NC}"
echo -e "${GREEN}Daily backups will be stored in $BACKUP_DIR (keeping last 7 days).${NC}"
