---
title: "Guest Agent"
weight: 81
labfoldernumber: "08"
description: >
  Guest Agent is an optional component that can run inside of Virtual Machines to provide plenty of additional runtime information.
---

In many of the available cloud images the `qemu-guest-agent` package is already installed. In case, it's not preinstalled you can use one of the previously learned concept to install the package.


## {{% task %}} Start a virtual machine and explore Guest Agent information

In this lab we're going to reuse the virtual machine, we created in the {{<link "cloud-init">}}.

Start the `cloud-init` virtual machine using the following command:

```bash
virtctl start {{% param "labsubfolderprefix" %}}04-cloudinit --namespace=$USER
```

The presence of the Guest Agent in the virtual machine is indicated by a condition in the `VirtualMachineInstance` status. This condition shows that the Guest Agent is connected and ready for use.

As soon as the virtual machine has started successfully (`kubectl get vm {{% param "labsubfolderprefix" %}}04-cloudinit --namespace=$USER` STATUS `Running`) we can use the following command to display the `VirtualMachineInstance` object.

```bash
kubectl get vmi {{% param "labsubfolderprefix" %}}04-cloudinit -o yaml --namespace=$USER
```

or

```bash
kubectl describe vmi {{% param "labsubfolderprefix" %}}04-cloudinit --namespace=$USER
```

Check the `status.conditions` and verify whether the `AgentConnected` condition is `True`

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

In case the guest agent has been able to be connected successfully, there will be additional OS information shown in the status of the `VirtualMachineInstance` as for example:

* `status.guestOSInfo:`, which contains OS runtime data
* `status.interfaces:` info, which shows QEMU interfaces merged with guest agent interfaces info.

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


## {{% task %}} Guest Agent information through virtctl

In addition to the `status` section in the `VirtualMachineInstance` it's also possible to get additional information from the Guest Agent via `virtctl` or directly using the kube-api.


Use the following commands to get the information using the `virtctl`

```bash
virtctl guestosinfo {{% param "labsubfolderprefix" %}}04-cloudinit --namespace=$USER
```

The `guestosinfo` command will return the whole Guest Agent data.


If you're only interested in the `userlist` or `filesystemlist` you can execute the following commands:

```bash
virtctl userlist {{% param "labsubfolderprefix" %}}04-cloudinit --namespace=$USER
```

```bash
virtctl fslist {{% param "labsubfolderprefix" %}}04-cloudinit --namespace=$USER
```

The full `QEMU Guest Agent Protocol Reference` can be found under this link <https://qemu.weilnetz.de/doc/3.1/qemu-ga-ref.html>


## End of lab

The Guest Agent information is a neat way to find out more information about your running virtual machines and to monitor your workload.

{{% alert title="Cleanup resources" color="warning" %}}  {{% param "end-of-lab-text" %}}

Stop the `VirtualMachineInstance` again:

```bash
virtctl stop {{% param "labsubfolderprefix" %}}04-cloudinit --namespace=$USER
```
{{% /alert %}}
