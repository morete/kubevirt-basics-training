---
title: "Perform Live Migration"
weight: 71
labfoldernumber: "07"
description: >
  Migrate running VMs to other Nodes for maintenance or other reasons
---

This Lab demonstrates how to perform a live migration of a running virutal machine.


## {{% task %}} Creating a virtual machine

Create a new file `livemigration.yaml` in the folder `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/` with the following content:


```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/size: small
        kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration
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
      {{< onlyWhen tolerations >}}tolerations:
        - effect: NoSchedule
          key: baremetal
          operator: Equal
          value: "true"
      {{< /onlyWhen >}}volumes:
        - name: containerdisk
          containerDisk:
            image: {{% param "cirrosCDI" %}}
```
Apply it to the cluster to create the virtual machine.
and apply the manifest.

{{% details title="Task hint: apply command" %}}
```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/livemigration.yaml --namespace=$USER
```
{{% /details %}}

Start the virtual machine:

```bash
virtctl start {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER
```

Once the VM has started successfully execute the following command to get the node the VMI is running on:

```bash
kubectl get vmi --namespace=$USER
```

Which will result in:

```bash
NAME                   AGE    PHASE     IP              NODENAME                 READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration    45m    Running   10.244.6.103    training-baremetal-<x>   True
```

During the start up of the virtual machine, KubeVirt determines whether a VMI is live-migratable or not. The information can be found in the `status.conditions` section of the VMI resource.

```bash
kubectl get vmi {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER -o yaml
```

Should show:

```yaml
[...]
 conditions:
  - lastProbeTime: null
    lastTransitionTime: "2024-10-05T14:51:36Z"
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: null
    status: "True"
    type: LiveMigratable
[...]
```


## {{% task %}} Start a simple process in your VM

Create the following Kubernetes Service (file: `service-livemigration.yaml` folder: `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}`):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration
  type: ClusterIP
```

```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/service-livemigration.yaml --namespace=$USER
```

Open a console to the VM and login:

```bash
virtctl console {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER
```

Start the following command:

```bash
while true; do ( echo "HTTP/1.0 200 Ok"; echo; echo "Migration test" ) | nc -l -p 8080; done
```

Go back to the webshell and open a new Terminal to test the service

```bash
curl -s {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration.$USER.svc.cluster.local:8080
```


## {{% task %}} Perform a live migration

To perform a Live Migration we can simply create a `VirtualMachineInstanceMigration` resource on the cluster, referencing the VMI to migration.
Create a new file `livemigration-job.yaml` in the folder `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/` with the following content:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstanceMigration
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration-job
spec:
  vmiName: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration
```

{{% alert title="Note" color="info" %}}  
It's also possible to initiate a live migration of a VM by using `virtctl`

```bash
virtctl migrate {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER
```
{{% /alert %}}

And apply it to the cluster:

```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/livemigration-job.yaml --namespace=$USER
```

This will automatically perform the live migration. Use the following command to see the status of the migration:

```bash
kubectl get VirtualMachineInstanceMigration {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration-job -w --namespace=$USER
```

Once the migration was successful, the VMI should run on the other node. Use

```bash
kubectl get vmi {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER
```

to verify that.


Details about the migration state will be represented in the VMI or the corresponding `VirtualMachineInstanceMigration`

```bash
kubectl describe vmi {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER
```

or

```bash
kubectl get VirtualMachineInstanceMigration {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration-job -o yaml --namespace=$USER
```

To check on the migration status in the status section of the `VirtualMachineInstance`.

And verify the running simple webserver by executing

```bash
curl -s {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration.$USER.svc.cluster.local
```


## Cancel a live migration

This lab is not meant to be executed.

A live migration can also be canceled, by deleting the `VirtualMachineInstanceMigration` object

```bash
kubectl delete vmi {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration-job --namespace=$USER
```

or using `virtctl`

```bash
virtctl migrate-cancel {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER
```


A successfully canceled migration will show the following states:

* Abort Requested: true
* Abort Status: Succeeded
* Completed: true
* Failed: true


## {{% task %}} (optional) perform migrations using the kubevirt command

Let's use the `kubevirt migrate` to perform an additional migration. Follow the migration with the commands we've used in the lab above.
Try to cancel a live migration, and verify it in the status section of the VMI manifest.


## {{% task %}} (optional) migration policies

In addition to the cluster wide configuration of the LiveMigration feature the concept of [Migration Policies](https://kubevirt.io/user-guide/cluster_admin/migration_policies/) was introduced. Migration policies are currently (v1.30) an alpha feature and the API might not be stable.

Explore the official documentation under <https://kubevirt.io/user-guide/cluster_admin/migration_policies/>


## End of lab

{{% alert title="Cleanup resources" color="warning" %}}  {{% param "end-of-lab-text" %}}

Stop the `VirtualMachineInstance`:

```bash
virtctl stop {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-livemigration --namespace=$USER
```
{{% /alert %}}
