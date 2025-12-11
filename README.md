# SOC Client Hub - Arquitectura Hub-and-Spoke

Infraestructura de Security Operations Center (SOC) Client amb arquitectura Hub-and-Spoke per rebre dades locals i forwardear al SOC Central via VPN.

## Arquitectura

El SOC Client Hub actua com a concentrador local que:
- Rep events de seguretat de Wazuh Agents locals
- Rep mètriques de Zabbix Agents locals
- Connecta via WireGuard VPN al SOC Central (soc.aracom.cat)
- Forwarding de dades al central

## Serveis

| Servei | Port | Funció |
|--------|------|--------|
| Wazuh Manager | 1514, 1515, 55000 | SIEM Hub - Rep agents locals |
| Wazuh Indexer | 9200 (intern) | Base de dades logs local |
| Wazuh Dashboard | 8443 | Interfície web local |
| Zabbix Proxy | 10051 | Monitoring Hub - Rep agents locals |
| WireGuard Client | 51820/udp | VPN al SOC Central |

## Desplegament

### 1. Generar Certificats
```bash
docker compose -f generate-indexer-certs.yml run --rm generator
```

### 2. Configurar WireGuard
Copiar `wg0.conf` del SOC Central a `config/wireguard/wg_confs/wg0.conf`

### 3. Iniciar Serveis
```bash
docker compose up -d
```

### 4. Verificar
```bash
docker ps
docker exec soc-client-wireguard wg show
docker logs soc-client-wazuh.manager-1
```

## Configuració Agents Locals

### Wazuh Agent
```bash
# Configurar MANAGER_IP=192.168.240.12
sudo systemctl start wazuh-agent
```

### Zabbix Agent
```bash
# Configurar Server=192.168.240.12
sudo systemctl start zabbix-agent2
```

## Accés

- **Dashboard**: https://192.168.240.12:8443
- **Wazuh Manager API**: https://192.168.240.12:55000
- **VPN**: 10.0.0.10 → 10.0.0.1 (Central)

## Referències

- [SOC Central](https://github.com/gersonfreire/soc-central)
- [Documentació Wazuh](https://documentation.wazuh.com/)
- [Documentació Zabbix](https://www.zabbix.com/documentation/)
