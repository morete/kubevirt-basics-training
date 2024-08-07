---
title: "2.2 VM Lifecycle"
weight: 220
labfoldernumber: "02"
sectionnumber: 2.2
description: >
  Start & Stop your VirtualMachine using kubectl or virtctl
---


## List your VirtualMachine

In the previous section we have written our VirtualMachine specification and have applied the manifest to the kubernetes cluster.

You may verify the creation with

```shell
kubectl get virtualmachine
```

The output should be as follows:

```text
NAME            AGE   STATUS    READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm   10m   Stopped   False
```

This indicated that the vm has been created but is still in a stopped state.

{{% alert title="Note" color="info" %}}
In kubernetes the resource `VirtualMachine` has a shortname `vm`. Therefore, the following command is equivalent to the one above:

```shell
kubectl get vm
```

From now on we will use the shortname `vm`.

You can list all shortnames with:

```shell
kubectl api-resources
```
{{% /alert %}}


## {{% task %}} Start your VirtualMachine

There are two ways of starting your VirtualMachine. You can patch your VirtualMachine resource with `kubectl` or use `virtctl` to
start the VM. Try starting and stopping your VM with both methods.


### Using Kubectl

Your VirtualMachine resource contains a field `spec.running` which indicated the desired state of the VM. You can check
the resource with:

```shell
kubectl describe vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm
```

Alternatively you can also directly select the relevant field using a jsonpath:

```shell
kubectl get vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm -o jsonpath='{.spec.running}'
```

{{% alert title="Note" color="info" %}}
With `kubectl` all you have to do to start and stop your VM is patching the field `spec.running`.
{{% /alert %}}

Use the following command to start your vm:

```shell
kubectl patch vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --type merge -p '{"spec":{"running":true}}'
```

the output should be:

```shell
virtualmachine.kubevirt.io/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm patched
```

Now check the state of your vm again:

```shell
kubectl get vm
```

You should see that the VM is now in a Running state:

```shell
NAME            AGE   STATUS    READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm   11m   Running   True
```

Stopping the VM is similar to starting. Just set `spec.running` back to `false`:
```shell
kubectl patch vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --type merge -p '{"spec":{"running":false}}'
```

The output should again be:

```shell
virtualmachine.kubevirt.io/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm patched
```


### Using virtctl

The binary `virtctl` provides an easier way of interacting with KubeVirt VMs.

Start your VM with:
```shell
virtctl start {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm
```

The output should be:

```shell
VM lab02-firstvm was scheduled to start
```

If you check the state of your VM you'll see that it had the same effect as using the `kubectl` command:

```shell
kubectl get vm
```

Your VM is in the Running state:

```shell
NAME            AGE   STATUS    READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm   11m   Running   True
```

For stopping your VM simply use
```shell
virtctl stop {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm
```

The output should be:

```shell
VM lab02-firstvm was scheduled to stop
```


### Involved Components

When your VM is in a `running` state you may have noticed that there is an additional pod running. Make sure your VM is
running and issue the following command:

```shell
kubectl get pods
```

The output will be similar to:
```shell
NAME                                READY   STATUS    RESTARTS   AGE
$USER-webshell-885dbc579-lwhtd      2/2     Running   0          1d
virt-launcher-lab02-firstvm-mfxrs   3/3     Running   0          90s
```

For each running VM there is a `virt-launcher` pod which is responsible to start the effective VM process in the
container and observes the VM state.

Beside the existence of the `virt-launcher` pod a new custom resource `VirtualMachineInstance` is present. This resource is
created under the hood by the `virt-controller` and will only be available as long as the VM is running. It represents a
single running virtual machine instance.

You may see your `VirtualMachineInstance` with the following command:

```shell
kubectl get vmi 
```

{{% alert title="Note" color="info" %}}
Remember that `vmi` is the shortname for `VirtualMachineInstance` just like `vm` for `VirtualMachine`.
{{% /alert %}}

