---
title: "Start and stop a VM"
weight: 12
labfoldernumber: "01"
description: >
  Start and stop your virtual machine using kubectl and virtctl
---

In the previous section, we wrote a VirtualMachine specification and applied the manifest to the Kubernetes cluster.


## Lifecycle

When the underlying technology `libvirt` refers to a VM it often also uses the concept of so-called _guest domains_.

According to [libvirt.org](https://wiki.libvirt.org/VM_lifecycle.html), a guest domain can be in several states:

1. **Undefined**: This is a baseline state. Libvirt does not know anything about domains in this state because the domain hasn't been defined or created yet.
2. **Defined** or **Stopped**: The domain has been defined but it's not running. This state is also called stopped. Only persistent domains can be in this state. When a transient domain is stopped or shut down, it ceases to exist.
3. **Running**: The domain has been created and started either as transient or persistent domain. Either domain in this state is being actively executed on the node's hypervisor.
4. **Paused**: The domain execution on the hypervisor has been suspended. Its state has been temporarily stored until it is resumed. The domain does not have any knowledge whether it was paused or not.
5. **Saved**: Similar to the paused state, but the domain state is stored to persistent storage. Again, the domain in this state can be restored and it does not notice that any time has passed.

![VM Lifecycle](../vm_lifecycle_graph.png)

{{% alert title="Note" color="info" %}}
In this section we will have a look how to use the states `Running`, `Stopped (Defined)` and `Paused`.
{{% /alert %}}


## List your virtual machines

Since you created the VirtualMachine resource in the previous section you may verify its creation with:

```bash
kubectl get virtualmachine --namespace=$USER
```

You should see your virtual machines listed as follows:

```bash
NAME            AGE   STATUS    READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm   10m   Stopped   False
```

This indicated that the VM has been created but is still in a stopped state.

{{% alert title="Note" color="info" %}}
In Kubernetes, the resource `VirtualMachine` has a shortname `vm`. Therefore, the following command is equivalent to the one above:

```bash
kubectl get vm --namespace=$USER
```
{{% /alert %}}


## {{% task %}} Working with your VMs

There are two ways of starting and stopping your virtual machines. You can patch your VirtualMachine resource with `kubectl` or use `virtctl` to
start the VM. Try starting and stopping your VM with both methods.


### Start VM with kubectl

Your VirtualMachine resource contains a field `spec.running` which indicates the desired state of the VM. You can check
the resource with:

```bash
kubectl describe vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

Alternatively you can directly select the relevant field using a jsonpath:

```bash
kubectl get vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm -o jsonpath='{.spec.running}' --namespace=$USER
```

{{% alert title="Note" color="info" %}}
With `kubectl` all you have to do to start and stop your VM is patching the field `spec.running`.
{{% /alert %}}

Use the following command to start your VM:

```bash
kubectl patch vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --type merge -p '{"spec":{"running":true}}' --namespace=$USER
```

The output should be:

```bash
virtualmachine.kubevirt.io/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm patched
```

Now check the state of your VM again:

```bash
kubectl get vm --namespace=$USER
```

You should see that the VM is now in `Running` state right, wait what it's `ErrorUnschedulable`?

```bash
NAME            AGE     STATUS               READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm   2m15s   ErrorUnschedulable   False
```

Our `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm` has not been able to get scheduled.

The reason for that is simple:

Use `kubectl describe vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER` to find the reason under `status`.

```bash
[...]
Status:
  Conditions:
    Last Probe Time:       <date>
    Last Transition Time:  <date>
    Message:               Guest VM is not reported as running
    Reason:                GuestNotRunning
    Status:                False
    Type:                  Ready
    Last Probe Time:       <nil>
    Last Transition Time:  2024-09-24T13:20:15Z
    Message:               0/7 nodes are available: 1 node(s) had untolerated taint {baremetal: true}, 3 Insufficient devices.kubevirt.io/kvm, 3 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: true}. preemption: 0/7 nodes are available: 3 No preemption victims found for incoming pod, 4 Preemption is not helpful for scheduling.
    Reason:                Unschedulable
    Status:                False
    Type:                  PodScheduled
[...]
```

With the current configuration there is no node available to run our VirtualMachine.

Our Lab Setup consist out of:

* 3 control plane nodes (virtual machines)
* multiple worker nodes (virtual machines) to run the lab infrastructure
* multiple baremetal nodes to run our kubevirt VMs

Our baremetal nodes (labels: `baremetal: true`) are tainted, to make sure that only VM Workload runs on those specific nodes.

Find out more about Taints and Tolerations in the official [documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/).

Therefore, to run our VirtualMachines we need to specify a so called `toleration` in our Virtual Machnie Manifest, to make sure the VM gets scheduled on the correct node.


### Define toleration on the VirtualMachine

Add the following `toleration` to the VM Manifest (`firstvm.yaml`):

```yaml
[...]
      tolerations:
        - effect: NoSchedule
          key: baremetal
          operator: Equal
          value: "true"
[...]
```

{{% details title="Task hint: Resulting yaml" %}}
Your VirtualMachine definition should look like this:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/size: small
        kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm
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
      tolerations:
        - effect: NoSchedule
          key: baremetal
          operator: Equal
          value: "true"
      volumes:
        - name: containerdisk
          containerDisk:
            image: {{% param "cirrosCDI" %}}
```
{{% /details %}}

And apply the changes again with:

```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/firstvm.yaml --namespace=$USER
```


### Start/stop with kubectl again

Use the following command to start your VM:

```bash
kubectl patch vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --type merge -p '{"spec":{"running":true}}' --namespace=$USER
```

The output should be:

```bash
virtualmachine.kubevirt.io/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm patched
```

Now check the state of your VM again:

