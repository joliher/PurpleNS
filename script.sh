LAN_NET=10.80.0
ATK_NET=10.81.0

pid() { docker inspect -f '{{.State.Pid}}' "$1"; }

sudo modprobe openvswitch
docker rm -f sw h1 h2 rt kali suri 2>/dev/null

docker run -d --name sw   --network none --cap-add NET_ADMIN ovs-sw
docker run -d --name h1   --network none --cap-add NET_ADMIN lab-victim
docker run -d --name h2   --network none --cap-add NET_ADMIN lab-victim
docker run -d --name rt   --network none --cap-add NET_ADMIN --sysctl net.ipv4.ip_forward=1 lab-router sleep infinity
docker run -d --name kali --network none --cap-add NET_ADMIN lab-kali sleep infinity

# Cables
sudo ip link add p-h1 netns $(pid sw) type veth peer name eth0    netns $(pid h1)
sudo ip link add p-h2 netns $(pid sw) type veth peer name eth0    netns $(pid h2)
sudo ip link add p-rt netns $(pid sw) type veth peer name eth-lan netns $(pid rt)
sudo ip link add eth-atk netns $(pid rt) type veth peer name eth0 netns $(pid kali)

# Switch
until docker exec sw ovs-vsctl show >/dev/null 2>&1; do sleep 1; done
docker exec sw ovs-vsctl add-br br-lan
for p in p-h1 p-h2 p-rt; do
  docker exec sw ovs-vsctl add-port br-lan $p
  docker exec sw ip link set $p up
done
docker exec sw ip link set br-lan up

# Víctimas
for h in h1 h2; do docker exec $h ip link set eth0 up; done
docker exec h1 ip addr add $LAN_NET.1/24 dev eth0
docker exec h2 ip addr add $LAN_NET.2/24 dev eth0
for h in h1 h2; do docker exec $h ip route add default via $LAN_NET.254; done

# Router
docker exec rt ip link set eth-lan up
docker exec rt ip link set eth-atk up
docker exec rt ip addr add $LAN_NET.254/24 dev eth-lan
docker exec rt ip addr add $ATK_NET.254/24 dev eth-atk

# Kali
docker exec kali ip link set eth0 up
docker exec kali ip addr add $ATK_NET.1/24 dev eth0
docker exec kali ip route add default via $ATK_NET.254

# Pruebas
docker exec kali ping -c 2 $LAN_NET.1

#
#docker volume create suri-rules
#docker run --rm --network host -v suri-rules:/var/lib/suricata --entrypoint suricata-update jasonish/suricata:latest

docker volume create suri-logs
docker run -d --name suri --network none --cap-add NET_ADMIN --cap-add NET_RAW --cap-add SYS_NICE -v suri-logs:/var/log/suricata -v suri-rules:/var/lib/suricata jasonish/suricata:latest -i eth0 --set 'vars.address-groups.HOME_NET=[10.80.0.0/24]'

sudo ip link add p-suri netns $(pid sw) type veth peer name eth0 netns $(pid suri)
docker exec sw ovs-vsctl add-port br-lan p-suri
docker exec sw ip link set p-suri up
docker exec suri ip link set eth0 up
docker exec sw ovs-vsctl -- --id=@p get port p-suri -- --id=@m create mirror name=m0 select-all=true output-port=@p -- set bridge br-lan mirrors=@m



