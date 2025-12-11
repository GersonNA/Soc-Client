# SOC Client Hub

**Agregador local (hub) per sucursals** que rep dades d'agents locals i les reenvia al SOC Central.

## Arquitectura Hub-and-Spoke

Aquest sistema funciona com a **punt d'agregació local** per una sucursal:

```
Sucursal (192.168.240.0/24)
├── PCs amb agents
│   ├── Wazuh Agent → envia a 192.168.240.12:1514
│   └── Zabbix Agent → envia a 192.168.240.12:10051
│
└── SOC Client Hub (192.168.240.12)
    ├── Wazuh Manager Local (rep agents locals)
    ├── Zabbix Proxy (rep agents locals)
    └── WireGuard VPN
        └── Reenvia al SOC Central (10.0.0.1)
```

**Components:**
- **WireGuard Client**: Connexió VPN segura al SOC Central
- **Zabbix Proxy**: Agregador local d'agents Zabbix (reenvia al Server central)
- **Wazuh Manager**: Manager local d'agents Wazuh (indexa localment)
- **Wazuh Indexer**: OpenSearch local per logs
- **Wazuh Dashboard**: Interface web local (opcional)

## Requisits Previs

- **Sistema operatiu**: Ubuntu/Debian 20.04+ o similar
- **Recursos mínims**:
  - RAM: 8 GB (recomanat 16 GB)
  - CPU: 4 cores
  - Disc: 50 GB lliures
- **Docker**: v20.10+
- **Docker Compose**: v2.0+
- **Configuració WireGuard** del servidor central (fitxer .conf)
- **Port 51820/udp** obert per WireGuard

## Instal·lació

### 1. Clonar Repositori

```bash
cd /opt
sudo git clone https://github.com/GersonNA/Soc-Client.git soc-client
sudo chown -R $USER:$USER soc-client
cd soc-client
```

### 2. Configurar Variables d'Entorn

```bash
cp .env.example .env
nano .env
```

Edita les variables:
- `ZABBIX_PROXY_HOSTNAME`: Nom identificatiu del proxy (ex: soc-client-proxy-01)
- `ZABBIX_SERVER`: IP del Zabbix Server central (normalment 10.0.0.1)
- `WAZUH_*_PASSWORD`: Passwords per Wazuh (canvia-les per seguretat!)

### 3. Configurar WireGuard

Copia la configuració WireGuard del servidor central:

```bash
mkdir -p config/wireguard
# Copiar fitxer .conf proporcionat pel central
cp /path/to/wireguard-client.conf config/wireguard/wg0.conf
chmod 600 config/wireguard/wg0.conf
```

### 4. Generar Certificats Wazuh

Executa el script per generar certificats SSL:

```bash
./scripts/generate-wazuh-certs.sh
```

Això crearà els certificats necessaris per:
- Wazuh Indexer
- Wazuh Manager
- Wazuh Dashboard

### 5. Iniciar Serveis

```bash
docker compose up -d
```

Això iniciarà:
- WireGuard Client (VPN)
- Zabbix Proxy
- Wazuh Indexer
- Wazuh Manager
- Wazuh Dashboard

### 6. Verificar Estat

```bash
# Verificar contenidors
docker compose ps

# Verificar VPN
docker exec soc-client-wireguard wg show

# Ping al central
docker exec soc-client-wireguard ping -c 3 10.0.0.1

# Logs Zabbix Proxy
docker logs soc-client-zabbix-proxy --tail 50

# Logs Wazuh Manager
docker logs soc-client-wazuh-manager --tail 50
```

## Configuració d'Agents Locals

### Agents Zabbix

Els agents Zabbix dels PCs de la sucursal han de configurar-se per enviar al proxy local:

```bash
# /etc/zabbix/zabbix_agent2.conf
Server=192.168.240.12
ServerActive=192.168.240.12:10051
Hostname=pc-sucursal-01
```

El Zabbix Proxy automàticament reenvia les dades al Server central (10.0.0.1) via VPN.

### Agents Wazuh

Els agents Wazuh dels PCs han de configurar-se per enviar al Manager local:

```xml
<!-- /var/ossec/etc/ossec.conf -->
<client>
  <server>
    <address>192.168.240.12</address>
    <port>1514</port>
    <protocol>tcp</protocol>
  </server>
</client>
```

El Wazuh Manager local indexa els logs localment. Per reenvi al central, caldrà configurar **Wazuh Agent** addicional al sistema host o utilitzar **Filebeat** per reenvi.

## Accés als Serveis

### Dashboard Local

Pots accedir al Wazuh Dashboard local des de qualsevol PC de la sucursal:

```
https://192.168.240.12
```

Credencials per defecte:
- **Username**: admin
- **Password**: admin (canvia-la després del primer login!)

### Des de fora la sucursal

Si vols accedir des del SOC Central:

1. Connecta't a la VPN WireGuard
2. Accedeix a `https://10.0.0.10` (IP VPN del client)

## Ports Exposats

Ports accessibles des de la xarxa local 192.168.240.0/24:

