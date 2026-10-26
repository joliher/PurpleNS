#!/bin/bash
# destroy.sh: borra todo lo del laboratorio para probarlo desde cero.
#   ./destroy.sh            -> contenedores, volúmenes, red y clon de Wazuh, imágenes construidas
#   ./destroy.sh --pulled   -> además, imágenes descargadas (Kali, Wazuh, Suricata)
#   ./destroy.sh --yes      -> sin pedir confirmación
set -u
PROJ="$(cd "$(dirname "$0")" && pwd)"
WZ_CLONE="$PROJ/wazuh/wazuh-docker"
WZ_PROJECT="single-node"
CONTAINERS="sw h1 h2 rt kali suri"
VOLUMES="suri-logs suri-rules"
BUILT_IMAGES="ovs-sw lab-router lab-kali lab-victim"
PULLED=0; YES=0

for a in "$@"; do
  case "$a" in
    --pulled) PULLED=1 ;;
    --yes)    YES=1 ;;
    *) echo "Opción desconocida: $a"; exit 1 ;;
  esac
done

# Protección: no borrar el clon si tus ediciones solo existen dentro de él
if [ -d "$WZ_CLONE" ] && { [ ! -f "$PROJ/wazuh/lab/docker-compose.lab.yml" ] || [ ! -f "$PROJ/wazuh/lab/wazuh_manager.conf" ]; }; then
  echo "ERROR: faltan docker-compose.lab.yml o wazuh_manager.conf en $PROJ/wazuh/lab/."
  echo "Cópialos antes de borrar o perderías tus ediciones."
  exit 1
fi

echo "Se va a borrar:"
echo "  - contenedores: $CONTAINERS y todos los del compose '$WZ_PROJECT' (Wazuh)"
echo "  - volúmenes: $VOLUMES y los de Wazuh (incluye alertas e índices)"
echo "  - red: ${WZ_PROJECT}_default"
echo "  - imágenes construidas: $BUILT_IMAGES"
[ $PULLED -eq 1 ] && echo "  - imágenes descargadas: wazuh/*, jasonish/suricata, kalilinux/*"
echo "  - carpeta $WZ_CLONE (con certificados) y /etc/sysctl.d/99-wazuh.conf"
echo "No se toca nada más."
if [ $YES -ne 1 ]; then
  read -rp "Escribe 'borrar' para continuar: " ok
  [ "$ok" = "borrar" ] || { echo "Cancelado."; exit 1; }
fi

echo "== Contenedores =="
docker rm -f $CONTAINERS 2>/dev/null
docker ps -aq --filter "label=com.docker.compose.project=$WZ_PROJECT" | xargs -r docker rm -f

echo "== Volúmenes =="
docker volume ls -q --filter "label=com.docker.compose.project=$WZ_PROJECT" | xargs -r docker volume rm
docker volume rm $VOLUMES 2>/dev/null

echo "== Red de Wazuh =="
docker network rm "${WZ_PROJECT}_default" 2>/dev/null

echo "== Imágenes =="
docker rmi $BUILT_IMAGES 2>/dev/null
if [ $PULLED -eq 1 ]; then
  docker images --format '{{.Repository}}:{{.Tag}}' \
    | grep -E '^(wazuh/|jasonish/suricata|kalilinux/)' | xargs -r docker rmi
fi

echo "== Ficheros =="
[ -d "$WZ_CLONE" ] && sudo rm -rf -- "$WZ_CLONE"
sudo rm -f /etc/sysctl.d/99-wazuh.conf

echo "== Estado final =="
docker ps -a --format 'table {{.Names}}\t{{.Image}}'
docker volume ls
