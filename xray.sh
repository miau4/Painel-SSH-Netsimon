#!/bin/bash

CONFIG="/etc/xray/config.json"
USERS="/etc/xray-manager/users.xray"

RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'

pause() {
    read -p "Pressione ENTER..."
}

install_xray() {
    if command -v xray >/dev/null; then
        echo -e "${CYAN}Xray já instalado${NC}"
        return
    fi

    bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
}

generate_config() {
    PORT=443
    WS_PATH="/ws"

    mkdir -p /etc/xray /var/log/xray

    cat > "$CONFIG" <<EOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$WS_PATH"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

    echo "Config base criada"
}

add_user() {
    UUID=$(cat /proc/sys/kernel/random/uuid)

    jq ".inbounds[0].settings.clients += [{\"id\":\"$UUID\"}]" $CONFIG > /tmp/xray.tmp && mv /tmp/xray.tmp $CONFIG

    echo "$UUID" >> "$USERS"

    echo -e "${GREEN}Usuário criado:${NC}"
    echo "$UUID"
}

restart_xray() {
    systemctl restart xray
}

status_xray() {
    systemctl status xray --no-pager
}

remove_xray() {
    systemctl stop xray
    apt remove xray -y
    rm -rf /etc/xray
}

# MENU
while true; do
clear
echo "========== XRAY MANAGER =========="
echo "1) Instalar Xray"
echo "2) Gerar Config Base"
echo "3) Adicionar Usuário"
echo "4) Reiniciar"
echo "5) Status"
echo "6) Remover"
echo "0) Voltar"
echo "=================================="
read -p "Escolha: " op

case $op in
1) install_xray; pause ;;
2) generate_config; pause ;;
3) add_user; pause ;;
4) restart_xray; pause ;;
5) status_xray; pause ;;
6) remove_xray; pause ;;
0) break ;;
*) echo "Inválido"; sleep 1 ;;
esac

done
