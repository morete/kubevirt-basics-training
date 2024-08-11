---
title: "2.1 Create a VM"
weight: 210
labfoldernumber: "02"
sectionnumber: 2.1
description: >
  Create your first VirtualMachine
---


## Creating a Virtual Machine

To create a Virtual Machine in our kubernetes cluster we have to create and apply a `VirtualMachine` yaml manifest.

This is a very basic example of a bootable virtual machine manifest.

```yaml
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
        devices: {}
        resources:
          requests:
            memory: 64M
```


{{% alert title="Note" color="info" %}}
A VirtualMachine yaml requires a memory resource specification. Therefore, we always have `spec.domain.resources.requests.memory` set.
You may also use `spec.domain.memory.guest` or `spec.domain.memory.hugepages.size` as a resource specification.
{{% /alert %}}


### {{% task %}} Review VirtualMachine manifest

Do you see any problems with the specification above? Try to answer the following questions:

* What happens when you run this vm?
* What is required to successfully boot a machine?

{{% details title="Task Hint" %}}
Our created manifest does not contain any bootable devices. Our vm is able to start, but it will just hang as there are
no bootable devices available.

![No bootable device](../no-bootable-device.png)

Having a bootable disk within your yaml specification is all you need to start the vm. However, as there is no network
interface specified which is connected to the underlying network our system would not be capable of interacting with the
outside world.
{{% /details %}}


### {{% task %}} Write your own VirtualMachine manifest

Create a file `vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm.yaml` with the content yaml
content from above. Starting from the basic manifest you need to add a bootable disk for your vm and a network and
interface specification. The easiest way is to use an ephemeral `containerDisk` mountable as a volume. Regarding the
network we connect our VM to the underlying kubernetes default network.

```yaml
spec:
  template:
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
      networks:
        - name: default
          pod: {}
      volumes:
        - name: containerdisk
          containerDisk:
            image: {{% param "cirrosContainerDiskImage" %}}
```

Make sure you implement the required parts for a container disk and the network interface specification in you VM manifest.

{{% details title="Task Hint" %}}
Your yaml should look like this:
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
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/kubevirt/cirros-container-disk-demo
```
{{% /details %}}


### {{% task %}} Create the VirtualMachine

Since you have completed the yaml configuration for the VM it's now time to create it our VM in the kubernetes cluster.

```shell
kubectl create -f {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm.yaml
```

The output should be:

```shell
virtualmachine.kubevirt.io/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}} created
```

