#!/bin/bash

# Script per reiniciar tots els serveis del SOC Client

echo "═══════════════════════════════════════════════════════"
echo "    Reiniciant SOC Client"
echo "═══════════════════════════════════════════════════════"

cd "$(dirname "$0")/.." || exit 1

echo "[INFO] Aturant contenidors..."
docker compose down

echo "[INFO] Iniciant contenidors..."
docker compose up -d

echo "[INFO] Esperant 10 segons..."
sleep 10

echo "[INFO] Estat dels contenidors:"
docker compose ps

echo ""
echo "═══════════════════════════════════════════════════════"
echo "    ✓ Reinici completat"
echo "═══════════════════════════════════════════════════════"
