# Running Geode Docker

This article describes how to launch a Geode cluster using `docker-compose` and run the `perf_test` app.

## Install `apachegeode/geode` Image

```console
docker pull apachegeode/geode
```

## Download `geode-docker`

You don't need to build the cloned repo since we have installed the `apachegeode/geode` image.

```console
# Download geode-docker
git clone https://github.com/markito/geode-docker.git
```

## Create `geode-addon` Directory

Create the `geode-addon` directory and place the library files and cache.xml file as follows:

```console
cd geode-docker/composer
mkdir geode-addon
cp -r $GEODE_ADDON_HOME/lib $GEODE_ADDON_HOME/plugins geode-addon/
cp -r $CLUSTER_DIR/etc geode-addon/
```

## Replace `docker-compose.yml`

Place the following in `composer/docker-compose.yml`. Make sure to change the `hostname-for-clients` value (192.168.1.15) with your host OS IP address. Note that `geode-addon` uses the system property, `geode-addons.server.port` instead of gfsh's `--server-port` which does not work in the stand-alone (non-docker) environement.

```yaml
version: '2.4'

services:
  locator:
    image: apachegeode/geode
    hostname: locator
    mem_limit: 512m
    expose:
     - "10334"
     - "1099"
     - "7575"
    ports:
     - "1099:1099"
     - "10334:10334"
     - "7575:7575"
     - "7070:7070"
    volumes:
     - ./scripts/:/scripts/
    command: /scripts/gfshWrapper.sh gfsh start locator --name=locator --mcast-port=0

  server1:
    image: apachegeode/geode
    mem_limit: 1g
    depends_on:
     - locator
    expose:
     - "8080"
     - "40404"
     - "1099"
    ports:
     - "40404:40404"
    volumes:
     - ./scripts/:/scripts/
     - ./geode-addon:/geode-addon/
    command: /scripts/startServer.sh --max-heap=1G --hostname-for-clients=192.168.1.15 --classpath=/geode-addon/lib/*:/geode-addon/plugins/* --cache-xml-file=/geode-addon/etc/cache.xml --J=-Dgeode-addon.server.port=40404
    restart: on-failure

  server2:
    image: apachegeode/geode
    mem_limit: 1g
    depends_on:
     - locator
    expose:
     - "8080"
     - "40405"
     - "1099"
    ports:
     - "40405:40405"
    volumes:
     - ./scripts/:/scripts/
     - ./geode-addon:/geode-addon/
    command: /scripts/startServer.sh --max-heap=1G --hostname-for-clients=192.168.1.15 --classpath=/geode-addon/lib/*:/geode-addon/plugins/* --cache-xml-file=/geode-addon/etc/cache.xml --J=-Dgeode-addon.server.port=40405
    restart: on-failure

  server3:
    image: apachegeode/geode
    mem_limit: 1g
    depends_on:
     - locator
    expose:
     - "8080"
     - "40406"
     - "1099"
    ports:
     - "40406:40406"
    volumes:
     - ./scripts/:/scripts/
     - ./geode-addon:/geode-addon/
    command: /scripts/startServer.sh --max-heap=1G --hostname-for-clients=192.168.1.15 --classpath=/geode-addon/lib/*:/geode-addon/plugins/* --cache-xml-file=/geode-addon/etc/cache.xml --J=-Dgeode-addon.server.port=40406
    restart: on-failure
```

## Start Locators and Servers

```console
cd composer
docker-compose up
```

## Run `perf_test`

You can run `perf_test` as is without modifications.

```console
create_app
cd_app perf_test; cd bin_sh
./test_ingestion -run
```

## Tear Down

Ctrl-C from the `docker-compose up` command and prune the containers.

```console
docker container prune
```

## Tips

```console
# Create host volume
docker run -it --name container1 -v /c/Users/dpark/Work:/Work apachegeode/geode
```