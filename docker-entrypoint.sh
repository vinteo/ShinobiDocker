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

## Hash the admins password
#if [ -n "${ADMIN_PASSWORD}" ]; then
#    echo "Hash admin password ..."
#    ADMIN_PASSWORD_MD5=$(echo -n "${ADMIN_PASSWORD}" | md5sum | sed -e 's/  -$//')
#fi

# Use embedded SQLite3 database ?
if [ "${EMBEDDEDDB}" = "true" ] || [ "${EMBEDDEDDB}" = "TRUE" ]; then
    # Create SQLite3 database if it does not exists
    chmod -R 777 /opt/dbdata

    if [ ! -e "/opt/dbdata/shinobi.sqlite" ]; then
        echo "Creating shinobi.sqlite for SQLite3..."
        cp /opt/shinobi/sql/shinobi.sample.sqlite /opt/dbdata/shinobi.sqlite
    fi
else
    # Create MariaDB database if it does not exists
    if [ -n "${MYSQL_HOST}" ]; then
        echo -n "Waiting for connection to MariaDB server on $MYSQL_HOST ."
        while ! mysqladmin ping -h"$MYSQL_HOST"; do
            sleep 1
            echo -n "."
        done
        echo " established."
    fi

    # Create MariaDB database if it does not exists
    if [ -n "${MYSQL_ROOT_USER}" ]; then
        if [ -n "${MYSQL_ROOT_PASSWORD}" ]; then
            echo "Setting up MariaDB database if it does not exists ..."

            mkdir -p sql_temp
            cp -f ./sql/framework.sql ./sql_temp
            cp -f ./sql/user.sql ./sql_temp

            if [ -n "${MYSQL_DATABASE}" ]; then
                echo " - Set database name: ${MYSQL_DATABASE}"
                sed -i  -e "s/ccio/${MYSQL_DATABASE}/g" \
                    "./sql_temp/framework.sql"
                
                sed -i  -e "s/ccio/${MYSQL_DATABASE}/g" \
                    "./sql_temp/user.sql"
            fi

            if [ -n "${MYSQL_ROOT_USER}" ]; then
                if [ -n "${MYSQL_ROOT_PASSWORD}" ]; then
                    sed -i -e "s/majesticflame/${MYSQL_USER}/g" \
                        -e "s/''/'${MYSQL_PASSWORD}'/g" \
                        -e "s/127.0.0.1/%/g" \
                        "./sql_temp/user.sql"
                fi
            fi

            echo "- Create database schema if it does not exists ..."
            mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST -e "source ./sql_temp/framework.sql" || true

            echo "- Create database user if it does not exists ..."
            mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST -e "source ./sql_temp/user.sql" || true

            rm -rf sql_temp
        fi
    fi
fi

# Update Shinobi's configuration by environment variables
echo "Updating Shinobi's configuration to match your environment ..."

if [ "${EMBEDDEDDB}" = "true" ] || [ "${EMBEDDEDDB}" = "TRUE" ]; then
    # Set database to SQLite3
    echo "Set database type to SQLite3 ..."
    node /opt/shinobi/tools/modifyConfiguration.js databaseType=sqlite3 db='{"filename":"/opt/dbdata/shinobi.sqlite"}'
else
    # Set MariaDB configuration from environment variables
    echo "- Set MariaDB configuration from environment variables ..."
    if [ -n "${MYSQL_USER}" ]; then
        echo "  - MariaDB username: ${MYSQL_USER}"
        sed -i -e 's/"user": "majesticflame"/"user": "'"${MYSQL_USER}"'"/g' \
            "/opt/shinobi/conf.json"
    fi

    if [ -n "${MYSQL_PASSWORD}" ]; then
        echo "  - MariaDB password."
        sed -i -e 's/"password": ""/"password": "'"${MYSQL_PASSWORD}"'"/g' \
            "/opt/shinobi/conf.json"
    fi

    if [ -n "${MYSQL_HOST}" ]; then
        echo "  - MariaDB server host: ${MYSQL_HOST}"
        sed -i -e 's/"host": "127.0.0.1"/"host": "'"${MYSQL_HOST}"'"/g' \
            "/opt/shinobi/conf.json"
    fi

    if [ -n "${MYSQL_DATABASE}" ]; then
        echo "  - MariaDB database name: ${MYSQL_DATABASE}"
        sed -i -e 's/"database": "ccio"/"database": "'"${MYSQL_DATABASE}"'"/g' \
            "/opt/shinobi/conf.json"
    fi
fi

# Set keys for CRON and PLUGINS ...
echo "- Set keys for CRON and PLUGINS from environment variables ..."
sed -i -e 's/"key":"73ffd716-16ab-40f4-8c2e-aecbd3bc1d30"/"key":"'"${CRON_KEY}"'"/g' \
       -e 's/"Motion":"d4b5feb4-8f9c-4b91-bfec-277c641fc5e3"/"Motion":"'"${PLUGINKEY_MOTION}"'"/g' \
       -e 's/"OpenCV":"644bb8aa-8066-44b6-955a-073e6a745c74"/"OpenCV":"'"${PLUGINKEY_OPENCV}"'"/g' \
       -e 's/"OpenALPR":"9973e390-f6cd-44a4-86d7-954df863cea0"/"OpenALPR":"'"${PLUGINKEY_OPENALPR}"'"/g' \
       "/opt/shinobi/conf.json"

# Set configuration for motion plugin ...
echo "Set configuration for motion plugin from environment variables ..."
sed -i -e 's/"host":"localhost"/"host":"'"${MOTION_HOST}"'"/g' \
       -e 's/"port":8080/"port":"'"${MOTION_PORT}"'"/g' \
       -e 's/"key":"d4b5feb4-8f9c-4b91-bfec-277c641fc5e3"/"key":"'"${PLUGINKEY_MOTION}"'"/g' \
       "/opt/shinobi/plugins/motion/conf.json"

# Set the admin password
if [ -n "${ADMIN_USER}" ]; then
    if [ -n "${ADMIN_PASSWORD}" ]; then
        echo "- Set the super admin credentials ..."
        # Hash the admins password
        echo "  - Hash super admin password ..."
        ADMIN_PASSWORD_MD5=$(echo -n "${ADMIN_PASSWORD}" | md5sum | sed -e 's/  -$//')
        # Set Shinobi's superuser's credentials
        echo "  - Set credentials ..."
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
