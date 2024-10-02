---
title: "Re-assign an instance type"
weight: 34
labfoldernumber: "03"
description: >
  Re-assign an instance type to your VM
---

In this section we will change the instance type of our running VMs to our newly created instance type.


## Changing an instance type

Whenever a VM referencing an instance type or preference is created, the definition at time of creation is stored in a `ControllerRevision`. This revision is then referenced in a new field `.spec.instancetype.revisionName` in our VM manifest.

This field ensures that our VirtualMachine knows the original specification even when the type or preference would change. This ensures that there are no accidental changes to the VM resources or preferences.

Use the following command to display the VM resource. You will find the reference to the revision under `spec.instancetype.revisionName`:

```bash
kubectl get vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros -o yaml --namespace=$USER
```

Example of a VM with a `revisionName`:

```yaml
[...]
spec:
  instancetype:
    kind: VirtualMachineClusterInstancetype
    name: u1.nano
    revisionName: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros-u1.nano-v1beta1-e15b4047-3ff9-4308-9cd7-9f30b25336e0-1
[...]
```

Use the following command to list all available `controllerrevision` resources:

```bash
kubectl get controllerrevision --namespace=$USER
```

```
NAME                                                                                     CONTROLLER                                   REVISION   AGE
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros-cirros-v1beta1-fa1da1cd-7e10-4e89-a8ac-5bded8f7129e-1                    virtualmachine.kubevirt.io/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros   0          2h
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros-cirros-v1beta1-fa1da1cd-7e10-4e89-a8ac-5bded8f7129e-1                    virtualmachine.kubevirt.io/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros   0          2h
[...]
```

If we want to explicitly change the instance type or preference, we have to remove the `revisionName` attribute completely, otherwise it will reject the change with the following message:

```bash
The request is invalid: spec.instancetype.revisionName: the Matcher Name has been updated without updating the RevisionName
```

If we want to change the instance type in the resource and reapply the changes using `kubectl apply -f` we need to set the `revisionName` set to `null`:

```yaml
[...]
spec:
  instancetype:
    kind: VirtualMachineClusterInstancetype
    name: u1.nano
    revisionName: null
[...]
```

When editing the resource directly, we can simply remove the `revisionName`:

```bash
kubectl edit vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros --namespace=$USER
```

Or alternatively, patch the resource using:

```bash
kubectl patch vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros --type merge --patch '{"spec":{"instancetype":{"kind":"<KIND>","name":"<NAME>","revisionName":null}}}' --namespace=$USER
```


## {{% task %}} Adapt your VMs to use the new instance type

Change the instance types of the two VMs from the current VirtualMachineClusterInstancetype (`u1.nano`) to instance type (`{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-pico` and `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-pico`)

* `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros`
* `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros`

Use one of the mentioned methods above to change the resource.

{{% alert title="Note" color="info" %}}
Since so far we were referencing a `VirtualMachineClusterPreference`, also change the kind to `VirtualMachineInstancetype` for our new instance types.
And don't forget to remove the referenced `revisionName`.
{{% /alert %}}


{{% details title="Task Hint" %}}
The relevant section for the VM `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros` should look like this:

```yaml
spec:
  instancetype:
    kind: VirtualMachineInstancetype
    name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-pico
```

For `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros` it will be:

```yaml
spec:
  instancetype:
    kind: VirtualMachineInstancetype
    name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-pico
```

{{% /details %}}

Make sure you restart both VMs to reflect the changes to their instance type:

```bash
virtctl restart {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros --namespace=$USER
virtctl restart {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros --namespace=$USER
```

Verify whether the two VMIs are running again properly:

```bash
kubectl get vmi --namespace=$USER
```

Describe both VirtualMachine instances and observe the effect:

```bash
kubectl get vmi {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros -o yaml --namespace=$USER
```

```bash
kubectl get vmi {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros -o yaml --namespace=$USER
```

The `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros` instance:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros
spec:
  domain:
    resources:
      requests:
        memory: 256Mi
    memory:
      guest: 256Mi
[...]
```

`{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros` instance:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros
spec:
  domain:
    resources:
      requests:
        memory: 192Mi
    memory:
      guest: 256Mi
[...]
```


## End of lab

{{% alert title="Cleanup resources" color="warning" %}}  {{% param "end-of-lab-text" %}}

Stop your running VM with:

```bash
virtctl stop {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros --namespace=$USER
virtctl stop {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros --namespace=$USER
```
{{% /alert %}}
