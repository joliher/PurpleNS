#!/bin/sh
nginx
until ping -c1 -W1 ${MANAGER:-10.80.0.10} >/dev/null 2>&1; do sleep 2; done
/var/ossec/bin/wazuh-control start
exec tail -f /dev/null
