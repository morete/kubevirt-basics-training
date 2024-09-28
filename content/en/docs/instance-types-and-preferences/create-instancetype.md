---
title: "Create an Instancetype"
weight: 33
labfoldernumber: "03"
description: >
  Create your own Instance type and Preference
---

In this section we will create and use our own instance type.


## {{% task %}} Create your own Instancetype

In the previous section we have seen that the Cirros preference requests 256Mi of memory. However, the smallest Instancetype
available requested 512Mi of memory. Let's create our own Instancetype and assign it to our VirtualMachines.

Create a file `vmf_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-pico.yaml` under `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}` and start with the
definition of the `o1.nano` instancetype.

Define the Instancetype:

* Request 256Mi of memory
* Reduce the overcommit percentage from 50% to 25%
* Name the resource `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-pico`.

{{% details title="Task Hint" %}}
Your Instancetype should look like this (labels and annotations are optional):
```yaml
apiVersion: instancetype.kubevirt.io/v1beta1
kind: VirtualMachineInstancetype
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-pico
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
```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/vmf_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-pico.yaml --namespace=$USER
```

And verify whether the creation was successful:

```bash
kubectl get vmf {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-pico --namespace=$USER
```


## {{% task %}} Create your own Instancetype with virtctl

The `virtctl` tool is also capable of creating Instancetypes. You can define and create a similar Instancetype `u1.pico` with:
```bash
virtctl create instancetype --namespaced --cpu 1 --memory 256Mi --name {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-pico --namespace=$USER | kubectl create --namespace=$USER -f -
```

Show the created Instancetype with
```bash
kubectl get vmf {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-pico -o yaml --namespace=$USER
```

The output will be similar to this one:
```yaml
apiVersion: instancetype.kubevirt.io/v1beta1
kind: VirtualMachineInstancetype
metadata:
  creationTimestamp: "2024-09-25T09:25:35Z"
  generation: 1
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-pico
  namespace: <user>
  resourceVersion: "55713159"
  uid: 14d414b7-b1f8-4b0d-af48-fb84340545c9
spec:
  cpu:
    guest: 1
  memory:
    guest: 256Mi
```
