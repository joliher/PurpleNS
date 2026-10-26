#!/bin/bash
# Preparación de Wazuh (una sola vez; repetible sin efectos secundarios)
set -e
BASE="$HOME/proyecto/wazuh"
SN="$BASE/wazuh-docker/single-node"
WAZUH_TAG=v4.14.9
CERTS="$SN/config/wazuh_indexer_ssl_certs"

# 1. Clonar la versión fijada
[ -d "$BASE/wazuh-docker" ] || git clone https://github.com/wazuh/wazuh-docker.git -b "$WAZUH_TAG" "$BASE/wazuh-docker"

# 2. Certificados (con red del host: la red por defecto de Docker no tiene NAT)
if ! sudo test -f "$CERTS/root-ca.pem"; then
  docker run --rm --network host -e CERT_TOOL_VERSION=4.14 \
    -v "$CERTS/":/certificates/ \
    -v "$SN/config/certs.yml":/config/certs.yml \
    wazuh/wazuh-certs-generator:0.0.4
fi

# 3. Ficheros editados del laboratorio
cp "$BASE/lab/docker-compose.lab.yml" "$SN/docker-compose.lab.yml"
cp "$BASE/lab/wazuh_manager.conf" "$SN/config/wazuh_cluster/wazuh_manager.conf"

# 4. Parámetro de kernel que exige el indexer
echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.d/99-wazuh.conf >/dev/null
sudo sysctl --system >/dev/null
