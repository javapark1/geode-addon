# Geode on Minikube using `kustomize`

This directory contains Kubernetes configuration files for deploying Geode, Prometheus, custom metrics API, and Horizontal Pod Autoscaler (HPA) on **Minikube**. The configuration files are to be used with the `kustomize` or `kubectl apply -k` command.

## Initializing Workspace

To follow instructions in this article, you must first install `geode-addon` and create a workspace. For example, the following creates the `ws-minikube` workspace in the `~/Geode/workspaces` directory. Make sure to source in the `initenv.sh` file.

```console
mkdir -p ~/Geode/workspaces
tar -C ~/Geode/ -xzf geode-addon_0.9.0-SNAPSHOT
~/Geode/geode-addon_0.9.0-SNAPSHOT/bin_sh/create_workspace -workspace ~/Geode/workspaces/ws-minikube
. ~/Geode/workspaces/ws-minikube/initenv.sh
```

We will be using the `$GEODE_ADDON_WORKSPACE` environment variable set by `initenv.sh` throughout this article. You can check its value as follows:

```console
echo $GEODE_ADDON_WORKSPACE 
/Users/dpark/Geode/workspaces/ws-minikube
```

## Required Software List

Before you begin, you must first install the following software. See the [References](#References) section for URIs.

- VirtualBox (for Windows, VirtualBox or Hyper-V)
- minikube
- docker (for Windows, Docker Toolbox if VirutalBox, Docker Desktop if Hyper-V)
- kubectl
- kustomize (optional - `kubectl apply -k` equivalent to `kustomize` )
- openssl
- jq (optional)
- watch (optional)

### `kubectl` on Windows 10

Running `kubectl` on Windows can be a challenge due to the lack of examples and support for command auto-completion. To ease the pain, it is recommended that you install `kubectl` on WSL. The following article provides installation steps:

[Minikube on WSL](Minikube-on-WSL.md)

## Creating Kubernetes Environment

In your workspace, create a Kubernetes environment in which we will setup Geode deployment files.

```console
create_k8s -cluster minikube-test

# Upon creation, source in the setenv.sh file as follows.
. $GEODE_ADDON_WORKSPACE/k8s/minikube-test/bin_sh/setenv.sh
```

We will be using the `$GEODE_KUSTOM_DIR` environment variable set by `setenv.sh` throughout the subsequent sections.

## Quick Start

First, start the Minikube VM. If you are using Windows Hyper-V, then replace `--vm-driver=virtualbox` with `--vm-driver=hyperv`.

```console
# Start minikube with 5Gi and 4 CPUs.
# If you are using Hyper-V, the specify --vm-driver=hyperv
minikube start --extra-config=kubelet.authentication-token-webhook=true --memory=5120 --cpus=4 --vm-driver=virtualbox

# Login to the host and create a directory in the host node (minikube)
# where we will upload addon jar files. We'll be mouting /data/custom as
# a persistent volume later.
minikube ssh
sudo mkdir -p /data/custom/plugins/v1
sudo chmod -R 777 /data
# Change password to docker
sudo passwd docker
exit
```

Let's add the Minikube IP address to the `/etc/hosts` file for convenience. The Kubernetes configuration files included in `geode-addon` use the host name `minikube`.

**Linux:**

```console
sudo echo "$(minikube ip)	minikube" >> /etc/hosts
```

**Windows:**

If you are using WSL, you should also add the `minikube` host name in the Windows `hosts` file.

```console
minikube.exe ip
172.17.34.252

REM Edit the hosts file and add the minikube host name
notepad C:\Windows\System32\drivers\etc\hosts
172.17.34.252	minikube
```

With the `minikube` host name in place, you can now use it to login to the Minikube VM. Let's upload the required binary files to the host OS file system which we'll be mounting as a persistent volume shortly.

```console
# Upload addon jar files to the minikube host.
scp -r $GEODE_ADDON_HOME/lib/* $GEODE_ADDON_HOME/plugins/* docker@minikube:/data/custom/plugins/v1/

# Upload the cluster's etc directory that contains cache.xml
cd_cluster mygeode
scp -r etc docker@minikube:/data/custom/
```

If you are using WSL then you will need to convert the minikube certificate file paths from Windows to Unix notations. From WSL, edit the `set_minikube` and `set_minikube.bat` scripts to enter the minikube IP and your user name, and run it as follows:

```console
# Edit both set_minikube and set_minikube.bat and enter the user name and minikube IP address
cd $GEODE_KUSTOM_DIR/bin_sh
vi set_minikube set_minikube.bat

USER_NAME=<your user name>
MINIKUBE_IP=<minikube ip>

# Save set_minikube and run it
./set_minikube
```

:exclamation: Whenever you switch from WSL to PowerShell, you must run `set_minikube.bat` to set the correct paths, and vice versa.

After running `set_minikube`, now create certificates for Prometheus as follows.

```console
# Create TLS certificates for the Prometheus custom metrics API adapter
./create_certs
```

You are now ready to deploy containers.

```console
# Change directory to etc/ where the Kubernetes configuration files are located.
cd $GEODE_KUSTOM_DIR/etc

# Create static persistent volume where we will store addon jar files
kubectl apply -k geode/storage/minikube/

# Copy base files to the overlay directory.
# Make changes to geode/overlay-base/server.yaml as necessary. No changes required for our demo.
cp geode/base/server-ss.yaml geode/overlay-base/

# Copy HPA metrics file to the overlay directory also. You can add other
# metrics to autoscale as needed.
cp geode/base/geode-hpa-custom.yaml geode/overlay-base/

# Deploy Geode.
kubectl apply -k geode/overlay-base/

# Deploy custom metrics API and start Prometheus/HPA
kubectl apply -k custom-metrics/overlay-base/

# Monitor HPA.
watch kubectl describe hpa my-release-geode
``` 

## Directory Overview

The `bin_sh` directory contains the `create_certs` script for generating the required secret file with TLS certificates. Make sure to run this script first before running Kubernetes.

The `kustom/etc` directory contains the entire Kubernetes configuration files. Each sub-directory contains `kustomization.yaml` that includes base directories and resource files for their respective configuration.

The `storage/minkube` directory contains storage configuration files that are specific to Minikube. These files create a local *hostPath* storage, persistent volume and claim used by Geode server pods for loading application specific configuration and library files.

The `geode/base` directory is the base directory that contains all the configuration files for deploying and starting Geode pods.

The `geode/overlay-base` directory contains configuration files that customize or patch the base files. Note that we also copied the `geode-hpa-custom.yaml` file into this directory in [Quick Start](#Quick-Start). You can include additional custom metrics in this file to autoscale Geode pods. The custom metrics are defined in `custom-metrics-api/custom-metrics-config-map.yaml`, which you can also extend to define additional custom metrics.

See [Quick Start](#Quick-Start) for the execution order.

```console
kustom
├── bin_sh
└── etc
    ├── custom-metrics
    │   ├── base
    │   ├── custom-metrics-api
    │   ├── metrics-server
    │   ├── overlay
    │   └── prometheus
    └── geode
        ├── base
        ├── init
        ├── overlay-base
        ├── overlay-nfs
        └── storage
            └── minikube
```

## Monitoring Kubernetes

### Dashboard

Start the Kubernetes dashboard by running the following command. It will automatically launch the browser.

```console
minikube dashboard &
```

### Prometheus

Prometheus runs in the `monitoring` namespace and has the port number `31190` exposed. Use the following URI in the browser.

```console
http://minikube:31190 
```

### HPA (Horizontal Pod Autoscaler)

You can monitor the HPA using the `watch` command as follows:

```console
# Watch HPA
watch kubectl describe hpa my-release-geode 
```

### Metrics API

You can also invoke the API to monitor any metrics.

```console
# Watch the on_heap-ratio metric
watch -d 'kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/on_heap_ratio" |jq'
```

### Geode Pulse 

The Geode Pulse service port is `30070`.

```console
http://minikube:30070/pulse/
```

## Running Client Applications

### Minikube

:exclamation: Before you begin, make sure Minikube's clock is properly synchronized. Minikube's clock can lag behind if your laptop has gone into the sleep mode, for example. This can be done as follows:

```console
minikube ssh
docker run -i --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i date -u $(date -u +%m%d%H%M%Y)
```

#### Server Pool via Node Ports

Unfortunately, Geode (v1.11.0) does not provide a port-forwarding service for locators. This prevents external client apps from making connections to locators. That means instead of creating a locator pool, you must create a server pool with the server endpoints. To run the `perf_test` app, for example, edit the `client-cache.xml` file as follows (service ports `30404`, `30405`, and `30406` have been exposed):

Edit `client-cache.xml`:

```console
create_app
cd_app perf_test
vi etc/client-cache.xml
```

Replace the locator endpoint with server endpoints as shown below. Note that `read-timeout` and `retry-attempts` are set to ensure the client connections do not timeout prematureally. This may occur when you run the client app initially due to the limited Kubernetes resrouces in the Minikube environment.

```xml
<!-- $GEODE_ADDON_WORKSPACE/apps/perf_test/etc/client-cache.xml -->
   <pool name="serverPool" read-timeout="20000" retry-attempts="5">
      <server host="minikube" port="30404" />
      <server host="minikube" port="30405" />
   </pool>
```

## Testing Horizontal Pod Autoscaler (HPA)

With the custom metrics installed as described in the [Quick Start](#Quick-Start) section, you can automatically scale out or in the Geode cluster running on minishift. Kubernetes HPA is responsible for auto-scaling and you can monitor it by executing the following command.

```console
# Monitor HPA.
watch kubectl describe hpa my-release-geode
```

### Auto-Scaling Out

HPA has been configure to auto-scale when the `on_heap_ratio` metric reaches 850m or 85% of the max heap. You can monitor the following lines displayed by the above command.

```console
Metrics:                    ( current / target )
  "on_heap_ratio" on pods:  121m / 850m
```

When the `current` value reaches greater than 850m, HPA will add another pod to the cluster.

To test HPA, first, configure the `perf_test`'s `client-cache.xml` as described in the [Running Client Applications](#Running-Client-Applications) section.

You will need to increase the number of entries to go above the threshold value of 850m. Edit `etc/ingestion.properties` and set the profile entry count to 20000 as follows.

```console
cd_app perf_test
vi etc/ingestion.properties
profile.totalEntryCount=20000
```

The above change should add just enough data into the Geode cluster so that it will increase the `on_heap_ratio` to above 850m.

Run `perf_test` as follows:

```bash
cd_app perf_test; cd bin_sh
./test_ingestion -run
```

### Auto-Scaling In

The `test_ingestion` script puts data into two regions: `eligibility` and `tx`. You can configure these regions with TTL to evict data so that you can see the autoscaling taking place automatically.

For our demo, let's just destroy the `profile` region using `gfsh` to free memory. After destroying the region, we should also run `gc` on each member to collect the unused memory.

Note that the default setting for scaling in is 5 minutes. After 5 minutes, you should see HPA removing a server pod from the Geode cluster. 

Let's login to one of the locator containers and run `gfsh`.

```console
# Login to a locator container
kubectl exec -it locator-0 bash

# Get the locator cluster IP and port number
echo $LOCATOR_SERVICE_HOST[$LOCATOR_SERVICE_PORT]
10.96.102.164[10334]

# Run gfsh and use the cluster IP and port number for the locator endpoint
gfsh
gfsh>connect --locator=10.96.102.164[10334]
gfsh>destroy --region=/profile
gfsh>gc --member=server-0
gfsh>gc --member=server-1
gfsh>gc --member=server-2
```

## Summary: Starting Geode

If yo have configured the environment as shown in [Quick Start](#quick-start), then you can execute the following to start Geode.

```console
cd $GEODE_KUSTOM_DIR/etc
kubectl apply -k geode/storage/minikube/
kubectl apply -k geode/overlay-base/
kubectl apply -k custom-metrics/overlay-base/
```

## Tearing Down

Execute the following:

```console
# Uninstall custom metrics and Geode.
kubectl delete -k custom-metrics/overlay-base/
kubectl delete -k geode/overlay-base/
kubectl delete -k geode/storage/minikube/

# Delete the minikube VM.
minikube delete
```

## Tips

### Viewing Server Log

```console
# Login to a server container
kubectl exec -it server-0 bash

# Tail server log
tail -f /data/server-0.log
```

### Running `gfsh`

```console
# Login to a locator container
kubectl exec -it locator-0 bash

# Get the locator cluster IP and port number
echo $LOCATOR_SERVICE_HOST[$LOCATOR_SERVICE_PORT]
10.96.102.164[10334]

# Run gfsh and use the cluster IP and port number for the locator endpoint
gfsh
gfsh> connect --locator=10.96.102.164[10334]
```

## Troubleshooting Guide
 
### I can't start the minikube dashboard. I'm getting the following error message:

```console
X Unable to enable dashboard: decode C:\Users\<user>\.minikube\config\config.json: EOF
```

**Solution:** Delete minikube and the `config.json` file, and restart minikube

```console
minikube delete
erase C:\Users\<user>\.minikube\config\config.json 
minikube start --extra-config=kubelet.authentication-token-webhook=true --memory=5120 --cpus=4 --vm-driver=virtualbox
```

## References

1. Download VirtualBox, [https://www.virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads).
2. Install Minikube, [https://kubernetes.io/docs/tasks/tools/install-minikube/](https://kubernetes.io/docs/tasks/tools/install-minikube/).
3. Install Docker, [https://docs.docker.com/install/](https://docs.docker.com/install/).
4. Install and Set Up kubectl, [https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
5. Install kustomize, [https://github.com/kubernetes-sigs/kustomize/blob/master/docs/INSTALL.md](https://github.com/kubernetes-sigs/kustomize/blob/master/docs/INSTALL.md). 
6. OpenSSL Download, [https://www.openssl.org/source/](https://www.openssl.org/source/).
7. Download jq, [https://stedolan.github.io/jq/download/](https://stedolan.github.io/jq/download/).
8. Prometheus Adapter for Kubernetes Metrics APIs, [https://github.com/DirectXMan12/k8s-prometheus-adapter](https://github.com/DirectXMan12/k8s-prometheus-adapter).
9. Querying Prometheus, [https://prometheus.io/docs/prometheus/latest/querying/basics/](https://prometheus.io/docs/prometheus/latest/querying/basics/).
10. Horizontal Pod Autoscaler, [https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/).
11. k8s-prom-hpa, *Custom Autoscaling Example*, [https://github.com/stefanprodan/k8s-prom-hpa](https://github.com/stefanprodan/k8s-prom-hpa).
12. Minikube Tunnel Design Doc, [https://github.com/kubernetes/minikube/blob/master/docs/tunnel.md](https://github.com/kubernetes/minikube/blob/master/docs/tunnel.md).
