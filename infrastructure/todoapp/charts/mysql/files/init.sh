#!/bin/bash

set -ex

ordinal="${HOSTNAME##*-}"
case "$ordinal" in
  ''|*[!0-9]*) echo "Invalid ordinal: $ordinal"; exit 1 ;;
esac

echo "[mysqld]" > /mnt/conf.d/server-id.cnf
echo "server-id=$((ordinal + 1))" >> /mnt/conf.d/server-id.cnf

if [ "$ordinal" -eq 0 ]; then
  cp /mnt/config-map/primary.cnf /mnt/conf.d/
else
  cp /mnt/config-map/replica.cnf /mnt/conf.d/
fi