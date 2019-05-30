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
            cp -f ./sql/FixLdapAuth.sql ./sql_temp

            if [ -n "${MYSQL_DATABASE}" ]; then
                echo " - Set database name: ${MYSQL_DATABASE}"
                sed -i  -e "s/ccio/${MYSQL_DATABASE}/g" \
                    "./sql_temp/framework.sql"
                
                sed -i  -e "s/ccio/${MYSQL_DATABASE}/g" \
                    "./sql_temp/user.sql"

                sed -i  -e "s/ccio/${MYSQL_DATABASE}/g" \
                    "./sql_temp/FixLdapAuth.sql"
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

            echo "- Fix user table for LDAP auth issues ..."
            mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST -e "source ./sql_temp/FixLdapAuth.sql" || true

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
        node /opt/shinobi/tools/modifyJson.js "/opt/shinobi/conf.json" db.user="${MYSQL_USER}"
    fi

    if [ -n "${MYSQL_PASSWORD}" ]; then
        echo "  - MariaDB password."
        node /opt/shinobi/tools/modifyJson.js "/opt/shinobi/conf.json" db.password="${MYSQL_PASSWORD}"
    fi

    if [ -n "${MYSQL_HOST}" ]; then
        echo "  - MariaDB server host: ${MYSQL_HOST}"
        node /opt/shinobi/tools/modifyJson.js "/opt/shinobi/conf.json" db.host="${MYSQL_HOST}"
    fi

    if [ -n "${MYSQL_DATABASE}" ]; then
        echo "  - MariaDB database name: ${MYSQL_DATABASE}"
        node /opt/shinobi/tools/modifyJson.js "/opt/shinobi/conf.json" db.database="${MYSQL_DATABASE}"
    fi
fi

# Set keys for CRON and PLUGINS ...
echo "- Set keys for CRON and PLUGINS from environment variables ..."
if [ -n "${CRON_KEY}" ]; then
    node /opt/shinobi/tools/modifyJson.js "/opt/shinobi/conf.json" cron.key="${CRON_KEY}"
fi

if [ -n "${PLUGINKEY_MOTION}" ]; then
    node /opt/shinobi/tools/modifyJson.js "/opt/shinobi/conf.json" pluginKeys.Motion="${PLUGINKEY_MOTION}"
fi

if [ -n "${PLUGINKEY_OPENCV}" ]; then
    node /opt/shinobi/tools/modifyJson.js "/opt/shinobi/conf.json" pluginKeys.OpenCV="${PLUGINKEY_OPENCV}"
fi

if [ -n "${PLUGINKEY_OPENALPR}" ]; then
    node /opt/shinobi/tools/modifyJson.js "/opt/shinobi/conf.json" pluginKeys.OpenALPR="${PLUGINKEY_OPENALPR}"
fi

# Set configuration for motion plugin ...
echo "Set configuration for motion plugin from environment variables ..."
node /opt/shinobi/tools/modifyJson.js "/opt/shinobi/plugins/motion/conf.json" host="${MOTION_HOST}" port="${MOTION_PORT}" key="${PLUGINKEY_MOTION}"

# Set password hash type
if [ -n "${PASSWORD_HASH}" ]; then
    echo "Set password hast type to ${PASSWORD_HASH} from environment variable PASSWORD_HASH !"
    node /opt/shinobi/tools/modifyJson.js "/opt/shinobi/conf.json" passwordType="${PASSWORD_HASH}"
fi

# Set the admin password
if [ -n "${ADMIN_USER}" ]; then
    if [ -n "${ADMIN_PASSWORD}" ]; then
        echo "- Set the super admin credentials ..."
        # Hash the admins password
        export APP_PASSWORD_HASH=$( node -pe "require('./conf.json')['passwordType']" )
        if [ ! -n "${APP_PASSWORD_HASH}" ]; then
            export APP_PASSWORD_HASH="md5"
        fi

        echo "  - Hash super admin password (${APP_PASSWORD_HASH})..."
        case "${APP_PASSWORD_HASH}" in
            md5)
                # MD5 hashing - unsecure!
                ADMIN_PASSWORD_HASH=$(echo -n "${ADMIN_PASSWORD}" | md5sum | sed -e 's/  -$//')
                ;;
            
            sha256)
                # SHA256 hashing
                ADMIN_PASSWORD_HASH=$(echo -n "${ADMIN_PASSWORD}" | sha256sum | sed -e 's/  -$//')
                ;;
            
            sha512)
                # SHA512 hashing with salting
                ADMIN_PASSWORD_HASH=$(echo -n "${ADMIN_PASSWORD}" | sha512sum | sed -e 's/  -$//')
                ;;

            *)
                echo "Unsupported password type ${APP_PASSWORD_HASH}. Set to md5, sha256 or sha512."
                exit 1
        esac

        # Set Shinobi's superuser's credentials
        echo "  - Set credentials ..."
        #   ISSUE-10: Bugfix
        # node /opt/shinobi/tools/modifyJson.js "/opt/shinobi/super.json" mail="${ADMIN_USER}" pass="${ADMIN_PASSWORD_HASH}"
        sed -i -e 's/"mail":"admin@shinobi.video"/"mail":"'"${ADMIN_USER}"'"/g' \
            -e "s/21232f297a57a5a743894a0e4a801fc3/${ADMIN_PASSWORD_HASH}/g" \
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
