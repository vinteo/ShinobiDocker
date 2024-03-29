#
# Builds a custom docker image for ShinobiCCTV Pro
#
FROM node:8

# Build arguments ...
# Shinobi's version information
ARG ARG_APP_VERSION 

# The channel or branch triggering the build.
ARG ARG_APP_CHANNEL

# The commit sha triggering the build.
ARG ARG_APP_COMMIT

# Update Shinobi on every container start?
#   manual:     Update Shinobi manually. New Docker images will always retrieve the latest version.
#   auto:       Update Shinobi on every container start.
ARG ARG_APP_UPDATE=auto

# Build data
ARG ARG_BUILD_DATE

# ShinobiPro branch, defaults to master
ARG ARG_APP_BRANCH=master

# Basic build-time metadata as defined at http://label-schema.org
LABEL org.label-schema.build-date=${ARG_BUILD_DATE} \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="GPLv3" \
    org.label-schema.name="MiGoller" \
    org.label-schema.vendor="MiGoller" \
    org.label-schema.version="${ARG_APP_VERSION}-${ARG_APP_BRANCH}" \
    org.label-schema.description="Shinobi Pro - The Next Generation in Open-Source Video Management Software" \
    org.label-schema.url="https://gitlab.com/users/MiGoller/projects" \
    org.label-schema.vcs-ref=${ARG_APP_COMMIT} \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://gitlab.com/MiGoller/ShinobiDocker.git" \
    maintainer="MiGoller" \
    Author="MiGoller, mrproper, pschmitt & moeiscool"

# Persist app-reladted build arguments
ENV APP_VERSION=$ARG_APP_VERSION \
    APP_CHANNEL=$ARG_APP_CHANNEL \
    APP_COMMIT=$ARG_APP_COMMIT \
    APP_UPDATE=$ARG_APP_UPDATE \
    APP_BRANCH=${ARG_APP_BRANCH}

# Set environment variables to default values
# ADMIN_USER : the super user login name
# ADMIN_PASSWORD : the super user login password
# PLUGINKEY_MOTION : motion plugin connection key
# PLUGINKEY_OPENCV : opencv plugin connection key
# PLUGINKEY_OPENALPR : openalpr plugin connection key
ENV ADMIN_USER=admin@shinobi.video \
    ADMIN_PASSWORD=admin \
    CRON_KEY=fd6c7849-904d-47ea-922b-5143358ba0de \
    PLUGINKEY_MOTION=b7502fd9-506c-4dda-9b56-8e699a6bc41c \
    PLUGINKEY_OPENCV=f078bcfe-c39a-4eb5-bd52-9382ca828e8a \
    PLUGINKEY_OPENALPR=dbff574e-9d4a-44c1-b578-3dc0f1944a3c \
    #leave these ENVs alone unless you know what you are doing 
    MYSQL_USER=majesticflame \
    MYSQL_PASSWORD=password \
    MYSQL_HOST=localhost \
    MYSQL_DATABASE=ccio \
    MYSQL_ROOT_PASSWORD=blubsblawoot \
    MYSQL_ROOT_USER=root 

# Create additional directories for: Custom configuration, working directory, database directory, scripts
RUN mkdir -p \
        /config \
        /opt/shinobi \
        /var/lib/mysql

# Assign working directory
WORKDIR /opt/shinobi

RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
RUN export DEBIAN_FRONTEND="noninteractive"

# Install package dependencies
RUN apt-get update && \
    apt-get install -y \
        libfreetype6-dev \ 
        libgnutls28-dev \ 
        libmp3lame-dev \ 
        libass-dev \ 
        libogg-dev \ 
        libtheora-dev \ 
        libvorbis-dev \ 
        libvpx-dev \ 
        libwebp-dev \ 
        libssh2-1-dev \ 
        libopus-dev \ 
        librtmp-dev \ 
        libx264-dev \ 
        libx265-dev \ 
        yasm && \
    apt-get install -y \
        build-essential \ 
        bzip2 \ 
        coreutils \ 
        gnutls-bin \ 
        nasm \ 
        tar \ 
        x264

# Install additional packages

RUN apt-get install -y \
        ffmpeg \
        git \
        make \
        mariadb-client \
        openrc \
        pkg-config \
        python \
        wget \
        tar \
        xz-utils

# Install MariaDB server... the debian way
RUN set -ex; \
	{ \
		echo "mariadb-server" mysql-server/root_password password '${MYSQL_ROOT_PASSWORD}'; \
		echo "mariadb-server" mysql-server/root_password_again password '${MYSQL_ROOT_PASSWORD}'; \
	} | debconf-set-selections; \
	apt-get update; \
	apt-get install -y \
		"mariadb-server" \
        socat \
	; \
    find /etc/mysql/ -name '*.cnf' -print0 \
		| xargs -0 grep -lZE '^(bind-address|log)' \
		| xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/'

RUN sed -ie "s/^bind-address\s*=\s*127\.0\.0\.1$/#bind-address = 0.0.0.0/" /etc/mysql/my.cnf

# Install Shinobi app including NodeJS dependencies
COPY ./ShinobiPro/ ./

RUN npm i npm@latest -g && \
    npm install pm2 -g && \
    npm install jsonfile && \
    npm install edit-json-file && \
    npm install ffbinaries && \
    npm install --unsafe-perm && \
    npm audit fix --force

# Copy code
COPY docker-entrypoint.migoller.sh ./docker-entrypoint.sh
COPY pm2Shinobi.yml ./
COPY /tools/modifyJson.js ./tools
RUN chmod -f +x ./*.sh

# Copy default configuration files
COPY ./config/conf.sample.json ./config/super.sample.json /opt/shinobi/

VOLUME ["/opt/shinobi/videos"]
VOLUME ["/config"]
VOLUME ["/var/lib/mysql"]

EXPOSE 8080

ENTRYPOINT ["/opt/shinobi/docker-entrypoint.sh"]

CMD ["pm2-docker", "pm2Shinobi.yml"]