| Port | Servei | Descripció |
|------|--------|------------|
| 1514 | Wazuh Manager | Recepció agents Wazuh (TCP) |
| 1515 | Wazuh Manager | Enrollment agents (TCP) |
| 10051 | Zabbix Proxy | Recepció agents Zabbix |
| 55000 | Wazuh API | API REST |
| 443 | Wazuh Dashboard | Interface web HTTPS |

## Manteniment

### Actualitzar Imatges

```bash
docker compose pull
docker compose up -d
```

### Backup

Backup de dades importants:

```bash
# Backup Zabbix Proxy
docker run --rm -v soc-client_zabbix-proxy-data:/data -v $(pwd):/backup alpine tar czf /backup/zabbix-proxy-backup.tar.gz /data

# Backup Wazuh
docker run --rm -v soc-client_wazuh-manager-data:/data -v $(pwd):/backup alpine tar czf /backup/wazuh-backup.tar.gz /data
```

### Logs

```bash
# Veure logs de tots els serveis
docker compose logs -f

# Logs d'un servei específic
docker compose logs -f wazuh-manager
docker compose logs -f zabbix-proxy
```

## Troubleshooting

### VPN no connecta

```bash
# Verificar configuració
docker exec soc-client-wireguard cat /config/wg_confs/wg0.conf

# Reiniciar WireGuard
docker restart soc-client-wireguard

# Verificar peer
docker exec soc-client-wireguard wg show
```

### Zabbix Proxy no reenvia dades

```bash
# Verificar connexió al Server central
docker exec soc-client-zabbix-proxy nc -zv 10.0.0.1 10051

# Logs detallats
docker logs soc-client-zabbix-proxy --tail 100
```

### Wazuh Manager no rep agents

```bash
# Verificar que el port està obert
netstat -tulpn | grep 1514

# Verificar agents registrats
docker exec soc-client-wazuh-manager /var/ossec/bin/agent_control -l

# Logs Manager
docker logs soc-client-wazuh-manager --tail 100
```

### Wazuh Dashboard no carrega

```bash
# Verificar que Indexer està Up
docker ps | grep wazuh-indexer

# Logs Dashboard
docker logs soc-client-wazuh-dashboard --tail 50

# Logs Indexer
docker logs soc-client-wazuh-indexer --tail 50
```

## Eliminar Instal·lació

```bash
# Aturar i eliminar contenidors
docker compose down

# Eliminar volums (ATENCIÓ: això esborra totes les dades!)
docker compose down -v

# Eliminar directori
cd /opt
sudo rm -rf soc-client
```

## Arquitectura Detallada

```
┌─────────────────────────────────────────────────────────────┐
│ Sucursal 192.168.240.0/24                                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  PCs amb Agents                                              │
│  ├─ Wazuh Agent ────────┐                                   │
│  └─ Zabbix Agent ───────┼────────┐                          │
│                         │        │                          │
│                         ▼        ▼                          │
│  ┌──────────────────────────────────────────┐               │
│  │ SOC Client Hub (192.168.240.12)         │               │
│  ├──────────────────────────────────────────┤               │
│  │                                          │               │
│  │  ┌─────────────┐    ┌──────────────┐    │               │
│  │  │ Wazuh       │    │ Zabbix Proxy │    │               │
│  │  │ Manager     │    │              │    │               │
│  │  │ :1514       │    │ :10051       │    │               │
│  │  └──────┬──────┘    └──────┬───────┘    │               │
│  │         │                  │            │               │
│  │         ▼                  │            │               │
│  │  ┌─────────────┐           │            │               │
│  │  │ Wazuh       │           │            │               │
│  │  │ Indexer     │           │            │               │
│  │  │ (OpenSearch)│           │            │               │
│  │  └─────────────┘           │            │               │
│  │                            │            │               │
│  │  ┌──────────────────────────┴───┐       │               │
│  │  │ WireGuard Client             │       │               │
│  │  │ IP VPN: 10.0.0.10            │       │               │
│  │  └──────────────┬───────────────┘       │               │
│  └─────────────────┼─────────────────────────┘               │
│                    │ Túnel VPN                              │
└────────────────────┼────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ SOC Central (soc.aracom.cat)                                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌─────────────┐                       │
│  │ Wazuh        │    │ Zabbix      │                       │
│  │ Manager      │    │ Server      │                       │
│  │ :1514        │    │ :10051      │                       │
│  └──────────────┘    └─────────────┘                       │
│                                                              │
│  Dashboards Centralitzats                                   │
│  └─ Visualització de totes les sucursals                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Suport

Per problemes o preguntes:
- GitHub Issues: https://github.com/GersonNA/Soc-Client/issues
- Documentació Wazuh: https://documentation.wazuh.com/
- Documentació Zabbix: https://www.zabbix.com/documentation

---

**Nota**: Aquest és un sistema Hub local. Cada sucursal té el seu propi hub que agrega dades i les reenvia al central. Això permet monitorització local i resiliència si la connexió al central falla temporalment.
