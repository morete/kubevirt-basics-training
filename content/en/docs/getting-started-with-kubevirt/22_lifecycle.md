---
title: "2.2 Start and Stop a VM"
weight: 220
labfoldernumber: "02"
sectionnumber: 2.2
description: >
  Start & Stop your VirtualMachine using kubectl or virtctl
---

In the previous section we have written our VirtualMachine specification and have applied the manifest to the kubernetes cluster.


## Lifecycle

When the underlying technology `libvirt` refers to a VM it often also uses the concept of guest domains.

According to [libvirt.org](https://wiki.libvirt.org/VM_lifecycle.html) a guest domain can be in several states:

1. **Undefined** - This is a baseline state. Libvirt does not know anything about domains in this state because the domain hasn't been defined or created yet.
2. **Defined** or **Stopped** - The domain has been defined, but it's not running. This state is also called stopped. Only persistent domains can be in this state. When a transient domain is stopped or shutdown, it ceases to exist.
3. **Running** - The domain has been created and started either as transient or persistent domain. Either domain in this state is being actively executed on the node's hypervisor.
4. **Paused** - The domain execution on hypervisor has been suspended. Its state has been temporarily stored until it is resumed. The domain does not have any knowledge whether it was paused or not. If you are familiar with processes in operating systems, this is the similar.
5. **Saved** - Similar to the paused state, but the domain state is stored to persistent storage. Again, the domain in this state can be restored and it does not notice that any time has passed.

![VM Lifecycle](../vm_lifecycle_graph.png)

{{% alert title="Note" color="info" %}}
In this section we will have a look how to use the states `Running`, `Stopped (Defined)` and `Paused`.
{{% /alert %}}


## List your VirtualMachines

Since you created the VirtualMachine in the previous section you may verify the creation with:

```shell
kubectl get virtualmachine --namespace=$USER
```

You should see your virtual machines listed as following:

```shell
NAME            AGE   STATUS    READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm   10m   Stopped   False
```

This indicated that the VM has been created but is still in a stopped state.

{{% alert title="Note" color="info" %}}
In kubernetes the resource `VirtualMachine` has a shortname `vm`. Therefore, the following command is equivalent to the one above:

```shell
kubectl get vm --namespace=$USER
```

From now on we will use the shortname `vm`.

You can list all shortnames with:

```shell
kubectl api-resources
```
{{% /alert %}}


## {{% task %}} Working with your VMs

There are two ways of starting and stopping your VirtualMachine. You can patch your VirtualMachine resource with `kubectl` or use `virtctl` to
start the VM. Try starting and stopping your VM with both methods.


### Start/Stop with Kubectl

Your VirtualMachine resource contains a field `spec.running` which indicated the desired state of the VM. You can check
the resource with:

```shell
kubectl describe vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

Alternatively you can also directly select the relevant field using a jsonpath:

```shell
kubectl get vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm -o jsonpath='{.spec.running}' --namespace=$USER
```

{{% alert title="Note" color="info" %}}
With `kubectl` all you have to do to start and stop your VM is patching the field `spec.running`.
{{% /alert %}}

Use the following command to start your vm:

```shell
kubectl patch vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --type merge -p '{"spec":{"running":true}}' --namespace=$USER
```

the output should be:

```shell
virtualmachine.kubevirt.io/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm patched
```

Now check the state of your vm again:

```shell
kubectl get vm --namespace=$USER
```

You should see that the VM is now in a Running state:

```shell
NAME            AGE   STATUS    READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm   11m   Running   True
```

Stopping the VM is similar to starting. Just set `spec.running` back to `false`:
```shell
kubectl patch vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --type merge -p '{"spec":{"running":false}}' --namespace=$USER
```

The output should again be:

```shell
virtualmachine.kubevirt.io/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm patched
```

{{% alert title="Note" color="info" %}}
The process of starting and stopping VMs takes a bit of time. Make sure the VM is in status Stopped, before you start it again.
{{% /alert %}}


### Start/Stop with Virtctl

The binary `virtctl` provides an easier way of interacting with KubeVirt VMs.

Start your VM with:
```shell
virtctl start {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

The output should be:

```shell
VM {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm was scheduled to start
```

If you check the state of your VM you'll see that it had the same effect as using the `kubectl` command:

```shell
kubectl get vm --namespace=$USER
```

Your VM is in the Running state:

```shell
NAME            AGE   STATUS    READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm   11m   Running   True
```

For stopping your VM simply use
```shell
virtctl stop {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

The output should be:

```shell
VM {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm was scheduled to stop
```


### Pause a VirtualMachine with Virtctl

Pausing a VM is as simple as:
```shell
virtctl pause vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```
Will result in an error:

```shell
Error pausing VirtualMachineInstance lab02-firstvm. VirtualMachine lab02-firstvm is not set to run
```

Obviously we can not pause a **stopped** VM, so start the VM and try the pause command again:

```shell
virtctl start {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

Make sure the VM is in the started status before you pause it, by checking with the following command `kubectl get vm --namespace=$USER`

```shell
virtctl pause vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```


The output should be:

```shell
VMI {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm was scheduled to pause
```

Again verify the state of the VM

```shell
kubectl get vm --namespace=$USER
```


Resuming a VM can be done with:
```shell
virtctl unpause vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

The output should be:

```shell
VMI {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm was scheduled to unpause
```


## Involved Components

When your VM is in a `running` state you may have noticed that there is an additional pod running. Make sure your VM is
running and issue the following command:

```shell
kubectl get pods --namespace=$USER
```

The output will be similar to:
```shell
NAME                                READY   STATUS    RESTARTS   AGE
$USER-webshell-885dbc579-lwhtd      2/2     Running   0          1d
virt-launcher-{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm-mfxrs   3/3     Running   0          90s
```

For each running VM there is a `virt-launcher` pod which is responsible to start the effective VM process in the container and observes the VM state.

Beside the existence of the `virt-launcher` pod a new custom resource `VirtualMachineInstance` is present. This resource is
created under the hood by the `virt-controller` and will only be available as long as the VM is running. It represents a
single running virtual machine instance.

You may see your `VirtualMachineInstance` with the following command:

```shell
kubectl get vmi --namespace=$USER
```

{{% alert title="Note" color="info" %}}
Remember that `vmi` is the shortname for `VirtualMachineInstance` just like `vm` for `VirtualMachine`.
{{% /alert %}}

The output will be similar to:
```shell
NAME            AGE     PHASE     IP             NODENAME            READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm   3m59s   Running   10.244.3.144   training-worker-0   True
```

This indicates that our {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm is running on the kubernetes node `training-worker-0`

{{% alert title="Note" color="info" %}}
You may use `-o wide` to get more details about the VM.

```shell
kubectl get vmi -o wide --namespace=$USER
```

With `wide` you can see if your VM is Live-Migratable or is currently in a paused state.

The output of a paused VM will be:

```shell
NAME           AGE     PHASE     IP             NODENAME            READY   LIVE-MIGRATABLE   PAUSED
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm  7m52s   Running   10.244.3.144   training-worker-0   False   True              True
```
{{% /alert %}}


## {{% task %}} (Optional) Under the hood: Explore virt-launcher Pod

In this optional Lab we're going to explore the virt-launcher Pod, which we discovered in the previous lab.

For every `VirtualMachineInstance` or `VMI` (running VM) one virt-launcher pod is created. The virt-launcher pod provides boundaries (cgoups, namespaces), the interface to the Kubernetes ecosystem and manages and monitors the lifecycle of the VMI.

In its core, the virt-launcher pod runs a `libvirtd` instance, which manages the lifecycle of the VMI process.

With the following command, we can have a look at the pod manifest(replace the `<pod>` with the actual pod `kubectl get pods --namespace=$USER`):

```shell
kubectl get pod virt-launcher-lab02-firstvm-<pod> -o yaml --namespace=$USER
```

or simply use the describe command

```shell
kubectl describe pod virt-launcher-lab02-firstvm-<pod> --namespace=$USER
```

Explore the pod yaml or use the describe command:

* Labels
* ownerReference
* init containers and containers
  * container-disk-binary
  * volumecontainerdisk-init
  * compute
  * volumecontainerdisk
  * guest-console-log
* resource limits abd requests
* volumes and mounts
* status

You can even exec into the Pod and list the running processes, where you can find the running libvirt, qemu-kvm, processes

```shell
kubectl exec --stdin --tty --namespace=$USER virt-launcher-lab02-firstvm-<pod> -- /bin/bash
```

```shell
ps -ef
```

Press `CTRL + d` or type `exit` to exit the shell of the pod again.


{{% alert title="Note" color="info" %}}
This does not connect to a shell withing the `VirtualMachineInstance` but a shell into the pod which is managing the `VirtualMachineInstance`.

Connecting into the shell of a `VirtualMachineInstance` will be explained in the next Lab.
{{% /alert %}}
