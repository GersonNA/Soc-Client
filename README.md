# SOC Client

Aquest repositori contÃ© la configuraciÃ³ per desplegar un "SOC Client" utilitzant Docker.

El `soc-client` estÃ  dissenyat per ser desplegat en una xarxa remota (per exemple, una sucursal o una VPC) per recollir logs i mÃ¨triques de seguretat i enviar-les de manera segura a un servidor central "SOC Central".

## Arquitectura

El `soc-client` utilitza `docker-compose` per orquestrar els segÃ¼ents serveis:

- **WireGuard**: Estableix un tÃºnel VPN segur cap al servidor `soc.aracom.cat`. Tot el trÃ fic de monitoritzaciÃ³ s'envia a travÃ©s d'aquest tÃºnel.
- **Wazuh Manager**: Actua com un manager local de Wazuh. Rep alertes dels agents Wazuh desplegats a la xarxa local i les reenvia al manager principal del SOC Central.
- **Zabbix Proxy**: Actua com un proxy local de Zabbix. Recopila mÃ¨triques dels agents Zabbix locals i les envia al servidor principal de Zabbix al SOC Central.

## Desplegament

1. **Clonar el repositori:**
   ```bash
   git clone git@github.com:GersonNA/Soc-Client.git /opt/soc-client
   cd /opt/soc-client
   ```

2. **ConfiguraciÃ³:**
   - Assegura't que el fitxer `config/wireguard/wg0.conf` contÃ© la configuraciÃ³ de client de WireGuard correcta proporcionada pel servidor SOC Central.

3. **LlanÃ§ar els serveis:**
   ```bash
   docker-compose up -d
   ```

## ConnexiÃ³ d'Agents

- **Agents Wazuh**: Han d'apuntar a la IP de la mÃ quina host que executa aquest `soc-client` al port `1514`/`1515`.
- **Agents Zabbix**: Han d'apuntar a la IP de la mÃ quina host que executa aquest `soc-client` al port `10050`.
