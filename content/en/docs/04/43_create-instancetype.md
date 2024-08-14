---
title: "4.3 Create an Instancetype"
weight: 430
labfoldernumber: "04"
sectionnumber: 4.3
description: >
  Create your own Instance type and Preference
---

In this section we will create and use our own instance type.


## {{% task %}} Create your own Instancetype

In the previous section we have seen that the cirros preference requests 256Mi of memory. However, the smallest Instancetype
available requested 512Mi of memory. Let's create our own Instancetype and assign it to our VirtualMachines.

Create a file `vmf_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-pico.yaml` and start with the
definition of the `o1.nano` instancetype.

Define the Instancetype:

* Request 256Mi of memory
* Reduce the overcommit percentage from 50% to 25%
* Name the resource `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-pico`.

{{% details title="Task Hint" %}}
Your Instancetype should look like this (labels and annotations are optional):
```ỳaml
apiVersion: instancetype.kubevirt.io/v1beta1
kind: VirtualMachineInstancetype
metadata:
  name: lab04-o1-pico
  annotations:
    instancetype.kubevirt.io/description: |-
      The O Series is based on the U Series, with the only difference
      being that memory is overcommitted.
      
      *O* is the abbreviation for "Overcommitted".
    instancetype.kubevirt.io/displayName: General Purpose
  labels:
    instancetype.kubevirt.io/class: general.purpose
    instancetype.kubevirt.io/cpu: "1"
    instancetype.kubevirt.io/icon-pf: pficon-server-group
    instancetype.kubevirt.io/memory: 256Mi
    instancetype.kubevirt.io/vendor: kubevirt-basics-training
    instancetype.kubevirt.io/version: "1"
spec:
  cpu:
    guest: 1
  memory:
    guest: 256Mi
    overcommitPercent: 25
```
{{% /details %}}

Create your resource with:
```shell
kubectl create -f vmf_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-pico.yaml
```


## {{% task %}} Create your own Instancetype with virtctl

The `virtctl` tool is also capable of creating Instancetypes. You can define and create a similar Instancetype `u1.pico` with:
```shell
virtctl create instancetype --namespaced --cpu 1 --memory 256Mi --name {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-pico | kubectl create -f -
```

Show the created Instancetype with
```shell
kubectl get vmf {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-pico -o yaml
```


## {{% task %}} Adapt your VMs to use the new Instancetypes

You need to update the instancetype section of your VM. Make sure you reference the newly create instancetype.

{{% alert title="Note" color="info" %}}
After creating our VMs some additional fields were added to the VM resource. For example the `revisionName`:
```yaml
  instancetype:
    kind: VirtualMachineClusterInstancetype
    name: u1.nano
    revisionName: lab04-u1-cirros-u1.nano-v1beta1-e15b4047-3ff9-4308-9cd7-9f30b25336e0-1
```

It reflects the instancetype configuration at creation time of the VM. This prevents the
VM from accidental changes whenever an Instancetype itself would change. If we want to change the Instancetype explicitely
we have to remove the revisionName attribute completely otherwise it will reject the change.

The easies way is to edit the resource directly:
```shell
kubectl edit vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros
```
{{% /alert %}}

* Edit the VM `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros` and reference the `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-pico`
* Edit the VM `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros` and reference the `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-pico`

{{% details title="Task Hint" %}}
The relevant section for the VM `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros` should look like this:

```ỳaml
spec:
  instancetype:
    kind: VirtualMachineInstancetype
    name: lab04-u1-pico
```
{{% /details %}}

Make sure you restart both VMs to reflect the change of their instancetype:
```shell
virtctl restart {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros
virtctl restart {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros
```
