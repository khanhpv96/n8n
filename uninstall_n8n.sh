#!/bin/bash

# === n8n Uninstaller Script ===
# Script go bo hoan toan n8n khoi VPS Ubuntu

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${GREEN}=== BAT DAU GO CAI DAT N8N ===${NC}"

if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}Can chay script bang quyen root!${NC}"
   exit 1
fi

read -p "Ban co chac chan muon go n8n va xoa toan bo du lieu? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo -e "${RED}Da huy thao tac go cai dat.${NC}"
  exit 0
fi

# Dung container va xoa file
INSTALL_DIR="/opt/n8n"
BACKUP_DIR="/opt/backups"

if [ -d "$INSTALL_DIR" ]; then
  echo -e "${GREEN}Dung va xoa Docker container...${NC}"
  cd $INSTALL_DIR
  docker compose down --volumes --remove-orphans
fi

echo -e "${GREEN}Xoa file cau hinh va backup...${NC}"
rm -rf $INSTALL_DIR
rm -rf $BACKUP_DIR

# Xoa nginx cau hinh
echo -e "${GREEN}Xoa nginx config...${NC}"
rm -f /etc/nginx/sites-enabled/n8n
rm -f /etc/nginx/sites-available/n8n
nginx -t && systemctl reload nginx

# Xoa cron backup
crontab -l | grep -v "/usr/local/bin/backup_n8n.sh" | crontab -
rm -f /usr/local/bin/backup_n8n.sh

# Xoa SSL
read -p "Ban co muon xoa luon SSL Let's Encrypt? (yes/no): " REMOVE_SSL
if [ "$REMOVE_SSL" = "yes" ]; then
  echo -e "${GREEN}Dang xoa SSL...${NC}"
  certbot delete --cert-name $(hostname)
fi

# Xong
clear
echo -e "${GREEN}=== N8N DA DUOC GO CAI DAT HOAN TOAN ===${NC}"
echo -e "May chu da tro ve trang thai khong co n8n."
