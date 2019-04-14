#!/bin/sh
set -e

# Update Shinobi to latest version on container start?
if [ "$APP_UPDATE" = "auto" ]; then
    echo "Checking for Shinobi updates ..."
    git reset --hard
    git pull
    npm install
fi

# Copy existing custom configuration files
echo "Copy custom configuration files ..."
if [ -d /config ]; then
    cp -R -f "/config/"* /opt/shinobi || echo "No custom config files found." 
fi

# Create default configurations files from samples if not existing
if [ ! -f /opt/shinobi/conf.json ]; then
    echo "Create default config file /opt/shinobi/conf.json ..."
    cp /opt/shinobi/conf.sample.json /opt/shinobi/conf.json
fi

if [ ! -f /opt/shinobi/super.json ]; then
    echo "Create default config file /opt/shinobi/super.json ..."
    cp /opt/shinobi/super.sample.json /opt/shinobi/super.json
fi

if [ ! -f /opt/shinobi/plugins/motion/conf.json ]; then
    echo "Create default config file /opt/shinobi/plugins/motion/conf.json ..."
    cp /opt/shinobi/plugins/motion/conf.sample.json /opt/shinobi/plugins/motion/conf.json
fi

# Hash the admins password
if [ -n "${ADMIN_PASSWORD}" ]; then
    echo "Hash admin password ..."
    ADMIN_PASSWORD_MD5=$(echo -n "${ADMIN_PASSWORD}" | md5sum | sed -e 's/  -$//')
fi

echo "MariaDB Directory ..."
DB_DATA_PATH="/var/lib/mysql"
DB_ROOT_PASS="${MYSQL_ROOT_PASSWORD}"
DB_USER="${MYSQL_USER}"
DB_PASS="${MYSQL_PASSWORD}"
MAX_ALLOWED_PACKET="200M"

if [ ! -f /var/lib/mysql/ibdata1 ]; then
    echo "Installing MariaDB ..."
    mysql_install_db --user=mysql --datadir=${DB_DATA_PATH} --silent
fi

echo "Starting MariaDB ..."
/usr/bin/mysqld_safe --user=mysql &
sleep 10s

chown -R mysql /var/lib/mysql

if [ ! -f /var/lib/mysql/ibdata1 ]; then
    mysql -u root --password="" <<-EOSQL
SET @@SESSION.SQL_LOG_BIN=0;
USE mysql;
DELETE FROM mysql.user ;
DROP USER IF EXISTS 'root'@'%','root'@'localhost','${DB_USER}'@'localhost','${DB_USER}'@'%';
CREATE USER 'root'@'%' IDENTIFIED BY '${DB_PASS}' ;
CREATE USER 'root'@'localhost' IDENTIFIED BY '${DB_PASS}' ;
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}' ;
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}' ;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION ;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION ;
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'%' WITH GRANT OPTION ;
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'localhost' WITH GRANT OPTION ;
DROP DATABASE IF EXISTS test ;
FLUSH PRIVILEGES ;
EOSQL
fi

# Waiting for connection to MariaDB server
if [ -n "${MYSQL_HOST}" ]; then
    echo -n "Waiting for connection to MariaDB server on $MYSQL_HOST ."
    while ! mysqladmin ping -h"$MYSQL_HOST"; do
        sleep 1
        echo -n "."
    done
    echo " established."
fi

# Create MariaDB database if it does not exists
echo "Create database schema if it does not exists ..."
mysql -e "source /opt/shinobi/sql/framework.sql" || true

echo "Create database user if it does not exists ..."
mysql -e "source /opt/shinobi/sql/user.sql" || true


echo "Set keys for CRON and PLUGINS from environment variables ..."
sed -i -e 's/"key":"73ffd716-16ab-40f4-8c2e-aecbd3bc1d30"/"key":"'"${CRON_KEY}"'"/g' \
       -e 's/"Motion":"d4b5feb4-8f9c-4b91-bfec-277c641fc5e3"/"Motion":"'"${PLUGINKEY_MOTION}"'"/g' \
       -e 's/"OpenCV":"644bb8aa-8066-44b6-955a-073e6a745c74"/"OpenCV":"'"${PLUGINKEY_OPENCV}"'"/g' \
       -e 's/"OpenALPR":"9973e390-f6cd-44a4-86d7-954df863cea0"/"OpenALPR":"'"${PLUGINKEY_OPENALPR}"'"/g' \
       "/opt/shinobi/conf.json"

# Set the admin password
if [ -n "${ADMIN_USER}" ]; then
    if [ -n "${ADMIN_PASSWORD_MD5}" ]; then
        sed -i -e 's/"mail":"admin@shinobi.video"/"mail":"'"${ADMIN_USER}"'"/g' \
            -e "s/21232f297a57a5a743894a0e4a801fc3/${ADMIN_PASSWORD_MD5}/g" \
            "/opt/shinobi/super.json"
    fi
fi

# Change the uid/gid of the node user
if [ -n "${GID}" ]; then
    if [ -n "${UID}" ]; then
        echo " - Set the uid:gid of the node user to ${UID}:${GID}"
        groupmod -g ${GID} node && usermod -u ${UID} -g ${GID} node
    fi
fi

# Modify Shinobi configuration
echo "- Chimp Shinobi's technical configuration ..."
cd /opt/shinobi
echo "  - Set cpuUsageMarker ..."
node tools/modifyConfiguration.js cpuUsageMarker=CPU

# Execute Command
echo "Starting Shinobi ..."
exec "$@"
