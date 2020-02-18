# `geode-addon` Docker Compose

This article describes how to create a Docker environment and launch a Geode cluster using `docker-compose`.

:exclamation: You must first install Docker and Docker Compose. See [References](#References) for download links.

## Create `geode-addon` Docker Cluster

```console
create_docker -cluster mydocker
```

By default, the create_docker command adds two (2) Geode servers (members) in the cluster. You can change the number of servers using the `-count` option.

## Configure the Cluster Environment

```console
cd_workspace; cd_docker mydocker
```

Edit the `.env` file as needed.

```console
vi .env
```

Configure Geode servers by editing `geode-addon/gemfire.properties` and `geode-addon/cache.xml`.

```console
vi geode-addon/gemfire.properties
vi geode-addon/cache.xml
```

Place your application jar files in the `geode-addon/plugins` directory, which already contains `geode-addon` test jar for running `perf_test`. 

```console
ls geode-addon/plugins
```

## Start Cluster

```console
docker-compose up
```

## Run `gfsh`

`gfsh` must be run in the locator container.

```console
docker exec -it compose_locator_1 bash
gfsh
gfsh>connect --locator=locator[10334]
gfsh>list members
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
docker-compose down
docker container prune
```

## References
1. Install Docker, [https://docs.docker.com/install/](https://docs.docker.com/install/).
2. Install Docker Compose, [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/). 