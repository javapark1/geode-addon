# Reactivating Workspaces on AWS EC2

This article describes how to reactivate VM workspaces that have been detached from AWS EC2 VMs. 

## Scenario

You have created a VM workspace with EC2 instances. After you were done running Geode/GemFire cluster(s) on the EC2 instances from the VM workspace, you terminated the EC2 instances. 

A few days later, you return to your work and are in need of reinstating the same workspace environment with new EC2 instances.

## VM Workspace Activation Steps

VM workspace activation steps involve updating two (2) workspace and cluster configuration files with the public IP addresses of  new EC2 instances.

- Workspace: `setenv.sh`
- Cluster: `cluster.properties`

### 1. Launch EC2 Instances

First, launch the desired number of EC2 instances from the EC2 Dashboard. For our example, we launched four (4) instances.

### 2. Update Workspace `setenv.sh`

Gather the public IP addresses of the EC2 instances and list them in the workspace `setenv.sh` file.

```console
switch_workspace ws-aws-gemfire
vi setenv.sh
```

Set the `VM_HOSTS` property with the public IP addresses and make sure `VM_USER` is set to the correct user name.

```bash
VM_HOSTS="3.134.79.6,18.219.86.104,18.224.214.212,18.222.146.161"
VM_USER="ec2-user"
```

### 3. Update `etc/cluster.properties`

Update the `etc/cluster.properties` file with the new EC2 IP addresses. For our example, the VM cluster name is `mygemfire`.

```console
switch_cluster mygemfire
vi etc/cluster.properties
```

Set the following VM properties. 

```bash
vm.locator.hosts=3.134.79.6
vm.locator.hosts=18.219.86.104,18.224.214.212,18.222.146.161
vm.user=ec2-user

# Set hostnameForClients for each IP address
vm.3.134.79.6.hostnameForClients=3.134.79.6
vm.18.219.86.104.hostnameForClients=18.219.86.104
vm.18.224.214.212.hostnameForClients=18.224.214.212
vm.18.222.146.161.hostnameForClients=18.222.146.161
```

It is important to set `hostnameForClients` for each host if you want to connect to the cluster from outside the EC2 environment. This is because the Geode/GemFire members are bound to the EC2 internal IP addresses. Make sure to follow the `vm.<host>.*` pattern for the property names.

:exclamation: If you have reinstated the workspace with an EC2 instance type that is different from the previous instance type then you may also need to change resource properties such as `heap.min` and `heap.max`.

### 4. Sync VMs

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

### 5. Install Software

`vm_sync` will display warning messages similar to the output shown above since the new EC2 instances do not have the required software installed. Download the required software and install them by running the `vm_install` command as shown below.

```console
 vm_install -java ~/Downloads/jdk-8u212-linux-x64.tar.gz \
            -geode ~/Downloads/pivotal-gemfire-9.9.1.tgz
```

### 6. Start Cluster

Start the cluster.

```console
start_cluster
```

## Summary

Reactivating a VM workspace on EC2 instances requires a simple step of updating the workspace and cluster configuration files with the new public IP addresses.