```bash
kubectl get vm --namespace=$USER
```

You should see that the VM is now in `Running` state:

```bash
NAME            AGE   STATUS    READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm   11m   Running   True
```



Stopping the VM is similar to starting. Just set `spec.running` back to `false`:

```bash
kubectl patch vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --type merge -p '{"spec":{"running":false}}' --namespace=$USER
```

The output should again be:

```bash
virtualmachine.kubevirt.io/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm patched
```

{{% alert title="Note" color="info" %}}
The process of starting and stopping VMs takes a bit of time. Make sure the VM is in status `Stopped` before you start it again.
{{% /alert %}}


### Start/stop with `virtctl`

The binary `virtctl` provides an easier way of interacting with KubeVirt VMs.

Start your VM with:

```bash
virtctl start {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

The output should be:

```bash
VM {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm was scheduled to start
```

If you check the state of your VM you'll see that it had the same effect as using the `kubectl` command:

```bash
kubectl get vm --namespace=$USER
```

Your VM is in `Running` state:

```bash
NAME            AGE   STATUS    READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm   11m   Running   True
```

To stop your VM, simply use:

```bash
virtctl stop {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

The output should be:

```bash
VM {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm was scheduled to stop
```


### Pause a VirtualMachine with `virtctl`

Pausing a VM is as simple as:

```bash
virtctl pause vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

However, if you try to execute above command, it will result in an error:

```bash
Error pausing VirtualMachineInstance lab02-firstvm. VirtualMachine lab02-firstvm is not set to run
```

Obviously we can not pause a stopped VM, so start the VM first and then try the pause command again:

```bash
virtctl start {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

Make sure the VM shows it has started before you pause it:

```bash
kubectl get vm --namespace=$USER
```

Now pause it:

```bash
virtctl pause vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

The output should be:

```bash
VMI {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm was scheduled to pause
```

Again, verify the state of the VM:

```bash
kubectl get vm --namespace=$USER
```

Resuming a VM can be done with:

```bash
virtctl unpause vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

The output should be:

```bash
VMI {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm was scheduled to unpause
```


## Involved components

When your VM is in a running state, you may have noticed that there is an additional Pod running. Make sure your VM is
running and issue the following command:

```bash
kubectl get pods --namespace=$USER
```

The output will be similar to:

```bash
NAME                                READY   STATUS    RESTARTS   AGE
$USER-webshell-885dbc579-lwhtd      2/2     Running   0          1d
virt-launcher-{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm-mfxrs   3/3     Running   0          90s
```

For each running VM there is a `virt-launcher` Pod which is responsible to start the effective VM process in the container and observes the VM state.

Beside the existence of the `virt-launcher` Pod, a new custom resource `VirtualMachineInstance` is present. This resource is
created under the hood by the `virt-controller` and will only be available as long as the VM is running. It represents a
single running virtual machine instance.

You may see your `VirtualMachineInstance` with the following command:

```bash
kubectl get vmi --namespace=$USER
```

{{% alert title="Note" color="info" %}}
Note that `vmi` is the shortname for `VirtualMachineInstance` just like `vm` for `VirtualMachine`.
{{% /alert %}}

The output will be similar to:

```bash
NAME            AGE     PHASE     IP             NODENAME               READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm   3m59s   Running   10.244.3.144   training-baremetal-0   True
```

Above output also indicates that our {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm is running on Kubernetes node `training-baremetal-0`.

{{% alert title="Note" color="info" %}}
You may use `-o wide` to get more details about the VM.

```bash
kubectl get vmi -o wide --namespace=$USER
```

With `wide` you can see if your VM is live-migratable or is currently in a paused state.

The output of a paused VM will be:

```bash
NAME           AGE     PHASE     IP             NODENAME            READY   LIVE-MIGRATABLE   PAUSED
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm  7m52s   Running   10.244.3.144   training-worker-0   True    True              
```
{{% /alert %}}


## {{% task %}} (Optional) Under the hood: Explore the virt-launcher Pod

In this optional lab we are going to explore the virt-launcher Pod, which we discovered in the previous task.

For every `VirtualMachineInstance` or `VMI` (running VM), one virt-launcher Pod is created. The virt-launcher Pod provides boundaries (cgoups, namespaces), the interface to the Kubernetes ecosystem and manages and monitors the lifecycle of the VMI.

In its core, the virt-launcher Pod runs a `libvirtd` instance, which manages the lifecycle of the VMI process.

With the following command, we can have a look at the Pod's manifest (replace the Pod name with the actual Pod's name from `kubectl get pods --namespace=$USER`):

```bash
kubectl get pod virt-launcher-{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm-<pod> -o yaml --namespace=$USER
```

Or simply use the describe command:

```bash
kubectl describe pod virt-launcher-{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm-<pod> --namespace=$USER
```

Explore the Pod definition or use the describe command:

* `labels`
* `ownerReference`
* `initContainers` and `containers`
  * `container-disk-binary`
  * `volumecontainerdisk-init`
  * `compute`
  * `volumecontainerdisk`
  * `guest-console-log`
* `limits` and `requests`
* `volumes` and `volumeMounts`
* `status`

You can even exec into the Pod and list the running processes, where you can find the running libvirt and qemu-kvm processes:

```bash
kubectl exec --stdin --tty --namespace=$USER virt-launcher-{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm-<pod> -- /bin/bash
```

```bash
ps -ef
```

Press `CTRL + d` or type `exit` to exit the shell of the pod again.

{{% alert title="Note" color="info" %}}
This does not connect to a shell within the `VirtualMachineInstance` but to the pod which is managing the `VirtualMachineInstance`.

Connecting to the shell of a `VirtualMachineInstance` will be explained in the next lab.
{{% /alert %}}
