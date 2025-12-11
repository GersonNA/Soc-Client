#!/bin/bash

# Script per veure logs dels serveis

SERVICE=$1

if [ -z "$SERVICE" ]; then
    echo "Ús: $0 [wireguard|wazuh|zabbix|all]"
    exit 1
fi

cd "$(dirname "$0")/.." || exit 1

case "$SERVICE" in
    wireguard)
        echo "═══════════════════════════════════════════════════════"
        echo "    Logs WireGuard"
        echo "═══════════════════════════════════════════════════════"
        docker logs -f soc-client-wireguard
        ;;
    wazuh)
        echo "═══════════════════════════════════════════════════════"
        echo "    Logs Wazuh Agent"
        echo "═══════════════════════════════════════════════════════"
        docker logs -f soc-client-wazuh-agent
        ;;
    zabbix)
        echo "═══════════════════════════════════════════════════════"
        echo "    Logs Zabbix Agent"
        echo "═══════════════════════════════════════════════════════"
        docker logs -f soc-client-zabbix-agent
        ;;
    all)
        echo "═══════════════════════════════════════════════════════"
        echo "    Logs de tots els serveis"
        echo "═══════════════════════════════════════════════════════"
        docker compose logs -f
        ;;
    *)
        echo "Servei no reconegut: $SERVICE"
        echo "Ús: $0 [wireguard|wazuh|zabbix|all]"
        exit 1
        ;;
esac
