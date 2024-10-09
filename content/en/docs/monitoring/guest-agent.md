---
title: "Guest agent"
weight: 81
labfoldernumber: "08"
description: >
  The guest agent is an optional component that can run inside of virtual vachines to provide additional runtime information
---

In many of the available cloud images, the `qemu-guest-agent` package is already installed. If it's not preinstalled you can use one of the previously learned concepts to install the package.


## {{% task %}} Start a virtual machine and explore guest agent information

In this lab we are going to reuse the virtual machine we created in the {{<link "cloud-init">}} lab.

Start the `cloud-init` virtual machine using the following command:

```bash
virtctl start {{% param "labsubfolderprefix" %}}04-cloudinit --namespace=$USER
```

The presence of the guest agent in the virtual machine is indicated by a condition in the VirtualMachineInstance's status. This condition shows that the guest agent is connected and ready for use.

As soon as the virtual machine has started successfully (`kubectl get vm {{% param "labsubfolderprefix" %}}04-cloudinit --namespace=$USER` STATUS `Running`) we can use the following command to display the VirtualMachineInstance object, either looking at its definition:

```bash
kubectl get vmi {{% param "labsubfolderprefix" %}}04-cloudinit -o yaml --namespace=$USER
```

Or by describing the resource:

```bash
kubectl describe vmi {{% param "labsubfolderprefix" %}}04-cloudinit --namespace=$USER
```

Check the `status.conditions` and verify whether the `AgentConnected` condition is `True`:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
[...]
spec:
[...]
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2024-10-05T12:02:40Z"
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: null
    status: "True"
    type: LiveMigratable
  - lastProbeTime: "2024-10-05T12:02:56Z"
    lastTransitionTime: null
    status: "True"
    type: AgentConnected
[...]
```

In case the guest agent could connect successfully, there will be additional operating system information shown in the VirtualMachineInstance resource's status, such as:

* `status.guestOSInfo` - Contains operating system runtime data
* `status.interfaces` - Shows QEMU interfaces merged with guest agent interfaces data

Explore the additional information.

```yaml
status:
  [...]
  guestOSInfo:
    id: fedora
    [...]
  interfaces:
    [...]
```


## {{% task %}} Guest agent information through `virtctl`

In addition to the `status` section in the VirtualMachineInstance resource, it's also possible to get additional information from the guest agent via `virtctl`.

Use the following commands to get the information using `virtctl`:

```bash
virtctl guestosinfo {{% param "labsubfolderprefix" %}}04-cloudinit --namespace=$USER
```

The `guestosinfo` sub-command will return the whole guest agent data.

If you're only interested in the `userlist` or `filesystemlist` data, you can execute the following commands:

```bash
virtctl userlist {{% param "labsubfolderprefix" %}}04-cloudinit --namespace=$USER
```

```bash
virtctl fslist {{% param "labsubfolderprefix" %}}04-cloudinit --namespace=$USER
```

The full QEMU guest agent protocol reference can be found at <https://qemu.weilnetz.de/doc/3.1/qemu-ga-ref.html>.


## End of lab

The guest agent information is a neat way to find out more about your running virtual machines and to monitor your workload.

{{% alert title="Cleanup resources" color="warning" %}} {{% param "end-of-lab-text" %}}

Stop the VirtualMachineInstance again:

```bash
virtctl stop {{% param "labsubfolderprefix" %}}04-cloudinit --namespace=$USER
```
{{% /alert %}}
