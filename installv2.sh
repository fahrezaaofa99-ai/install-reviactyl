#!/bin/bash

# Pterodactyl Multi-Theme Installer & Toolkit
# Supports: Reviactyl, NookTheme, Nightcore, Enola, Twilight
# Created by Assistant

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Konfigurasi
PANEL_DIR="/var/www/pterodactyl"
BACKUP_DIR="/var/www/pterodactyl_backup_$(date +%F_%H-%M)"

# Cek Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Harap jalankan script ini sebagai root (sudo su)${NC}"
  exit
fi

# Banner
clear
echo -e "${BLUE}=================================================${NC}"
echo -e "${YELLOW}       PTERODACTYL MULTI-THEME TOOLKIT           ${NC}"
echo -e "${BLUE}=================================================${NC}"
echo -e "Toolkit ini memungkinkan Anda menginstall berbagai theme"
echo -e "untuk Pterodactyl Panel dengan mudah dan aman."
echo -e ""

# Cek apakah Pterodactyl terinstall
if [ ! -d "$PANEL_DIR" ]; then
    echo -e "${RED}[!] Pterodactyl Panel tidak ditemukan di $PANEL_DIR${NC}"
    echo -e "${YELLOW}Script ini adalah Theme Installer. Harap install Pterodactyl Panel terlebih dahulu.${NC}"
    echo -e "${YELLOW}Pastikan Anda menjalankan script ini di server yang sudah terinstall Pterodactyl.${NC}"
    exit 1
else
    echo -e "${GREEN}[✓] Pterodactyl Panel terdeteksi.${NC}"
    echo -e ""
    echo -e "${BLUE}Pilih Theme yang ingin diinstall:${NC}"
    echo -e "1. ${GREEN}Blueprint Framework${NC} (Required for some extensions)"
    echo -e "2. ${GREEN}Reviactyl${NC} (Full Remake, Modern UI)"
    echo -e "3. ${GREEN}NookTheme${NC} (Clean, Modern, Open Source)"
    echo -e "4. ${GREEN}Nightcore${NC} (Dark Mode, Purple Accents)"
    echo -e "5. ${GREEN}Enola${NC} (Elegant Dark)"
    echo -e "6. ${GREEN}Twilight${NC} (Deep Dark)"
    echo -e "7. ${YELLOW}Stellar${NC} (Premium - Manual Upload)"
    echo -e "8. ${GREEN}Recolor${NC} (Blueprint Extension)"
    echo -e "9. ${YELLOW}Restore Original Pterodactyl${NC} (Kembali ke awal)"
    echo -e "0. Keluar"
    echo -e ""
    read -p "Pilih menu (0-9): " THEME_CHOICE
fi

if [ "$THEME_CHOICE" == "0" ]; then
    exit
fi

# Fungsi Backup
backup_panel() {
    echo -e "${YELLOW}[+] Membuat Backup Panel...${NC}"
    mkdir -p "$BACKUP_DIR"
    rsync -av --exclude 'storage' --exclude 'node_modules' --exclude '.git' "$PANEL_DIR/" "$BACKUP_DIR/"
    echo -e "${GREEN}[✓] Backup tersimpan di: $BACKUP_DIR${NC}"
}

# Fungsi Install Dependencies
install_dependencies() {
    echo -e "${YELLOW}[+] Menginstall Dependencies (zip, unzip, curl, tar)...${NC}"
    apt update -y
    apt install -y zip unzip curl tar
}

# Fungsi Install Dependencies (NodeJS/Yarn) jika dibutuhkan
install_build_tools() {
    echo -e "${YELLOW}[+] Mengecek Build Tools (NodeJS & Yarn)...${NC}"
    
    # Unset NODE_OPTIONS to avoid --openssl-legacy-provider issues with Node 20
    unset NODE_OPTIONS
    
    # Check for Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -lt 20 ]; then
            echo -e "${YELLOW}[!] Node.js versi lama terdeteksi ($NODE_VERSION). Mengupgrade ke Node.js 20...${NC}"
            curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
            apt install -y nodejs
        fi
    else
        echo -e "Install NodeJS..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt install -y nodejs
    fi
    
    if ! command -v yarn &> /dev/null; then
        echo -e "Install Yarn..."
        npm i -g yarn
    fi
}

