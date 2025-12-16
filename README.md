# SOC Client

Aquest repositori conté la configuració per desplegar un "SOC Client" utilitzant Docker.

El `soc-client` està dissenyat per ser desplegat en una xarxa remota (per exemple, una sucursal o una VPC) per recollir logs i mètriques de seguretat i enviar-les de manera segura a un servidor central "SOC Central".

## Arquitectura

El `soc-client` utilitza `docker-compose` per orquestrar els següents serveis:

- **WireGuard**: Estableix un túnel VPN segur cap al servidor `soc.aracom.cat` (10.0.0.x). Tot el tràfic de monitorització s'envia a través d'aquest túnel.
- **Wazuh Manager (WORKER)**: Actua com un node WORKER del cluster Wazuh. Rep alertes dels agents Wazuh desplegats a la xarxa local i les sincronitza automàticament amb el manager MASTER del SOC Central mitjançant el cluster.
- **Zabbix Proxy**: Actua com un proxy local de Zabbix. Recopila mètriques dels agents Zabbix locals i les envia al servidor principal de Zabbix al SOC Central.

### Cluster Wazuh

El SOC Client està configurat com a **WORKER** en un cluster Wazuh:
- **MASTER**: SOC Central (soc.aracom.cat - 10.0.0.1)
- **WORKER**: SOC Client (10.0.0.11)

Tots els agents que es connecten al SOC Client apareixen automàticament al SOC Central gràcies a la sincronització del cluster.

## Requisits Previs

1. **Docker i Docker Compose** instal·lats
2. **Configuració de WireGuard** proporcionada pel SOC Central
3. **Clau de cluster** (ha de coincidir amb el SOC Central)

## Desplegament

### 1. Clonar el repositori

```bash
git clone git@github.com:GersonNA/Soc-Client.git /opt/soc-client
cd /opt/soc-client
```

### 2. Configuració de WireGuard

Afegeix el fitxer de configuració de WireGuard proporcionat pel SOC Central:

```bash
nano config/wireguard/wg0.conf
```

### 3. Verificar Configuració de Docker

**IMPORTANT**: Si Docker no arrenca, verifica que `/etc/docker/daemon.json` té un format JSON vàlid:

```json
{
  "userland-proxy": false
}
```

### 4. Llançar els serveis

```bash
docker-compose up -d
```

### 5. Verificar el desplegament

```bash
# Verificar cluster Wazuh
docker exec soc-client-wazuh-manager /var/ossec/bin/cluster_control -l
```

## Connexió d'Agents

### Agents Wazuh
Han d'apuntar a la IP de la màquina host que executa aquest `soc-client`:
- **Port 1514**: Connexió segura TCP
- **Port 1515**: Registre d'agents (authd)

### Agents Zabbix
Han d'apuntar a la IP de la màquina host:
- **Port 10050**: Port del proxy Zabbix

## Troubleshooting

### Docker no arrenca

**Solució**:
```bash
echo '{
  "userland-proxy": false
}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
```

### Wazuh Manager no arrenca

```bash
docker-compose down
docker volume rm soc-client_wazuh_etc soc-client_wazuh_logs soc-client_wazuh_queue
docker-compose up -d
```

### Cluster no connecta

```bash
# Test connectivitat
docker exec soc-client-wireguard ping -c 3 10.0.0.1
docker exec soc-client-wireguard nc -zv 10.0.0.1 1516
```

## Logs

```bash
docker-compose logs -f
docker exec soc-client-wazuh-manager /var/ossec/bin/cluster_control -l
```
