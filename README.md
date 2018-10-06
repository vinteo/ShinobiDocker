# Shinobi CCTV on Docker

This repository provides Docker images regulary built from the [official Shinobi Docker image repository](https://gitlab.com/Shinobi-Systems/ShinobiDocker) on [GitLab](https://gitlab.com/).

Since forking my image; mrproper's previous image has been merged to make an ultimate docker image with `docker-compose`.

Thank you mrproper, pschmitt & moeiscool for the contuination of the development for the official Docker image.

Find my original image on Docker Hub [migoller/shinobi](https://hub.docker.com/r/migoller/shinobi/) and the git repository for upcoming images at https://gitlab.com/MiGoller/ShinobiDocker .

## Supported tags
Aside the "official" Shinobi Docker image I provide a Docker image optimized for microservice environments.
### Official Shinobi Docker images
- `1.0.38-official`, `1.0-official`, `1-official`, `official`, `latest` [master/official/Dockerfile](https://gitlab.com/MiGoller/ShinobiDocker/blob/master/official/Dockerfile)
- `1.0.38-alpine`, `1.0-alpine`, `1-alpine`, `alpine` [master/alpine/Dockerfile](https://gitlab.com/MiGoller/ShinobiDocker/blob/master/alpine/Dockerfile)
- `1.0.38-debian`, `1.0-debian`, `1-debian`, `debian` [master/debian/Dockerfile](https://gitlab.com/MiGoller/ShinobiDocker/blob/master/debian/Dockerfile)

### Microservice Shinobi Docker images
- `1.0.38-microservice`, `1.0-microservice`, `1-microservice`, `microservice` [microservice/alpine/Dockerfile](https://gitlab.com/MiGoller/ShinobiDocker/blob/microservice/alpine/Dockerfile)
- `1.0.38-microservice-debian`, `1.0-microservice-debian`, `1-microservice-debian`, `microservice-debian` [microservice/debian/Dockerfile](https://gitlab.com/MiGoller/ShinobiDocker/blob/microservice/debian/Dockerfile)

> **Warning**:
> Currently Alpine-based Docker images Shinobi may encounter DNS-resolution issues to hostnames and FQDN.
> If you encounter such a problem just give the Debian-based variant a try.

### The "official" Shinobi Docker image
This repository is a fork of the [official Shinobi Docker image repository](https://gitlab.com/Shinobi-Systems/ShinobiDocker). I will merge the upstream repository into my fork regulary for new commits, features and bug fixes.
No need, to clone the repo and to run `docker-compose ...`, just run my "offical" image `migoller/shinobidocker` to get Shinobi bundled with a MariaDB server in on container.

You'll notice the `alpine` and the `debian` tags as well. These are the differences.

> The `official` and the `alipine` tagged images are based on an Alpine-linux image. Be aware of the DNS-resolution issues.

##### The "official" image
The official image is built from a fork of the [official Shinobi Docker image repository](https://gitlab.com/Shinobi-Systems/ShinobiDocker) . There are no optimizations enhancing the image.

##### The "alpine" image
The alpine image is identical to the features and the content of the official image but is reduced in size and relies on the Alpine-based [node:8-alpine](https://hub.docker.com/_/node/) Docker image.

##### The "debian" image
The debian image is identical to the features and the content of the official image but is built upon the Debian-based [node:8](https://hub.docker.com/_/node/) Docker image.

> Right now there are no DNS-resolution issues known to Shinobi when running a Debian-image.

### My "microservice" Shinobi Docker image
According to the [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices) it's best to [decouple applications](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#decouple-applications).
> Each container should have only one concern.
> The container should be stateless.

It doesn't makes sense to reinvent the wheel while there are so many specialized Docker images eg. for MariaDB, etc. around, right?
- The "microservice" image has only one concern: Shinobi! There's no bundled MariaDB server.
- The corresponding container is stateless. Any data will be stored outside the container by using volumes or volume mounts.
- The image allows to connect to a MariaDB server within the same stack running `docker-compose` or to link to an already existing MariaDB server.
- Alpine-based images and Debian-based images available. Get rid of the DNS-resolution issues by switching from the Alpine-based image to the Debian-based image!

## How to Dock Shinobi
Now you have at least two additional options to dock Shinobi.
> I assume that you followed the guide eg. [Get Docker CE for Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/) to install Docker CE. If you do not [Manage Docker as a non-root user](https://docs.docker.com/install/linux/linux-postinstall/) you'll have to `sudo`the Docker commands.
> The `docker cli` is used when managing individual containers on a docker engine. It is the client command line to access the docker daemon api. 

These are some basic steps to get an container up and running and to persists the containers data.
1. Create a directory for the application.
    This directory may hold the `.service`-files, `docker-compose` files, etc. as well.
2. Create a directory for the application's data like configurations, etc.
    We will mount this directory to a directory inside of the container to persist the container data. So the data will stay even if the container gets removed, updated, etc.
    > The container should be stateless.
3. Run the Docker container for the application.
4. Register the application as a service.

### Dock the "official" Shinobi Docker image
The official configuration for the Shinobi Docker image will let you run Shinobi on Docker as a single-container application: Shinobi comes with it's own bundled MariaDB server. So it's a kind of "plug'n'play".

##### Run the pre-built image
1. First create directories for Shinobi's database, video and configuration files.
    ```
    $ mkdir -p [Path to Shinobi direcory]/config [Path to Shinobi direcory]/datadir [Path to Shinobi direcory]/videos
    ```
2. To start Shinobi just type:
    ```
    $ docker run -d \
        -p 8080:8080 \
        -v /etc/localtime:/etc/localtime:ro \
        -v /etc/timezone:/etc/timezone:ro \
        -v [Path to Shinobi direcory]/config:/config \
        -v [Path to Shinobi direcory]/datadir:/var/lib/mysql \
        -v [Path to Shinobi direcory]/videos:/opt/shinobi/videos \
        -v /dev/shm/shinobiDockerTemp:/dev/shm/streams \
        migoller/shinobidocker
    ```

That's it.

Feel free to choose between the `official`, the `alpine` and the `debian`tags. Just add the corresponding tag to the imagename. You do not have to add the `official` tag, because that image is tagged as `latest`as well.
```
$ docker run -d \
    -p 8080:8080 \
    ... \
    migoller/shinobidocker:alpine
```
```
$ docker run -d \
    -p 8080:8080 \
    ... \
    migoller/shinobidocker:debian
```

##### Checkout and run docker-compose
If you want to run `docker-compose` for the "official" image, you can do that as well.

>  `docker-compose` should already be installed.

1. Clone the Repo and enter the `docker-shinobi` directory.
    ```
    git clone https://gitlab.com/Shinobi-Systems/ShinobiDocker.git ShinobiDocker && cd ShinobiDocker
    ```

2. Spark one up.
    ```
    sh start-image.sh
    ```

### Dock the "microservice" Shinobi Docker image
Run Shinobi using the "microservice" images as a stack or connect the Shinobi container to an already existing MariaDB server.

##### Run a Shinobi stack on docker
Well, that's quite easy. A Shinobi stack creates two containers: A container for Shinobi and a second container for Shinobi's private MariaDB server.

1. First create directories for Shinobi's database, video and configuration files.
    ```
    $ mkdir -p [Path to Shinobi direcory]/config [Path to Shinobi direcory]/datadir [Path to Shinobi direcory]/videos
    ```
    
2. Create a `docker-compose.yml` file in the directory `[Path to Shinobi direcory]` with the following content.
    ```
    version: '2'
    services:
      db:
        image: mariadb
        env_file:
          - MySQL.env
        volumes:
          - ./datadir:/var/lib/mysql
      shinobi:
        image: migoller/shinobidocker:microservice-debian
        env_file:
          - MySQL.env
          - Shinobi.env
        volumes:
          - /etc/localtime:/etc/localtime:ro
          - /etc/timezone:/etc/timezone:ro
          - ./config:/config
          - ./videos:/opt/shinobi/videos
          - /dev/shm/shinobiDockerTemp:/dev/shm/streams
        ports:
          - "8080:8080"
    ```

3. Create `.env`-files to set the environment variables.
    Use `.env`-files to set the environment variables only ones but incorporate them in many containers. We need environment variables to configure Shinobi and MariaDB at runtime, because the container is stateless.
    
    1. Create `MySQL.env` with the following content.
        ```
        MYSQL_USER=majesticflame
        MYSQL_PASSWORD=password
        MYSQL_HOST=db
        MYSQL_DATABASE=ccio
        MYSQL_ROOT_PASSWORD=blubsblawoot
        MYSQL_ROOT_USER=root
        ```
    2. Create `Shinobi.env` with the following content.
        ```
        ADMIN_USER=admin@shinobi.video
        ADMIN_PASSWORD=admin
        CRON_KEY=b59b5c62-57d0-4cd1-b068-a55e5222786f
        PLUGINKEY_MOTION=49ad732d-1a4f-4931-8ab8-d74ff56dac57
        PLUGINKEY_OPENCV=6aa3487d-c613-457e-bba2-1deca10b7f5d
        PLUGINKEY_OPENALPR=SomeOpenALPRkeySoPeopleDontMessWithYourShinobi
        MOTION_HOST=localhost
        MOTION_PORT=8080
        ```
        
4. To start the Shinobi stack just type:
    ```
    $ docker-compose up -d
    ```
    If you want to stop the stack run `docker-compose down`.

The stack should be up and running.

##### Run a Shinobi against an already existing MariaDB server
Well, that's a bit like a Shinobi stack without a stack. We do not need to launch a private MariaDB server, but we have to connect to an already existing one. Here we go.

> The Shinobi container creates the database on your MariaDB server, creates the user account for Shinobi and sets the required privileges, **if you specify MYSQL_ROOT_USER and MYSQL_ROOT_PASSWORD**.

You're already running a MariaDB server container like this, right?
```
$ docker run -d --name [YourMariaDbContainerName] \
    -v /etc/localtime:/etc/localtime:ro \
	-v /etc/timezone:/etc/timezone:ro \
	-v [Path to your MariaDB server data files]:/var/lib/mysql \
	-e MYSQL_ROOT_PASSWORD=[Your very strong MariaDB root password] \
	-p 3306:3306 \
	mariadb
```

1. First create directories for Shinobi's database, video and configuration files.
    ```
    $ mkdir -p [Path to Shinobi direcory]/config [Path to Shinobi direcory]/datadir [Path to Shinobi direcory]/videos
    ```
2. To start Shinobi just type:
    ```
    $ docker run -d \
        --link [YourMariaDbContainerName]:db \
        -p 8080:8080 \
        -e ADMIN_USER=admin@shinobi.video \
        -e ADMIN_PASSWORD=admin \
        -e MYSQL_USER=majesticflame\
        -e MYSQL_PASSWORD=password\
        -e MYSQL_HOST=db \
        -e MYSQL_DATABASE=ccio \
        -e MYSQL_ROOT_PASSWORD=[Your very strong MariaDB root password] \
        -e MYSQL_ROOT_USER=[Your MariaDB root username] \
        -e CRON_KEY=b59b5c62-57d0-4cd1-b068-a55e5222786f \
        -e PLUGINKEY_MOTION=49ad732d-1a4f-4931-8ab8-d74ff56dac57 \
        -e PLUGINKEY_OPENCV=6aa3487d-c613-457e-bba2-1deca10b7f5d \
        -e PLUGINKEY_OPENALPR=SomeOpenALPRkeySoPeopleDontMessWithYourShinobi \
        -e MOTION_HOST=localhost \
        -e MOTION_PORT=8080 \
        -v /etc/localtime:/etc/localtime:ro \
        -v /etc/timezone:/etc/timezone:ro \
        -v [Path to your Shinobi data files]/config:/config \
        -v [Path to your Shinobi data files]/datadir:/var/lib/mysql \
        -v [Path to your Shinobi data files]/videos:/opt/shinobi/videos \
        -v /dev/shm/shinobiDockerTemp:/dev/shm/streams \
        migoller/shinobidocker:microservice-debian
    ```

That's it.

## Login to Shinobi
The first time start will take a few seconds, because the Shinobi container creates the database on your MariaDB server, creates the user account for Shinobi and sets the required privileges, **if you specify MYSQL_ROOT_USER and MYSQL_ROOT_PASSWORD**.
 
Now try to open Shinobi's super admin UI. Open your Docker host's IP address in your web browser on port `8080`. Open the superuser panel to create an account.
```
Web Address : http://xxx.xxx.xxx.xxx:8080/super
Username : admin@shinobi.video
Password : admin
```
After account creation head on over to the main `Web Address` and start using Shinobi!
```
http://xxx.xxx.xxx.xxx:8080/
```

Enjoy.

# HTTPS - SSL encryption for transport security
There are many different possibilities to introduce encryption depending on your setup. 

I recommend using a reverse proxy in front of your installation like the popular [nginx-proxy](https://github.com/jwilder/nginx-proxy) and [docker-letsencrypt-nginx-proxy-companion](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion) containers. Please check the according documentations before using this setup.
