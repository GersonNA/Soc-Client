#!/bin/bash

# Script de verificació de salut del SOC Client

echo "═══════════════════════════════════════════════════════"
echo "    SOC Client - Health Check"
echo "═══════════════════════════════════════════════════════"

cd "$(dirname "$0")/.." || exit 1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Comprovar contenidors
echo ""
echo "1. Estat dels Contenidors:"
echo "─────────────────────────────────────────────────────"
if docker compose ps | grep -q "Up"; then
    echo -e "${GREEN}✓${NC} Contenidors en execució"
    docker compose ps
else
    echo -e "${RED}✗${NC} Alguns contenidors no estan funcionant"
    docker compose ps
    exit 1
fi

# Comprovar WireGuard
echo ""
echo "2. WireGuard VPN:"
echo "─────────────────────────────────────────────────────"
if docker exec soc-client-wireguard wg show 2>/dev/null | grep -q "interface"; then
    echo -e "${GREEN}✓${NC} WireGuard actiu"
    docker exec soc-client-wireguard wg show
else
    echo -e "${RED}✗${NC} WireGuard no està actiu"
fi

# Comprovar connectivitat al servidor central
echo ""
echo "3. Connectivitat al Servidor Central (10.0.0.1):"
echo "─────────────────────────────────────────────────────"
if docker exec soc-client-wireguard ping -c 3 10.0.0.1 >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Ping al servidor central exitós"
else
    echo -e "${RED}✗${NC} No es pot fer ping al servidor central"
fi

# Comprovar Wazuh Agent
echo ""
echo "4. Wazuh Agent:"
echo "─────────────────────────────────────────────────────"
if docker logs soc-client-wazuh-agent 2>&1 | grep -q "Connected to enrollment service"; then
    echo -e "${GREEN}✓${NC} Wazuh Agent connectat"
else
    echo -e "${YELLOW}⚠${NC} Wazuh Agent podria no estar connectat"
    echo "Últimes línies del log:"
    docker logs soc-client-wazuh-agent --tail 5
fi

# Comprovar Zabbix Agent
echo ""
echo "5. Zabbix Agent:"
echo "─────────────────────────────────────────────────────"
if docker exec soc-client-zabbix-agent zabbix_agentd -t agent.ping 2>&1 | grep -q "agent.ping"; then
    echo -e "${GREEN}✓${NC} Zabbix Agent respon"
else
    echo -e "${YELLOW}⚠${NC} Zabbix Agent podria no estar responent"
fi

# Resum
echo ""
echo "═══════════════════════════════════════════════════════"
echo "    Health Check Completat"
echo "═══════════════════════════════════════════════════════"
