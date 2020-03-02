# Workspaces on AWS EC2 Instances

This article provides step-by-step instructions for creating and running a VM workspace on AWS EC2 instances.

## Launch EC2 Instances

From the EC2 Dashboard launch four (4) EC2 instances of type `t2.micro` and collect their public IP addresses. For our example, we have named the instances and collected their public IP addresses as follows:

| Name    | IP Address     |
| ------- | -------------- |
| locator | 4.3.134.79.6   |
| member1 | 18.219.86.104  |
| member2 | 18.224.214.212 |
| member3 | 18.222.146.161 |

## Create VM Workspace

To create a workspace, run `create_workspace`, which by default runs in the interactive mode. For our example, let's run it in the non-interactive mode by specifying the `-quiet` option as follows: 

```console
create_workspace -quiet \
-name ws-aws-geode \
-cluster mygeode \
-java /home/dpark/Work/linux/jdk1.8.0_212 \
-geode /home/dpark/Work/linux/apache-geode-1.11.0 \
-vm 3.134.79.6,18.219.86.104,18.224.214.212,18.222.146.161 \
-vm-java /home/ec2-user/Geode/jdk1.8.0_212 \
-vm-geode /home/ec2-user/Geode/pivotal-gemfire-9.9.1 \
-vm-addon /home/ec2-user/Geode/geode-addon_0.9.0-SNAPSHOT \
-vm-workspaces /home/dpark/Geode/workspaces \
-vm-user ec2-user \
-vm-key /home/dpark/Work/aws/ecs.pem
```

The above creates the workspace named `ws-aws-geode` and places all the installations in the `/home/ec2-user/Geode` directory. When you are done with installation later, each EC2 instance will have the following folder contents:

```console
/home/ec2-user/Geode
├── apache-geode-1.11.0
├── geode-addon_0.9.0-SNAPSHOT
├── jdk1.8.0_212
└── workspaces
    ├── initenv.sh
    ├── setenv.sh
    └── ws-aws-geode
        └── clusters
            └── mygeode
```

The non-vm options, `-java` and `-geode` must be set to Java and Geode home paths in your local file system.

The following table shows the breakdown of the options.

| Option         | Value                                                    | Description                     |
|--------------- | -------------------------------------------------------- | ------------------------------- |
| -name          | ws-aws-geode                                             | Workspace name                  |
| -cluster       | mygeode                                                  | Cluster name                    |
| -java          | /home/dpark/Work/linux/jdk1.8.0_212                      | JAVA_HOME, local file system    |
| -geode         | /home/dpark/Work/linux/apache-geode-1.11.0               | GEODE_HOME, local file system   |
| -vm            | 3.134.79.6,18.219.86.104,18.224.214.212,18.222.146.161 | EC2 instance public IP addresses. Must be separated by command with no spaces |
| -vm-java       | /home/ec2-user/Geode/jdk1.8.0_212                        | JAVA_HOME, EC2 instances        |
| -vm-geode      | /home/ec2-user/Geode/pivotal-gemfire-9.9.1               | GEODE_HOME, EC2 instances       |
| -vm-addon      | /home/ec2-user/Geode/geode-addon_0.9.0-SNAPSHOT          | GEODE_ADDON_HOME, EC2 instances |
| -vm-workspaces | /home/dpark/Geode/workspaces                             | GEODE_ADDON_WORKSPACES_HOME, EC2 instances |
| -vm-user       | ec2-user                                                 | User name, EC2 instances        |
| -vm-key        | /home/dpark/Work/aws/ecs.pem                             | Private key file, EC2 instances |


## Configure Cluster

We launched `t2.micro` instances which only have 1 GB of memory. We need to lower the GemFire member heap size to below this value. Edit the `cluster.properties` file as follows:

```console
switch_workspace ws-aws-geode
switch_cluster mygeode
vi etc/cluster.properties
```

Change the heap and host properties in that file as follows:

```bash
# Lower the heap size from 1g to 512m
heap.min=512m
heap.max=512m

# Set the first VM as the locator
vm.locator.hosts=3.134.79.6

# Rest of the 3 VMs for members
vm.hosts=18.219.86.104,18.224.214.212,18.222.146.161
```

## Sync VMs

