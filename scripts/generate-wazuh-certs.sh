#!/bin/bash
# Script per generar certificats Wazuh per al SOC Client

echo "=== Generant certificats Wazuh per al SOC Client ==="

# Crear directoris
mkdir -p config/wazuh-indexer/certs
mkdir -p config/wazuh-manager/certs  
mkdir -p config/wazuh-dashboard/certs
mkdir -p config/wazuh-dashboard/config

# Generar certificats amb contenidor oficial
docker run --rm -v $(pwd)/config:/config wazuh/wazuh-certs-generator:0.0.1 \
  -A

# Copiar certificats als directoris correctes
if [ -d "config/wazuh-certificates" ]; then
  cp config/wazuh-certificates/wazuh-indexer.pem config/wazuh-indexer/certs/
  cp config/wazuh-certificates/wazuh-indexer-key.pem config/wazuh-indexer/certs/
  cp config/wazuh-certificates/root-ca.pem config/wazuh-indexer/certs/
  
  cp config/wazuh-certificates/wazuh-manager.pem config/wazuh-manager/certs/filebeat.pem
  cp config/wazuh-certificates/wazuh-manager-key.pem config/wazuh-manager/certs/filebeat.key
  cp config/wazuh-certificates/root-ca.pem config/wazuh-manager/certs/
  
  cp config/wazuh-certificates/wazuh-dashboard.pem config/wazuh-dashboard/certs/
  cp config/wazuh-certificates/wazuh-dashboard-key.pem config/wazuh-dashboard/certs/
  cp config/wazuh-certificates/root-ca.pem config/wazuh-dashboard/certs/
  
  echo "✅ Certificats generats correctament"
else
  echo "❌ Error generant certificats"
  exit 1
fi

# Crear fitxers de configuració dashboard
cat > config/wazuh-dashboard/config/opensearch_dashboards.yml << 'YAML'
server.host: "0.0.0.0"
server.port: 5601
opensearch.hosts: ["https://wazuh-indexer:9200"]
opensearch.ssl.verificationMode: none
YAML

cat > config/wazuh-dashboard/config/wazuh.yml << 'YAML'
hosts:
  - default:
      url: https://wazuh-manager
      port: 55000
      username: wazuh-wui
      password: MyS3cr37P450r.*-
YAML

echo "✅ Configuració dashboard creada"
echo "=== Certificats llests per desplegar ==="
