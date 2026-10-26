for src in h1 h2 kali; do
  for dst in 10.80.0.1 10.80.0.2 10.80.0.10 10.80.0.254 10.81.0.1 10.81.0.254; do
    printf "%-5s -> %-12s " $src $dst
    docker exec $src ping -c1 -W1 $dst >/dev/null 2>&1 && echo OK || echo FALLA
  done
done

WZ=$(docker inspect -f '{{.State.Pid}}' $(docker compose -f ~/proyecto/wazuh/wazuh-docker/single-node/docker-compose.lab.yml ps -q wazuh.manager))
sudo nsenter -t $WZ -n ping -c1 -W1 10.80.0.1

docker exec sw ovs-appctl fdb/show br-lan
