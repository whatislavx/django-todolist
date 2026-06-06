#!/bin/bash
set -ex

PRIMARY="${CHART_NAME}-statefulset-0.${CHART_NAME}-headless.${MY_NAMESPACE}.svc.cluster.local"
REPLICA="${CHART_NAME}-statefulset-1.${CHART_NAME}-headless.${MY_NAMESPACE}.svc.cluster.local"

until mysql -h"$PRIMARY" -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" 2>/dev/null; do
  echo "Waiting for primary to be ready..."
  sleep 3
done

echo "Configuring Primary database users..."
mysql -h"$PRIMARY" -uroot -p"${MYSQL_ROOT_PASSWORD}" <<EOF
SET SQL_LOG_BIN=0;

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

CREATE USER IF NOT EXISTS 'repl_user'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
ALTER USER 'repl_user'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT REPLICATION SLAVE, REPLICATION CLIENT, SELECT ON *.* TO 'repl_user'@'%';

FLUSH PRIVILEGES;

SET SQL_LOG_BIN=1;
EOF

until mysql -h"$PRIMARY" -u"repl_user" -p"${MYSQL_PASSWORD}" -e "SELECT 1" 2>/dev/null; do
  echo "Waiting for replication user on primary..."
  sleep 3
done

until mysql -h"$REPLICA" -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" 2>/dev/null; do
  echo "Waiting for replica to be ready..."
  sleep 3
done

echo "Configuring replication on replica..."
mysql -h"$REPLICA" -uroot -p"${MYSQL_ROOT_PASSWORD}" <<EOF
STOP REPLICA;
RESET REPLICA ALL;
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='${PRIMARY}',
  SOURCE_USER='repl_user',
  SOURCE_PASSWORD='${MYSQL_PASSWORD}',
  SOURCE_AUTO_POSITION=1;
START REPLICA;
EOF

sleep 2
mysql -h"$REPLICA" -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW REPLICA STATUS\G"