---
title: "Common instance types and preferences"
weight: 32
labfoldernumber: "03"
description: >
  Discover and use common instance types and preferences provided by KubeVirt
---

The KubeVirt project provides a set of [common instance types and preferences](https://github.com/kubevirt/common-instancetypes).
In this lab, we are going to have a look at these and how they can help us create virtual machines.


## Deployment of common instance types and preferences

The common instance types and preferences are not available by default. They have to be deployed manually or by using one of the KubeVirt Operator's feature gates.

You can check the configuration on the KubeVirt CustomResource:

```bash
kubectl get kubevirt kubevirt --namespace=kubevirt -o jsonpath={.spec.configuration.developerConfiguration.featureGates}
```
or

```bash
kubectl get kubevirt kubevirt --namespace=kubevirt -o yaml
```

The relevant section on the CustomResource is the following:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - CommonInstancetypesDeploymentGate
[...]
```

With the feature gate enabled, the Operator itself takes care of deploying the cluster wide common instance types and preferences.


### Manually deploy the common instance types and preferences

This step has been done for your on the lab cluster.
How to deploy the common instance types and preferences on your own cluster can be found in the [documentation](https://kubevirt.io/user-guide/user_workloads/deploy_common_instancetypes/).


## List and inspect instance types

Be aware that the common instance types and preferences are cluster-wide resources. They are called
`VirtualMachineClusterInstancetype` and `VirtualMachineClusterPreference`.

You can list the available instance types using:

```bash
kubectl get virtualmachineclusterinstancetype
```

A shortened output of the command above:

```bash
NAME          AGE
cx1.2xlarge   10m
[...]
gn1.2xlarge   10m
[...]
m1.2xlarge    10m
[...]
n1.2xlarge    10m
[...]
o1.2xlarge    10m
[...]
u1.2xlarge    10m
u1.4xlarge    10m
u1.8xlarge    10m
u1.large      10m
u1.medium     10m
u1.micro      10m
u1.nano       10m
u1.small      10m
u1.xlarge     10m
```

As you see the instance types follow a specific naming schema:

```bash
instanceTypeName = seriesName , "." , size;

seriesName = ( class | vendorClass ) , version;

class = "u" | "o" | "cx" | "g" | "m" | "n" | "rt";
vendorClass = "g" , vendorHint;
vendorHint = "n" | "i" | "a";
version = "1";

size = "nano" | "micro" | "small" | "medium" | "large" | [( "2" | "4" | "8" )] , "xlarge";
```

The class `u`, `o`, `cx`, `g`, `m`, `n` and  `rt` mean the following:

* **U** (universal) - Provides resources for general purpose applications. VMs will share CPU cores on a time-slice basis.
* **O** (overcommitted) - Based on `u` with the only difference that memory will be overcommitted. Allows higher workload density.
* **CX** (compute exclusive) - Provides exclusive compute resources for compute intensive applications.
* **GN** (gpu nvidia) - Instance type for VMs which consume attached NVIDIA GPUs.
* **M** (memory) - Provides resources for memory-intensive applications.
* **N** (network) - Provide resources for network-intensive DPDK[^1] applications like Virtual Network Functions (VNF).
* **RT** (realtime) - Provide resources for realtime-intensive applications.

We therefore can say that the classes `u` and `o` are agnostic to the workload. The other classes are optimized for
specific workload.

You may see the details of an instance type by describing the resource:

```bash
kubectl describe virtualmachineclusterinstancetype o1.nano
```

As an example you will see that the instance type `o1.nano` has 1 CPU, 512Mi memory and overcommits memory by 50%. The following output is shortened:

```
Name:         o1.nano
Namespace:    
Labels:       app.kubernetes.io/component=kubevirt
              app.kubernetes.io/managed-by=virt-operator
              instancetype.kubevirt.io/class=overcommitted
              instancetype.kubevirt.io/common-instancetypes-version=v1.0.1
              instancetype.kubevirt.io/cpu=1
              instancetype.kubevirt.io/icon-pf=pficon-virtual-machine
              instancetype.kubevirt.io/memory=512Mi
              instancetype.kubevirt.io/vendor=kubevirt.io
              instancetype.kubevirt.io/version=1
Annotations:  instancetype.kubevirt.io/description:
                The O Series is based on the U Series, with the only difference
                being that memory is overcommitted.
                
                *O* is the abbreviation for "Overcommitted".
              instancetype.kubevirt.io/displayName: Overcommitted
API Version:  instancetype.kubevirt.io/v1beta1
Kind:         VirtualMachineClusterInstancetype
Spec:
  Cpu:
    Guest:  1
  Memory:
    Guest:               512Mi
    Overcommit Percent:  50
[...]
```


## List and inspect preferences

```bash
kubectl get virtualmachineclusterpreference
```

A shortened output of the command above:

```
NAME                     AGE
alpine                   10m
centos.7                 10m
[...]
```

You may see the details of a preference by describing the resource:

```bash
kubectl describe virtualmachineclusterpreference cirros
```

As an example you'll see that the instance type `cirros` has the requirements of 1 CPU, 256Mi memory. The following output is shortened:

```
Name:         cirros
Namespace:    
Labels:       app.kubernetes.io/component=kubevirt
              app.kubernetes.io/managed-by=virt-operator
              instancetype.kubevirt.io/common-instancetypes-version=v1.0.1
              instancetype.kubevirt.io/os-type=linux
              instancetype.kubevirt.io/vendor=kubevirt.io
Annotations:  iconClass: icon-cirros
              tags: hidden,kubevirt,cirros
API Version:  instancetype.kubevirt.io/v1beta1
Kind:         VirtualMachineClusterPreference
Metadata:
  [...]
Spec:
  Devices:
    Preferred Disk Bus:         virtio
    Preferred Interface Model:  virtio
  Requirements:
    Cpu:
      Guest:  1
    Memory:
      Guest:  256Mi
[...]
```


## Querying for specific instance types and preferences with labels


### Instancetypes

These instance types are labeled according to their specification. You can use labels to find the correct instance type.

Instance types are known to use the following labels:

```properties
instancetype.kubevirt.io/common-instancetypes-version: The version of the common-instancetypes project used to generate these resources.
instancetype.kubevirt.io/vendor: The vendor of the resource, this is always kubevirt.io upstream and should be changed by downstream vendors consuming the project.
instancetype.kubevirt.io/icon-pf: The suggested patternfly icon to use when displaying the resource.
instancetype.kubevirt.io/deprecated: If the resource has been deprecated ahead of removal in a future release of the common-instancetypes project.
instancetype.kubevirt.io/version: The version of instance type class the resources has been generated from.
instancetype.kubevirt.io/class: The class of the instance type.
instancetype.kubevirt.io/cpu: The number of vCPUs provided by the instance type.
instancetype.kubevirt.io/memory: The amount of memory provided by the instance type.
instancetype.kubevirt.io/numa: If NUMA guestmappingpassthrough is enabled by the instance type.
instancetype.kubevirt.io/dedicatedCPUPlacement: If dedicatedCPUPlacement is enabled by the instance type.
instancetype.kubevirt.io/isolateEmulatorThread: If isolateEmulatorThread is enabled by the instance type.
instancetype.kubevirt.io/hugepages: If hugepages are requested by the instance type.
instancetype.kubevirt.io/gpus: If GPUs are requested by the instance type.
```

As an example, you can query for 4 CPUs:

```bash
kubectl get virtualmachineclusterinstancetype --selector instancetype.kubevirt.io/cpu=4
```

Output will list all instance types with 4 CPUs:

```
NAME         AGE
cx1.xlarge   10m
gn1.xlarge   10m
m1.xlarge    10m
n1.large     10m
n1.medium    10m
o1.xlarge    10m
u1.xlarge    10m
```


### Preferences

Just like instance types, preferences are labeled with the following labels:

```properties
instancetype.kubevirt.io/common-instancetypes-version: The version of the common-instancetypes project used to generate these resources.
instancetype.kubevirt.io/vendor: The vendor of the resource, this is always kubevirt.io upstream and should be changed by downstream vendors consuming the project.
instancetype.kubevirt.io/icon-pf: The suggested patternfly icon to use when displaying the resource.
instancetype.kubevirt.io/deprecated: If the resource has been deprecated ahead of removal in a future release of the common-instancetypes project.
instancetype.kubevirt.io/os-type: The underlying type of the workload supported by the preference, current values are linux or windows.
instancetype.kubevirt.io/arch: The underlying architecture of the workload supported by the preference, current values are `arm64` or `amd64`.
```

We can use these labels to query preferences:

```bash
kubectl get virtualmachineclusterpreference --selector instancetype.kubevirt.io/os-type=linux
```

The output will list all preferences targeting the operating system linux (output shortened):

```
NAME                     AGE
alpine                   10m
centos.7                 10m
[...]
cirros                   10m
fedora                   10m
[...]
rhel.9.dpdk              10m
ubuntu                   10m
[...]
```


## {{% task %}} Find matching instance type and preference

You want to find the optimal configuration of instance type and preference for a Windows 10 64-bit virtual machine.
According to Microsoft, the Windows 10 system requirements[^2] are the following:

```
Processor: 1 gigahertz (GHz) or faster processor or SoC
RAM: 2 GB for 64-bit
Hard disk space: 20 GB for 64-bit OS
```

Try to find the best matching instance type and preference for a Windows 10 minimal installation using label selectors.

{{% details title="Task Hint" %}}
You can query instance types as follows:

```bash
kubectl get virtualmachineclusterinstancetype \
   --selector instancetype.kubevirt.io/cpu=1,instancetype.kubevirt.io/memory=2Gi
```

Above query will return something like:

```bash
NAME         AGE
cx1.medium   10m
o1.small     10m
u1.small     10m
```

You would most likely pick `o1.small` or `u1.small` as your instance type.

For preferences, you can use the following query:

```bash
kubectl get virtualmachineclusterpreference --selector instancetype.kubevirt.io/os-type=windows
```

Which outputs:

```
NAME                  AGE
windows.10            10m
windows.10.virtio     10m
windows.11            10m
windows.11.virtio     10m
windows.2k12          10m
windows.2k12.virtio   10m
windows.2k16          10m
windows.2k16.virtio   10m
windows.2k19          10m
windows.2k19.virtio   10m
windows.2k22          10m
windows.2k22.virtio   10m
```

The preferences `windows.10` or `windows.10.virtio` are the best-matching.

{{% alert title="Note" color="info" %}}
This only fulfills the machines minimal requirements. In a production environment you would most likely size your instance bigger than the minimal requirements.
{{% /alert %}}

{{% /details %}}


## {{% task %}} Deploy two Cirros VMs with minimal requirements

Deploy two VMs with different instance types:

* Deploy a cirros VM using a `u` class instance type and a matching preference
  * Write the VM specification in `vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros.yaml`
* Deploy a cirros VM using a `o` class instance type and the same preference
  * Write the VM specification in `vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros.yaml`

{{% onlyWhen tolerations %}}

{{% alert title="Tolerations" color="warning" %}}
Don't forget the `tolerations` from the setup chapter to make sure the VM will be scheduled on one of the baremetal nodes.
{{% /alert %}}

{{% /onlyWhen %}}

{{% details title="Solution" %}}
`{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros.yaml` specification:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros
spec:
  running: false
  instancetype:
    kind: VirtualMachineClusterInstancetype
    name: u1.nano
  preference:
    kind: VirtualMachineClusterPreference
    name: cirros
  template:
    metadata:
      labels:
        kubevirt.io/size: nano
        kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros
    spec:
      domain:
        devices:
          disks:
            - name: containerdisk
            - name: cloudinitdisk
          interfaces:
            - name: default
              masquerade: {}
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
            image: quay.io/kubevirt/cirros-container-disk-demo
        - name: cloudinitdisk
          cloudInitNoCloud:
            userDataBase64: SGkuXG4=
```

`{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros.yaml` specification:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros
spec:
  running: false
  instancetype:
    kind: VirtualMachineClusterInstancetype
    name: o1.nano
  preference:
    kind: VirtualMachineClusterPreference
    name: cirros
  template:
    metadata:
      labels:
        kubevirt.io/size: nano
        kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros
    spec:
      domain:
        devices:
          disks:
            - name: containerdisk
            - name: cloudinitdisk
          interfaces:
            - name: default
              masquerade: {}
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
            image: quay.io/kubevirt/cirros-container-disk-demo
        - name: cloudinitdisk
          cloudInitNoCloud:
            userDataBase64: SGkuXG4=
```

Apply and start both VMs using:

```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros.yaml --namespace=$USER
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros.yaml --namespace=$USER
virtctl start {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros
virtctl start {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros
```
{{% /details %}}


## {{% task %}} Instance type differences

The main difference in the instance types `u` and `o` are memory overcommitting. Let's inspect our two VMs. What exactly means
overcommitting in the scope of a VirtualMachine instance? Overcommitting means that we assign more memory to a VM than we requested
from the cluster by setting `spec.domain.memory.guest` to a higher value than `spec.domain.resources.requests.memory`.

What would you expect from both VMs?

{{% details title="Task hint" %}}

* `u` class should have equal requests for `spec.domain.memory.guest` and `spec.domain.resources.requests.memory`
* `o` class should have higher requests for `spec.domain.memory.guest` than `spec.domain.resources.requests.memory`

For both VMs we would expect the guest OS to have approximately 512Mi of memory.
{{% /details %}}

Check the expectations about memory settings of both VirtualMachine instances `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros`
and `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros`. Do they match our expectations?

{{% details title="Task hint" %}}

Describe both VirtualMachine instances using:

```bash
kubectl get vmi {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros -o yaml --namespace=$USER
kubectl get vmi {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros -o yaml --namespace=$USER
```

The `u1-cirros` instance:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-u1-cirros
spec:
  domain:
    resources:
      requests:
        memory: 512Mi
    memory:
      guest: 512Mi
[...]
```

The `o1-cirros` instance:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-o1-cirros
spec:
  domain:
    resources:
      requests:
        memory: 256Mi
    memory:
      guest: 512Mi
[...]
```

As we can see in the difference between `spec.domain.memory.guest` and `spec.domain.resources.requests.memory`, the `o` class actually overcommits by 50% as defined in the `o1.nano` instance type:

```yaml
apiVersion: instancetype.kubevirt.io/v1beta1
kind: VirtualMachineClusterInstancetype
metadata:
  name: o1.nano
spec:
  cpu:
    guest: 1
  memory:
    guest: 512Mi
    overcommitPercent: 50
[...]
```

The `.status.memory` of both VirtualMachine instances shows that the guest was assigned 512Mi memory.

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
status:
  memory:
    guestAtBoot: 512Mi
    guestCurrent: 512Mi
    guestRequested: 512Mi
[...]
```

{{% /details %}}


[^1]: [Data Plane Development Kit (DPDK)](https://www.dpdk.org/about/)
[^2]: [Windows 10 system requirements](https://support.microsoft.com/en-us/windows/windows-10-system-requirements-6d4e9a79-66bf-7950-467c-795cf0386715)
