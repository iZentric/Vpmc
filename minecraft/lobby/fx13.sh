#!/bin/bash
cd /home/container
if [ -f server.properties ]; then
  sed -i 's/^pause-when-empty-seconds=.*/pause-when-empty-seconds=60/' server.properties
  sed -i 's/^max-players=.*/max-players=300/' server.properties
fi
D=plugins/DecentHolograms/config.yml
if [ -f $D ]; then
  sed -i -e 's/^bStats: true/bStats: false/' -e 's/^update-check: true/update-check: false/' $D
fi
(
  sleep 60
  {
    echo "=== PORT AUDIT $(date -Iseconds) ==="
    echo "LOBBY_CONTAINER_IP=$(hostname -I)"
    for t in 169.58.65.236:25565 169.58.65.236:25566 169.58.65.236:25567 169.58.65.236:25568 169.58.65.236:25569 172.18.0.2:25566 172.18.0.4:25567; do
      h=${t%:*}
      p=${t#*:}
      if timeout 2 bash -c "echo > /dev/tcp/$h/$p" 2>/dev/null; then
        echo "$t=OPEN"
      else
        echo "$t=CLOSED"
      fi
    done
  } > /home/container/port-audit.txt 2>&1
) &
