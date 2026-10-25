FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends openvswitch-switch iproute2 iputils-ping tcpdump && rm -rf /var/lib/apt/lists/*
CMD ["sh","-c","/usr/share/openvswitch/scripts/ovs-ctl start && exec tail -f /var/log/openvswitch/ovs-vswitchd.log"]

