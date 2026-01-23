#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Reviactyl Installer"
echo "  Ubuntu 22.04 | Pterodactyl"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PTERO_DIR="/var/www/pterodactyl"
WEBUSER="www-data"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Jalankan sebagai root!"
  exit 1
fi

if [ ! -d "$PTERO_DIR" ]; then
  echo "❌ Folder Pterodactyl tidak ditemukan!"
  exit 1
fi

cd $PTERO_DIR

echo "[1/6] Install dependency..."
apt update -y
apt install -y curl wget unzip git nodejs npm

npm install -g yarn

echo "[2/6] Download Reviactyl..."
rm -rf reviactyl
git clone https://github.com/reviactyl/panel.git reviactyl

echo "[3/6] Apply theme..."
cp -rf reviactyl/* $PTERO_DIR/

echo "[4/6] Build frontend..."
yarn install
yarn build:production

echo "[5/6] Clear cache..."
php artisan optimize:clear
php artisan view:clear
php artisan config:clear
php artisan queue:restart

echo "[6/6] Set permission..."
chown -R $WEBUSER:$WEBUSER $PTERO_DIR
chmod -R 755 storage bootstrap/cache

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " ✅ Reviactyl berhasil dipasang"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
