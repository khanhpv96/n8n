#!/bin/bash

# === n8n Auto Installer - PRO VERSION - Final ===
# Customized for community use

# Mau sac
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Kiem tra quyen root
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}Loi: Ban phai chay script nay bang quyen root!${NC}"
   exit 1
fi

# Bien
INSTALL_DIR="/opt/n8n"
BACKUP_DIR="/opt/backups"
TIMEZONE="Asia/Ho_Chi_Minh"
LOG_FILE="$INSTALL_DIR/install.log"

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

# Cap nhat va cai goi can thiet
echo -e "${GREEN}Dang cap nhat he thong va cai dat cac goi can thiet...${NC}"
apt update && apt upgrade -y
echo -e "${GREEN}Dang cai dat cac goi can thiet, vui long cho doi...${NC}"
apt install -y curl sudo ufw nginx certbot python3-certbot-nginx docker.io docker-compose
systemctl enable docker
systemctl start docker
echo -e "${GREEN}Cai dat goi can thiet hoan tat.${NC}"

# Kiem tra neu n8n cu ton tai thi xoa
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${RED}Phat hien cai dat n8n cu, dang xoa...${NC}"
    cd $INSTALL_DIR
    docker-compose down
    cd /
    rm -rf $INSTALL_DIR
fi
rm -f /etc/nginx/sites-enabled/n8n
rm -f /etc/nginx/sites-available/n8n
systemctl reload nginx

# Tao moi thu muc
echo -e "${GREEN}Dang tao thu muc moi...${NC}"
mkdir -p $INSTALL_DIR $BACKUP_DIR
cd $INSTALL_DIR

# Tao file .env
echo -e "${GREEN}Dang tao file .env...${NC}"
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

# Tao docker-compose.yml
echo -e "${GREEN}Dang tao docker-compose.yml...${NC}"
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

# Khoi dong docker
echo -e "${GREEN}Dang khoi dong Docker...${NC}"
docker-compose up -d

# Cau hinh nginx
echo -e "${GREEN}Dang cau hinh nginx...${NC}"
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
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/ || true
nginx -t && systemctl reload nginx

# Lay SSL
echo -e "${GREEN}Dang lay SSL Let's Encrypt...${NC}"
certbot --nginx --non-interactive --agree-tos -m admin@$DOMAIN_NAME -d $DOMAIN_NAME

# Tao backup script
echo -e "${GREEN}Dang tao script backup...${NC}"
cat > /usr/local/bin/backup_n8n.sh <<EOF
#!/bin/bash
DATE=\$(date +%F)
cd $INSTALL_DIR
tar -czf $BACKUP_DIR/n8n_data_\$DATE.tar.gz ./n8n_data
docker exec n8n_postgres_1 pg_dump -U $POSTGRES_USER $POSTGRES_DB > $BACKUP_DIR/n8n_db_\$DATE.sql
find $BACKUP_DIR/ -type f -mtime +7 -exec rm {} \\;
EOF

chmod +x /usr/local/bin/backup_n8n.sh

# Them cronjob backup
echo -e "${GREEN}Them cronjob backup hang ngay...${NC}"
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
echo -e "${GREEN}Backup duoc tu dong tao o thu muc: $BACKUP_DIR (giu 7 ngay gan nhat).${NC}"
