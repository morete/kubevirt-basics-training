---
title: "Resizing a Disk"
weight: 65
labfoldernumber: "06"
description: >
  Resizing virtual machine disks
---

In this section we will resize the root disk of a virtual machine.


## Requirements

Resizing disks depends on the Kubernetes storage provider. The CSI driver must support resizing volumes and must be configured with `AllowVolumeExpansion`.

Further, it may depend on the operating system you use. Whenever the volume is resized, your VM might see the change
in disk size immediately. But there might still be the need to resize the partition and filesystem. Fedora Cloud for instance
has the package `cloud-utils-growpart` installed. This rewrites the partition table so that the partition takes up all
the space available. This makes it a very handy choice for resizing disk images.


## {{% task %}} Create a volume and a virtual machine

In a first step we are going to create a Fedora disk. Create the file `dv_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand-disk.yaml` in the folder `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}` with the following content:

```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand-disk
spec:
  source:
    registry:
      url: "docker://{{% param "fedoraCloudCDI" %}}"
  pvc:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 6Gi
```

Create the data volume in the cluster:

```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/dv_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand-disk.yaml --namespace=$USER
```

Create the file `vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand.yaml` in the folder `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}` and use the following yaml specification:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand
    spec:
      domain:
        cpu:
          cores: 1
        devices:
          disks:
            - name: datavolumedisk
              disk:
                bus: virtio
            - name: cloudinitdisk
              disk:
                bus: virtio
          interfaces:
          - name: default
            masquerade: {}
        resources:
          requests:
            memory: 2Gi
      networks:
      - name: default
        pod: {}
      {{< onlyWhen tolerations >}}tolerations:
        - effect: NoSchedule
          key: baremetal
          operator: Equal
          value: "true"
      {{< /onlyWhen >}}volumes:
        - name: datavolumedisk
          persistentVolumeClaim:
            claimName: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand-disk
        - name: cloudinitdisk
          cloudInitNoCloud:
            secretRef:
              name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit
```

Create the virtual machine with:

```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand.yaml --namespace=$USER
```

Start the virtual machine with:

```bash
virtctl start {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand --namespace=$USER
```


### Check the disk size

Start the virtual machines' console and log in (user: `fedora`, password: `kubevirt`):

```bash
virtctl console {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand --namespace=$USER
```

Check your block devices with:

```bash
lsblk
```

```bash
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
zram0  251:0    0  1.9G  0 disk [SWAP]
vda    252:0    0  5.7G  0 disk 
├─vda1 252:1    0    2M  0 part 
├─vda2 252:2    0  100M  0 part /boot/efi
├─vda3 252:3    0 1000M  0 part /boot
└─vda4 252:4    0  4.6G  0 part /var
                                /home
                                /
vdb    252:16   0    1M  0 disk
```


## {{% task %}} Resize the disk

Triggering a resize of a PVC in Kubernetes can be done with editing the PVC size request. Get the PersistentVolumeClaim manifest with:

```bash
kubectl get pvc {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand-disk -o yaml --namespace=$USER
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand-disk
  [...]
spec:
  resources:
    requests:
      storage: 6Gi
[...]
```

Now, patch the PVC to increase the disk size to `8Gi`:

```bash
kubectl patch pvc {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand-disk --type='json' -p='[{"op": "replace", "path": "/spec/resources/requests/storage", "value":"8Gi"}]' --namespace=$USER
```

```
persistentvolumeclaim/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand-disk patched
```

It might take some time for the storage provider to resize the persistent volume. You can see details about the process
in the events section when describing the PersistentVolumeClaim resource:

```bash
kubectl describe pvc {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand-disk --namespace=$USER
```

```
Events:
  Type     Reason                       Age                 From                                                                                      Message
  ----     ------                       ----                ----                                                                                      -------
  Warning  ExternalExpanding            2m56s               volume_expand                                                                             waiting for an external controller to expand this PVC
  Normal   Resizing                     2m56s               external-resizer driver.longhorn.io                                                       External resizer is resizing volume pvc-bc3e89f3-1372-4e10-852a-0c94ea343ab4
  Normal   FileSystemResizeRequired     2m46s               external-resizer driver.longhorn.io                                                       Require file system resize of volume on node
  Normal   FileSystemResizeSuccessful   2m8s                kubelet                                                                                   MountVolume.NodeExpandVolume succeeded for volume "pvc-bc3e89f3-1372-4e10-852a-0c94ea343ab4" training-worker-2
```

If you still have a console open in your virtual machine you see that there was a message about the capacity change:

```bash
[  896.201742] virtio_blk virtio3: [vda] new size: 15853568 512-byte logical blocks (8.12 GB/7.56 GiB)
[  896.202409] vda: detected capacity change from 11890688 to 15853568
```

Recheck your block devices:

```bash
lsblk
```

```
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
zram0  251:0    0  1.9G  0 disk [SWAP]
vda    252:0    0  7.6G  0 disk 
├─vda1 252:1    0    2M  0 part 
├─vda2 252:2    0  100M  0 part /boot/efi
├─vda3 252:3    0 1000M  0 part /boot
└─vda4 252:4    0  4.6G  0 part /var
                                /home
                                /
vdb    252:16   0    1M  0 disk
```

You will see that the capacity change is visible from within the virtual machine. But at this time our partitions still
have the same size and do not use all available disk space.

Issue a reboot to let the system expand the partitions:

```bash
sudo reboot
```

After the reboot you have to log in and check `lsblk` again:
 
```bash
lsblk
```

You can see that, e.g., `vda4` has been resized from `5.7G` to `7.6G`.


## End of lab

{{% alert title="Cleanup resources" color="warning" %}}  {{% param "end-of-lab-text" %}}

Delete your VirtualMachine resources:

```bash
kubectl delete vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-storage --namespace=$USER
kubectl delete vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros --namespace=$USER
kubectl delete vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-snapshot --namespace=$USER
kubectl delete vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand --namespace=$USER
```

Delete your disks:

```bash
kubectl delete dv {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-fs-disk --namespace=$USER
kubectl delete dv {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-block-disk --namespace=$USER
kubectl delete dv {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros-disk --namespace=$USER
kubectl delete dv {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-expand-disk --namespace=$USER
kubectl delete dv {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk --namespace=$USER
```

Delete your VirtualMachineSnapshots:

```bash
kubectl delete vmsnapshot {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-snapshot-snap --namespace=$USER
```

{{% /alert %}}
