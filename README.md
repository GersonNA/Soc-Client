# SOC Client

Agent client per connectar a SOC Central amb WireGuard VPN, Wazuh Agent i Zabbix Agent.

## Descripció

Aquest projecte desplega un client SOC que es connecta al servidor central mitjançant VPN WireGuard i envia dades de monitorització i seguretat.

**Components:**
- **WireGuard Client**: Connexió VPN segura al SOC Central
- **Wazuh Agent**: Monitorització de seguretat (SIEM)
- **Zabbix Agent**: Monitorització d'infraestructura

## Requisits Previs

- Docker i Docker Compose instal·lats
- Configuració WireGuard del servidor central (fitxer .conf)
- Accés al SOC Central per VPN

## Instal·lació

### 1. Clonar Repositori

```bash
cd /opt
sudo git clone git@github.com:GersonNA/Soc-Client.git soc-client
sudo chown -R $USER:$USER soc-client
cd soc-client
```

### 2. Configurar Variables d'Entorn

```bash
cp .env.example .env
nano .env
```

Edita les variables segons la teva configuració:
- `WAZUH_AGENT_NAME`: Nom identificatiu del client
- `ZABBIX_AGENT_HOSTNAME`: Hostname per Zabbix
- Les IPs ja estan configurades per VPN (10.0.0.1)

### 3. Configurar WireGuard

Copia el fitxer de configuració WireGuard proporcionat pel servidor central:

```bash
# Opció 1: Copiar fitxer .conf directament
cp /path/to/wireguard-client.conf config/wireguard/wg0.conf
chmod 600 config/wireguard/wg0.conf

# Opció 2: Crear manualment amb la configuració proporcionada
nano config/wireguard/wg0.conf
```

Contingut típic del fitxer `wg0.conf`:

```ini
[Interface]
PrivateKey = [CLAU_PRIVADA_DEL_CLIENT]
Address = 10.0.0.X/32
DNS = 10.0.0.1, 8.8.8.8

[Peer]
PublicKey = [CLAU_PUBLICA_DEL_SERVIDOR]
Endpoint = soc.aracom.cat:51821
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
```

### 4. Iniciar Serveis

```bash
docker compose up -d

# Verificar estat
docker compose ps
```

### 5. Verificar Connectivitat

**Verificar connexió VPN:**
```bash
# Verificar que WireGuard està connectat
docker exec soc-client-wireguard wg show

# Verificar ping al servidor central
docker exec soc-client-wireguard ping -c 3 10.0.0.1
```

**Verificar Wazuh Agent:**
```bash
# Veure logs de l'agent
docker logs soc-client-wazuh-agent

# Verificar estat
docker exec soc-client-wazuh-agent /var/ossec/bin/agent-control -l
```

**Verificar Zabbix Agent:**
```bash
# Veure logs
docker logs soc-client-zabbix-agent

# Test de connexió
docker exec soc-client-zabbix-agent zabbix_agentd -t agent.ping
```

## Arquitectura

```
┌─────────────────────────────────────────────┐
│           SOC Client (Sucursal)             │
│                                             │
│  ┌────────────┐  ┌────────────┐            │
│  │   Wazuh    │  │  Zabbix    │            │
│  │   Agent    │  │  Agent     │            │
│  └─────┬──────┘  └─────┬──────┘            │
│        │               │                    │
│        └───────┬───────┘                    │
│                │                            │
│        ┌───────▼───────┐                    │
│        │  WireGuard    │                    │
│        │    Client     │                    │
│        └───────┬───────┘                    │
│                │                            │
└────────────────┼────────────────────────────┘
                 │ VPN (10.0.0.0/24)
                 │
        ┌────────▼─────────┐
        │   Internet       │
        └────────┬─────────┘
                 │
┌────────────────▼────────────────────────────┐
│           SOC Central Server                │
│                                             │
│  ┌────────────┐  ┌────────────┐            │
│  │   Wazuh    │  │  Zabbix    │            │
│  │  Manager   │  │  Server    │            │
│  └────────────┘  └────────────┘            │
│                                             │
│         ┌────────────┐                      │
│         │ WireGuard  │                      │
│         │  Server    │                      │
│         └────────────┘                      │
└─────────────────────────────────────────────┘
```

## Flux de Dades

1. **WireGuard**: Estableix túnel VPN segur amb el servidor central
2. **Wazuh Agent**: Envia logs i events de seguretat al Wazuh Manager (port 1514)
3. **Zabbix Agent**: Envia mètriques al Zabbix Server (port 10051)

## Scripts Auxiliars

### Restart Complet
```bash
./scripts/restart.sh
```

### Veure Logs
```bash
./scripts/logs.sh [wireguard|wazuh|zabbix]
```

### Health Check
```bash
./scripts/health-check.sh
```

## Troubleshooting

### WireGuard no connecta

1. Verificar configuració:
   ```bash
   cat config/wireguard/wg0.conf
   ```

2. Verificar logs:
   ```bash
   docker logs soc-client-wireguard
   ```

3. Verificar que el port UDP 51821 està obert al firewall del servidor

### Wazuh Agent no envia dades

1. Verificar connectivitat al manager:
   ```bash
   docker exec soc-client-wireguard ping -c 3 10.0.0.1
   docker exec soc-client-wireguard nc -zv 10.0.0.1 1514
   ```

2. Verificar clau de registre:
   ```bash
   docker logs soc-client-wazuh-agent | grep -i "connected\|error"
   ```

3. Al servidor central, verificar que l'agent està registrat:
   ```bash
   docker exec soc-central-wazuh.manager-1 /var/ossec/bin/agent_control -l
   ```

### Zabbix Agent no apareix al servidor

1. Verificar connectivitat:
   ```bash
   docker exec soc-client-wireguard ping -c 3 10.0.0.1
   docker exec soc-client-wireguard nc -zv 10.0.0.1 10051
   ```

2. Verificar hostname configurat:
   ```bash
   docker exec soc-client-zabbix-agent cat /etc/zabbix/zabbix_agentd.conf | grep Hostname
   ```

3. Al servidor Zabbix, afegir l'host manualment si cal

## Manteniment

### Actualitzar Contenidors

```bash
docker compose pull
docker compose up -d
```

### Backup Configuració

```bash
tar -czf soc-client-backup-$(date +%Y%m%d).tar.gz config/ .env
```

### Eliminar Tot

```bash
docker compose down -v
```

## Seguretat

- Les claus privades WireGuard s'han de mantenir segures (permisos 600)
- No compartir el fitxer .env (conté configuració sensible)
- Assegurar que només el tràfic VPN pot accedir als serveis

## Suport

Per problemes o consultes, contactar amb l'equip SOC Central.

## Llicència

Propietari - ARACOM CLOUD SERVICES SLU