Run `vm_sync` to synchronize the workspace.

```console
vm_sync
```

The above command reports the following:

```console
Deploying geode-addon_0.9.0-SNAPSHOT to 3.134.79.6...
Deploying geode-addon_0.9.0-SNAPSHOT to 18.219.86.104...
Deploying geode-addon_0.9.0-SNAPSHOT to 18.224.214.212...
Deploying geode-addon_0.9.0-SNAPSHOT to 18.222.146.161...

Workspace sync: ws-aws-gemfire
   Synchronizing 3.134.79.6...
   Synchronizing 18.219.86.104...
   Synchronizing 18.224.214.212...
   Synchronizing 18.222.146.161...
------------------------------------------------------------------------------------------
WARNING:
/home/ec2-user/Geode/jdk1.8.0_212
   JDK not installed on the following VMs. The workspace will not be operational
   until you install JDK on these VMs.
       3.134.79.6 18.219.86.104 18.224.214.212 18.222.146.161
VM Java Home Path:
      /home/ec2-user/Geode/jdk1.8.0_212
To install Java on the above VMs, download the correct version of JDK and execute 'vm_install'.
Example:
   vm_install -java jdk1.8.0_212.tar.gz
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
WARNING:
   Geode is not installed on the following VMs. The workspace will not be operational
   until you install Geode on these VMs.
       3.134.79.6 18.219.86.104 18.224.214.212 18.222.146.161
VM Geode Path:
    /home/ec2-user/Geode/pivotal-gemfire-9.9.1
To install Geode on the above VMs, download the correct version of JDK and execute 'vm_install'.
Example:
   vm_install -geode pivotal-gemfire-9.9.1.tar.gz
------------------------------------------------------------------------------------------
```

## Install Software

`vm_sync` will display warning messages similar to the output shown above since the new EC2 instances do not have the required software installed. Download the required software and install them by running the `vm_install` command as shown below.

```console
 vm_install -java ~/Downloads/jdk-8u212-linux-x64.tar.gz \
            -geode ~/Downloads/pivotal-gemfire-9.9.1.tgz
```

## Start Cluster

Start the cluster.

```console
start_cluster
```

## Monitor Cluster

To monitor the cluster:

```console
show_cluster
```

## View Log

To view logs

```console
# ubuntu1
show_log

# ubuntu2
show_log -num 2
```

## Pulse

You can get the Pulse URL by running the `show_cluster -long` command. For our example, the URL is as follows:

http://3.134.79.6:7070/pulse(http://3.134.79.6:7070/pulse)

## Test Cluster

You can run the `perf_test` app to ingest data into the cluster and monitor the region sizes increase from Pulse.

First, create the `perf_test` app and edit its configuration file to point to the locator running on EC2.

```console
create_app
cd_app perf_test
vi etc/client-cache.xml
```

Set the locator host as in the `etc/client-cache.xml` with the EC2 IP address.

```xml
<pool name="serverPool">
   <locator host="3.134.79.6" port="10334" />
</pool>
```

Ingest data into the cluster.

```console
cd bin_sh
./test_ingestion -run
```

## Preserve Workspace

If you terminate the EC2 instances without removing the workspace, then your workspace will be preserved on your local machine. This means you can later reactivate the workspace by simply launching new EC2 instances and configuring the workspace with the new public IP addresses. The following link provides step-by-step instructions describing how to reactivate VM workspaces.

[Reactivating Workspaces on AWS EC2](Reactivating-Workspaces-on-AWS-EC2.md)

## Tear Down

1. Stop the cluster

If you want to remove the cluster from all the VMs, then you must first stop the cluster and execute the `remove_cluster` command.

```console
# Stop cluster including members and locator
stop_cluster -all
```

2. Remove the workspace

If you want to preserve the workspace so that you can later reactivate it then skip this step and jump to the next step; othereise, run the `remove_workspace` command which will also remove the cluster.

```console
# Simulate removing workspace from all VMs. Displays removal steps but does not
# actually remove the workspace.
remove_workspace -workspace ws-vm -simulate

# Remove workspace from all VMs. Runs in interactive mode.
remove_workspace -workspace ws-vm
```

3. Terminate the EC2 instances

From the EC2 Dashboard remove the EC2 instances.