# Fungsi Reset Permission
fix_permissions() {
    echo -e "${YELLOW}[+] Memperbaiki Permission...${NC}"
    chown -R www-data:www-data "$PANEL_DIR"
    chmod -R 755 "$PANEL_DIR/storage" "$PANEL_DIR/bootstrap/cache"
}

# --- LOGIKA INSTALASI ---

# Panggil fungsi install_dependencies untuk semua pilihan theme
# Ini memastikan curl, zip, unzip, tar terinstall
install_dependencies

# 1. BLUEPRINT FRAMEWORK
if [ "$THEME_CHOICE" == "1" ]; then
    backup_panel
    echo -e "${BLUE}[+] Menginstall Blueprint Framework...${NC}"
    cd "$PANEL_DIR"
    
    # Environment variable untuk Blueprint
    export PTERODACTYL_DIRECTORY="$PANEL_DIR"
    
    install_build_tools
    
    # Pastikan dependencies node terinstall (Penting untuk build)
    echo -e "${YELLOW}[+] Menjalankan yarn install...${NC}"
    npm i -g yarn
    yarn install
    
    # Tambahan dependencies yang sering missing
    echo -e "${YELLOW}[+] Menginstall dependencies tambahan (webpack, react)...${NC}"
    yarn add cross-env webpack webpack-cli react react-dom --dev

    
    wget --no-check-certificate "$(curl -s -k -H "User-Agent: Mozilla/5.0" https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep -o '"browser_download_url": *"[^"]*release.zip"' | head -n 1 | cut -d '"' -f 4)" -O "$PANEL_DIR/release.zip"
    unzip -o release.zip
    
    # Konfigurasi Blueprint (.blueprintrc) - WAJIB
    echo -e "${YELLOW}[+] Membuat konfigurasi .blueprintrc...${NC}"
    echo 'WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";' > "$PANEL_DIR/.blueprintrc"

    chmod +x blueprint.sh
    bash blueprint.sh
    rm release.zip
    
    # Finalisasi untuk mencegah "Unfinished installation"
    echo -e "${YELLOW}[+] Memverifikasi instalasi Blueprint...${NC}"
    if [ -f "/usr/local/bin/blueprint" ]; then
        echo -e "${BLUE}[+] Menjalankan blueprint -upgrade untuk memastikan build selesai...${NC}"
        /usr/local/bin/blueprint -upgrade
    elif command -v blueprint &> /dev/null; then
        blueprint -upgrade
    fi
    
    fix_permissions
    echo -e "${GREEN}[✓] Blueprint Framework berhasil diinstall!${NC}"

# 2. REVIACTYL
elif [ "$THEME_CHOICE" == "2" ]; then
    backup_panel
    echo -e "${BLUE}[+] Menginstall Reviactyl...${NC}"
    cd "$PANEL_DIR"
    php artisan down
    curl -L -k -H "User-Agent: Mozilla/5.0" -o panel.tar.gz https://github.com/reviactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    composer install --no-dev --optimize-autoloader
    php artisan migrate --seed --force
    php artisan view:clear
    php artisan config:clear
    fix_permissions
    php artisan up
    echo -e "${GREEN}[✓] Reviactyl berhasil diinstall!${NC}"

# 3. NOOKTHEME
elif [ "$THEME_CHOICE" == "3" ]; then
    backup_panel
    echo -e "${BLUE}[+] Menginstall NookTheme...${NC}"
    cd "$PANEL_DIR"
    php artisan down
    curl -L -k -H "User-Agent: Mozilla/5.0" -o panel.tar.gz https://github.com/Nookure/NookTheme/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    composer install --no-dev --optimize-autoloader
    php artisan migrate --seed --force
    php artisan view:clear
    php artisan config:clear
    fix_permissions
    php artisan up
    echo -e "${GREEN}[✓] NookTheme berhasil diinstall!${NC}"

# 4. NIGHTCORE
elif [ "$THEME_CHOICE" == "4" ]; then
    backup_panel
    echo -e "${BLUE}[+] Menginstall Nightcore...${NC}"
    # Menggunakan script installer external yang terpercaya/populer untuk Nightcore
    bash <(curl -s -k -H "User-Agent: Mozilla/5.0" https://raw.githubusercontent.com/NoPro200/Pterodactyl_Nightcore_Theme/main/install.sh)
    fix_permissions
    echo -e "${GREEN}[✓] Nightcore Theme berhasil diinstall!${NC}"

# 5. ENOLA
elif [ "$THEME_CHOICE" == "5" ]; then
    backup_panel
    install_build_tools
    echo -e "${BLUE}[+] Menginstall Enola Theme...${NC}"
    cd "$PANEL_DIR"
    bash <(curl -s -k -H "User-Agent: Mozilla/5.0" https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoThemes/main/install.sh)
    echo -e "${YELLOW}[!] Script installer external telah dijalankan.${NC}"
    echo -e "${YELLOW}[!] Silakan pilih 'Enola' pada menu yang muncul jika diminta.${NC}"

# 6. TWILIGHT
elif [ "$THEME_CHOICE" == "6" ]; then
    backup_panel
    install_build_tools
    echo -e "${BLUE}[+] Menginstall Twilight Theme...${NC}"
    bash <(curl -s -k -H "User-Agent: Mozilla/5.0" https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoThemes/main/install.sh)
    echo -e "${YELLOW}[!] Script installer external telah dijalankan.${NC}"
    echo -e "${YELLOW}[!] Silakan pilih 'Twilight' pada menu yang muncul jika diminta.${NC}"

# 7. STELLAR (MANUAL)
elif [ "$THEME_CHOICE" == "7" ]; then
    backup_panel
    echo -e "${BLUE}[+] Menyiapkan Instalasi Stellar Theme...${NC}"
    echo -e "${YELLOW}[!] Stellar adalah theme berbayar/premium.${NC}"
    echo -e "Silakan upload file ${GREEN}stellar.zip${NC} (atau nama theme lain) ke folder /root/ di VPS ini."
    echo -e "Jika sudah, tekan ENTER untuk melanjutkan."
    read -p ""
    
    if [ -f "/root/stellar.zip" ]; then
        echo -e "${GREEN}[+] File stellar.zip ditemukan!${NC}"
        cd "$PANEL_DIR"
        php artisan down
        cp /root/stellar.zip "$PANEL_DIR/"
        unzip -o stellar.zip
        
        # Stellar biasanya tidak butuh build jika file zip berisi pre-built files
        # Tapi kita jalankan standard maintenance commands
        chmod -R 755 storage/* bootstrap/cache/
        composer install --no-dev --optimize-autoloader
        php artisan migrate --seed --force
        php artisan view:clear
        php artisan config:clear
        fix_permissions
        php artisan up
        echo -e "${GREEN}[✓] Stellar Theme berhasil diinstall (Manual Mode)!${NC}"
    else
        echo -e "${RED}[!] File /root/stellar.zip tidak ditemukan.${NC}"
        echo -e "Pastikan Anda sudah mengupload file theme yang valid."
        exit 1
    fi

# 8. RECOLOR (BLUEPRINT)
elif [ "$THEME_CHOICE" == "8" ]; then
    backup_panel
    echo -e "${BLUE}[+] Menginstall Recolor (Blueprint Extension)...${NC}"
    cd "$PANEL_DIR"
    
    # Cek Blueprint
    if [ ! -f "$PANEL_DIR/blueprint.sh" ]; then
        echo -e "${RED}[!] Blueprint Framework belum terinstall!${NC}"
        echo -e "${YELLOW}Silakan install Blueprint terlebih dahulu (Menu 1).${NC}"
        exit 1
    fi

    # Recolor Install (via blueprint command if available, or fetch release)
    # Since Recolor is an extension, we usually download the .blueprint file
    # For automation, we try to fetch latest release
    echo -e "${YELLOW}Downloading Recolor Extension...${NC}"
    
    # Fix URL fetch logic - ensure we get valid URL
    RECOLOR_URL=$(curl -s -k -H "User-Agent: Mozilla/5.0" https://api.github.com/repos/BlueprintFramework/Extensions/releases/latest | grep -o '"browser_download_url": *"[^"]*recolor.blueprint"' | head -n 1 | cut -d '"' -f 4)
    
    if [ -z "$RECOLOR_URL" ]; then
        # Fallback to specific version/URL if latest fetch fails
        RECOLOR_URL="https://github.com/BlueprintFramework/Extensions/releases/download/recolor-latest/recolor.blueprint"
    fi
    
    wget --no-check-certificate "$RECOLOR_URL" -O "recolor.blueprint"
    
    # Fix NODE_OPTIONS issue for Blueprint
    unset NODE_OPTIONS
    
    if [ -f "recolor.blueprint" ]; then
        # Cek command blueprint
        if [ -f "/usr/local/bin/blueprint" ]; then
            if /usr/local/bin/blueprint -i recolor.blueprint; then
                echo -e "${GREEN}[✓] Recolor berhasil diinstall!${NC}"
            else
                echo -e "${RED}[!] Gagal menginstall Recolor via /usr/local/bin/blueprint.${NC}"
            fi
        elif command -v blueprint &> /dev/null; then
            if blueprint -i recolor.blueprint; then
                echo -e "${GREEN}[✓] Recolor berhasil diinstall!${NC}"
            else
                echo -e "${RED}[!] Gagal menginstall Recolor via command blueprint.${NC}"
            fi
        else
            echo -e "${RED}[!] Command 'blueprint' tidak ditemukan.${NC}"
            echo -e "${YELLOW}Pastikan Blueprint Framework sudah terinstall dengan benar.${NC}"
            echo -e "Anda bisa mencoba menjalankan: blueprint -i recolor.blueprint secara manual."
        fi
    else
        echo -e "${RED}[!] Gagal mendownload Recolor.${NC}"
        echo -e "Silakan download manual dari GitHub dan gunakan 'blueprint -i [file]'"
    fi

# 9. RESTORE ORIGINAL
elif [ "$THEME_CHOICE" == "9" ]; then
    echo -e "${YELLOW}[+] Mengembalikan ke Pterodactyl Original...${NC}"
    cd "$PANEL_DIR"
    php artisan down
    curl -L -k -H "User-Agent: Mozilla/5.0" -o panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    composer install --no-dev --optimize-autoloader
    php artisan migrate --seed --force
    php artisan view:clear
    php artisan config:clear
    fix_permissions
    php artisan up
    echo -e "${GREEN}[✓] Pterodactyl Original berhasil direstore!${NC}"
fi

# Nginx Config Check (Jika install fresh atau config hilang)
if [ ! -f "/etc/nginx/sites-available/pterodactyl.conf" ]; then
    echo -e "${YELLOW}[+] Membuat konfigurasi Nginx default...${NC}"
    cat <<EOF > /etc/nginx/sites-available/pterodactyl.conf
server {
    listen 80;
    server_name \$PANEL_DOMAIN;
    root /var/www/pterodactyl/public;
    index index.php;
    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;
    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }
    location ~ /\.ht {
        deny all;
    }
}
EOF
    # Link config
    ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf 2>/dev/null
    systemctl restart nginx
fi

echo -e ""
echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}      INSTALASI SELESAI / TASK COMPLETED         ${NC}"
echo -e "${BLUE}=================================================${NC}"
