---
title: "Live Migration"
weight: 70
labfoldernumber: "07"
description: >
  Migrate running VMs to other Nodes for maintenance or other reasons
---

## Introduction

The Live Migration feature (`LiveMigration`) is enabled by default in recent KubeVirt Versions, previously it needed to be enabled in the KubeVirt configuration running on the cluster (`kubectl get kubevirt kubevirt -n kubevirt -o yaml`).

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
      - Sidecar
      - CommonInstancetypesDeploymentGate
      - ExperimentalIgnitionSupport
      - HotplugVolumes
      - ExpandDisks
      - Snapshot
      - VMExport
      - BlockVolume
```

Additionally the LiveMigration feature can be configured under `spec.configuration.migrations` whit a set of configuration parameters. The full list can be found in the [API Reference](https://kubevirt.io/api-reference/v1.3.0/definitions.html#_v1_migrationconfiguration)

* `bandwidthPerMigration` BandwidthPerMigration limits the amount of network bandwidth live migrations are allowed to use. The value is in quantity per second. Defaults to 0 (no limit)
* `parallelMigrationsPerCluster` ParallelMigrationsPerCluster is the total number of concurrent live migrations allowed cluster-wide. Defaults to 5
* `parallelOutboundMigrationsPerNode` ParallelOutboundMigrationsPerNode is the maximum number of concurrent outgoing live migrations allowed per node. Defaults to 2
* `completionTimeoutPerGiB` CompletionTimeoutPerGiB is the maximum number of seconds per GiB a migration is allowed to take. If a live-migration takes longer to migrate than this value multiplied by the size of the VMI, the migration will be cancelled, unless AllowPostCopy is true. Defaults to 800
* `progressTimeout` ProgressTimeout is the maximum number of seconds a live migration is allowed to make no progress. Hitting this timeout means a migration transferred 0 data for that many seconds. The migration is then considered stuck and therefore cancelled. Defaults to 150

{{% alert title="Limitations" color="warning" %}}

* Virtual Machines using PVC must have a `RWX` access mode to be Live-Migrated
* Additionally, pod network binding of bridge interface is not allowed
* Live migration requires ports `49152`, `49153` to be available in the `virt-launcher` pod. If these ports are explicitly specified in masquarade interface, live migration will not function.

{{% /alert %}}


## {{% task %}} Creating a virtual machine

Create a new file `livemigration.yaml` in the folder `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/` with the following content:


```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/size: small
        kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration
    spec:
      domain:
        devices:
          disks:
            - name: containerdisk
              disk:
                bus: virtio
          interfaces:
            - name: default
              masquerade: {}
        resources:
          requests:
            memory: 64M
      networks:
        - name: default
          pod: {}
      {{< onlyWhen tolerations >}}tolerations:
        - effect: NoSchedule
          key: baremetal
          operator: Equal
          value: "true"
      {{< /onlyWhen >}}volumes:
        - name: containerdisk
          containerDisk:
            image: {{% param "cirrosCDI" %}}
```
Apply it to the cluster to create the virtual machine.
and apply the manifest.

{{% details title="Task hint: apply command" %}}
```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/livemigration.yaml --namespace=$USER
```
{{% /details %}}

Start the virtual machine:

```bash
virtctl start {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER
```

Once the VM has started successfully execute the following command to get the node the VMI is running on:

```bash
kubectl get vmi --namespace=$USER
```

Which will result in:

```bash
NAME                   AGE    PHASE     IP              NODENAME                 READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration    45m    Running   10.244.6.103    training-baremetal-<x>   True
```

During the start up of the virtual machine, KubeVirt determines whether a VMI is live-migratable or not. The information can be found in the `status.conditions` section of the VMI resource.

```bash
kubectl get vmi {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER -o yaml
```

Should show:

```yaml
[...]
 conditions:
  - lastProbeTime: null
    lastTransitionTime: "2024-10-05T14:51:36Z"
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: null
    status: "True"
    type: LiveMigratable
[...]
```


## {{% task %}} Start a simple process in your VM

Create the following Kubernetes Service (file: `service-livemigration.yaml` folder: `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}`):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration
  type: ClusterIP
```

```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/service-livemigration.yaml --namespace=$USER
```

Open a console to the VM and login:

```bash
virtctl console {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER
```

Start the following command:

```bash
while true; do ( echo "HTTP/1.0 200 Ok"; echo; echo "Migration test" ) | nc -l -p 8080; done
```

Go back to the webshell and open a new Terminal to test the service

```bash
curl -s {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration.$USER.svc.cluster.local:8080
```


## {{% task %}} Perform a live migration

To perform a Live Migration we can simply create a `VirtualMachineInstanceMigration` resource on the cluster, referencing the VMI to migration.
Create a new file `livemigration-job.yaml` in the folder `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/` with the following content:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstanceMigration
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration-job
spec:
  vmiName: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration
```

{{% alert title="Note" color="info" %}}  
It's also possible to initiate a live migration of a VM by using `virtctl`

```bash
virtctl migrate {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER
```
{{% /alert %}}

And apply it to the cluster:

```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/livemigration-job.yaml --namespace=$USER
```

This will automatically perform the live migration. Use the following command to see the status of the migration:

```bash
kubectl get VirtualMachineInstanceMigration {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration-job -w --namespace=$USER
```

Once the migration was successful, the VMI should run on the other node. Use

```bash
kubectl get vmi {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER
```

to verify that.


Details about the migration state will be represented in the VMI or the corresponding `VirtualMachineInstanceMigration`

```bash
kubectl describe vmi {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER
```

or

```bash
kubectl get VirtualMachineInstanceMigration {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration-job -o yaml --namespace=$USER
```

To check on the migration status in the status section of the `VirtualMachineInstance`.

And verify the running simple webserver by executing

```bash
curl -s {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration.$USER.svc.cluster.local
```


## Cancel a live migration

This lab is not meant to be executed.

A live migration can also be canceled, by deleting the `VirtualMachineInstanceMigration` object

```bash
kubectl delete vmi {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration-job --namespace=$USER
```

or using `virtctl`

```bash
virtctl migrate-cancel {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER
```


A successfully canceled migration will show the following states:

* Abort Requested: true
* Abort Status: Succeeded
* Completed: true
* Failed: true


## Migration strategies

Live migration is a complex process. During migration, the entire state of the source VM (primarily its RAM) must be transferred to the target VM. When sufficient resources, such as network bandwidth and CPU power, are available, the migration should proceed smoothly. However, if resources are lacking, the migration may stall without making further progress.

A key factor influencing migration from the guest VM's perspective is its dirty rate—the rate at which the VM modifies memory. A high dirty rate creates a challenge, as memory is continuously transferred to the target while the guest simultaneously modifies it. In such cases, more advanced migration strategies may be needed.

The following 3 migration strategies are currently supported, and can be configured in the kubevirt configuration:


### Pre-copy

Pre-copy is the default strategy and works like this:

1. The target VM is created, but the guest keeps running on the source VM.
1. The source starts sending chunks of VM state (mostly memory) to the target. This continues until all of the state has been transferred to the target.
1. The guest starts executing on the target VM.
1. The source VM is being removed.

Pre-copy is generally the safest and fastest migration strategy in most scenarios. It supports multithreading, can be easily canceled, and works efficiently. If there's no strong reason to choose a different approach, pre-copy is typically the best option.

However, in some cases, migrations may struggle to converge. This means that by the time a portion of the source VM’s state reaches the target VM, it may have already been modified by the source VM (the one running the guest). Factors such as a high dirty rate or limited resources, like insufficient network bandwidth or CPU power, can cause this lack of convergence.


### Post-copy

Post-copy is the default strategy and works like this:

1. The target VM is created.
1. The guest is being run on the target VM.
1. The source starts sending chunks of VM state (mostly memory) to the target.
1. When the guest, running on the target VM, would access memory:
   * If the memory exists on the target VM, the guest can access it.
   * Otherwise, the target VM asks for a chunk of memory from the source VM.
1. Once all of the memory state is updated at the target VM, the source VM is being removed.

The main idea is, that the VM starts immediately, there are some pros and cons on this strategy:

Pros:

* With post-copy migration, the same memory chunk is never transferred more than once because the guest is already running on the target VM, making it irrelevant if a page gets modified.
* As a result, a high dirty rate has significantly less impact.
* It also uses less network bandwidth.


Cons:

* In post-copy migration, the VM state has not one source of truth. While the guest running on the target VM writes to memory, some parts of the state may still reside on the source VM. This creates a risky situation, as the VM state may become unrecoverable if either the target or source VM crashes.
* Post-copy also has a slow warm-up phase, as no memory is initially available on the target VM. The guest must wait for a significant amount of memory to be transferred in a short time.
* Additionally, post-copy is generally slower than pre-copy in most cases
* and more difficult to cancel once the migration starts.


### Auto-converge

Auto-converge is a technique designed to accelerate the convergence of pre-copy migrations without altering the fundamental migration process.

Since a high dirty rate is often the primary reason migrations fail to converge, auto-converge addresses this by throttling the guest’s CPU. If the migration is progressing quickly enough, the CPU is either not throttled or only minimally. However, if the migration lags, the CPU throttling increases over time.

This approach significantly boosts the likelihood that the migration will eventually succeed.


## Migration networks

It is possible and also reasonable for production setups to use separate networks for:

* Workload Network Traffic
* Migration Network Traffic

This will reduce the risk of unwanted side effects during live migrations.

A dedicated physical network is necessary, meaning each node in the cluster must have at least two NICs. The NICs designated for migrations need to be interconnected, they must all be connected to the same switch. In the examples below, eth1 is assumed to handle migrations.

Additionally, the Kubernetes cluster must have multus installed.

The following `NetworkAttachmentDefinition` definition configures the `migration-network` and needs to be created in the `kubevirt` namespace.

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: migration-network
  namespace: kubevirt
spec:
  config: '{
      "cniVersion": "0.3.1",
      "name": "migration-bridge",
      "type": "macvlan",
      "master": "eth1",
      "mode": "bridge",
      "ipam": {
        "type": "whereabouts",
        "range": "10.1.1.0/24"
      }
    }'
```

To configure KubeVirt to migrate the `VirtualMachineInstances` over that network, we need to adopt the migrations configuration in the `kubevirt` manifest.

```yaml
apiVersion: kubevirt.io/v1
kind: Kubevirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
      [...]
      - LiveMigration
    migrations:
      network: migration-network
[...]
```


## {{% task %}} (optional) perform migrations using the kubevirt command

Let's use the `kubevirt migrate` to perform an additional migration. Follow the migration with the commands we've used in the lab above.
Try to cancel a live migration, and verify it in the status section of the VMI manifest.


## {{% task %}} (optional) migration policies

In addition to the cluster wide configuration of the LiveMigration feature the concept of [Migration Policies](https://kubevirt.io/user-guide/cluster_admin/migration_policies/) was introduced. Migration policies are currently (v1.30) an alpha feature and the API might not be stable.

Explore the official documentation under <https://kubevirt.io/user-guide/cluster_admin/migration_policies/>


## End of lab

{{% alert title="Cleanup resources" color="warning" %}}  {{% param "end-of-lab-text" %}}

Stop the `VirtualMachineInstance`:

```bash
virtctl stop {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER
```
{{% /alert %}}
