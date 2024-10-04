---
title: "Hotplugging disks"
weight: 63
labfoldernumber: "06"
description: >
  Hotplugging disks into virtual machines
---

In this section we will hotplug a disk to a running virtual machine.


## {{% task %}} Starting a virtual machine

First, create a file `vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros.yaml` in the folder `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}` and start with the following virtual machine definition:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-volume
    spec:
      domain:
        devices:
          disks:
            - name: containerdisk
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
            image: quay.io/kubevirt/cirros-container-disk-demo
        - name: cloudinitdisk
          cloudInitNoCloud:
            userData: |
              #cloud-config
```

Create and start the virtual machine with:

```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros.yaml --namespace=$USER
```

Start the VM with:

```bash
virtctl start {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros --namespace=$USER
```

Open a console with:

```bash
virtctl console {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros --namespace=$USER
```


## Inspect block devices on the virtual machine before hotplugging a disk

Depending on the system you use you have different ways of listing devices. Here is a set of possibilities:

Listing block devices with `lsblk`:

```bash
lsblk -a
```

```
NAME    MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
vda     253:0    0  44M  0 disk 
|-vda1  253:1    0  35M  0 part /
`-vda15 253:15   0   8M  0 part 
vdb     253:16   0   1M  0 disk 
loop0     7:0    0       0 loop 
[...]
```

Listing devices in the `/dev` folder:

```bash
ls -d -- /dev/[sv]d[a-z]
```

```
/dev/vda  /dev/vdb
```

Some operating systems also list disk devices in `/dev/disk` with subfolders representing different views to your disks.
On a, e.g., Fedora virtual machine:

```bash
ls -lR /dev/disk/*
```

```
/dev/disk/by-label:
cidata -> ../../vdb

/dev/disk/by-partuuid:
41222438-01 -> ../../vda1

/dev/disk/by-path:
pci-0000:07:00.0 -> ../../vda
pci-0000:07:00.0-part1 -> ../../vda1
pci-0000:08:00.0 -> ../../vdb
virtio-pci-0000:07:00.0 -> ../../vda
virtio-pci-0000:07:00.0-part1 -> ../../vda1
virtio-pci-0000:08:00.0 -> ../../vdb

/dev/disk/by-uuid:
2024-09-03-15-29-13-00 -> ../../vdb
d1b37ed4-3bbb-40b2-a6ba-f377f0c90217 -> ../../vda1
```

Devices starting with `/dev/vd{a,b,c}` are our devices using the virtio bus type. Devices with `/dev/s{a,b,c,...}` are
SCSI devices. What we see inside the virtual machine reflects our configuration.

Actually, we can see that we have two disks available:

* `/dev/vda` - The first disk and therefore our container disk.
* `/dev/vdb` - The second disk is the cloud-init disk. If your operating system provides the `/dev/disk` folder you may see that the cloud-init disk is labeled `cidata` (see sample output). This is required for cloud-init to detect the disk as a provider for cloud-init configuration[^1].


## {{% task %}} Create a DataVolume to be hotplugged

Create a file `dv_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk.yaml` in the folder `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}` with the following content:

```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk
spec:
  source:
    blank: {}
  storage:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 128Mi
```

Create the data volume with:

```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/dv_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk.yaml --namespace=$USER
```


## {{% task %}} Hotplug a volume to a virtual machine

Hotplug the disk by using `virtctl`:

```bash
virtctl addvolume {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros --volume-name={{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk --namespace=$USER
```

```
Successfully submitted add volume request to VM {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros for volume {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk
```

After some time, the device will be hotplugged to your virtual machine. You may get a first hint where your new disk is plugged in by executing `dmesg` in the VM's console:

```bash
dmesg
```

```
[   78.043285] scsi 0:0:0:0: Direct-Access     QEMU     QEMU HARDDISK    2.5+ PQ: 0 ANSI: 5
[   78.056318] sd 0:0:0:0: Warning! Received an indication that the LUN assignments on this target have changed. The Linux SCSI layer does not automatical
[   78.060497] sd 0:0:0:0: [sda] 262144 512-byte logical blocks: (134 MB/128 MiB)
[   78.070252] sd 0:0:0:0: [sda] Write Protect is off
[   78.070767] sd 0:0:0:0: [sda] Mode Sense: 63 00 00 08
[   78.073753] sd 0:0:0:0: [sda] Write cache: enabled, read cache: enabled, doesn't support DPO or FUA
[   78.075719] sd 0:0:0:0: Attached scsi generic sg0 type 0
[   78.113862] sd 0:0:0:0: [sda] Attached SCSI disk
```

You can verify this using the commands above. Check that your `/dev/sda` device is available.

{{% alert title="Note" color="info" %}}
Disks are always hotplugged using the SCSI bus. This is due to the fact that virtio devices use a PCIe slot which are
limited to 32 slots on a system. Further PCIe slots need to be reserved ahead of time.
{{% /alert %}}

Check with list block devices:

```bash
lsblk -a
```

```
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda       8:0    0  128M  0 disk 
vda     253:0    0   44M  0 disk 
|-vda1  253:1    0   35M  0 part /
`-vda15 253:15   0    8M  0 part 
vdb     253:16   0    1M  0 disk 
loop0     7:0    0       0 loop 
[...]
```

Check listing the devices:

```bash
ls -d -- /dev/[sv]d[a-z]
```

```
/dev/sda  /dev/vda  /dev/vdb
```

In our case we can clearly see that our new hotplugged disk is `/dev/sda`. Let's mount it.


### {{% task %}} Format and mount the disk

From the previous steps we know our new disk is `/dev/sda`. To use it we first have to format the new disk.

{{% alert title="Important" color="warning" %}}
When hotplugging volumes and formatting devices always make sure you know where they are plugged in.
{{% /alert %}}


```bash
sudo mkfs.ext4 /dev/sda
```

```
mke2fs 1.42.12 (29-Aug-2014)
Discarding device blocks: done                            
Creating filesystem with 131072 1k blocks and 32768 inodes
Filesystem UUID: 8cceeb09-cf4c-4605-896a-e2ecbe878894
Superblock backups stored on blocks: 
 8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done 
```

Next we have to create mount points for our new disk:

```bash
sudo mkdir /mnt/disk
```

And finally mount the disk:

```bash
sudo mount /dev/sda /mnt/disk/
```

We can start to use the disk:

```bash
sudo touch /mnt/disk/myfile
```


### {{% task %}} Removing a disk

You can remove a hotplugged disk with:

```bash
virtctl removevolume {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros --volume-name={{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk --namespace=$USER
```

```
Successfully submitted remove volume request to VM {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros for volume {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk
```

What happens if you remount the disk again? Is the created file `/mnt/disk/myfile` still present?

{{% details title="Task Hint" %}}
After hotplugging and mounting the volume again the file is still present. There is no need to format the device again.
However, the mounting needs to be done again. You may mount disks with startup scripts like cloud-init.

Beware that the device might have a different name such as `sdb`.

Mount the disk again with:

```bash
sudo mkdir /mnt/disk
sudo mount /dev/sdb /mnt/disk/
```

Check whether the file `/mnt/disk/myfile` still exists.

And don't forget to remove the disk again:

```bash
virtctl removevolume {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros --volume-name={{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk --namespace=$USER
```

{{% /details %}}


## Persistent mounting

With the above steps we have hotplugged a disk into the VM. This mount is not persistent. Whenever the VM is restarted
or shut down, the disk won't be attached again. When you want to mount the disk persistently you can use the `--persist` flag.

```bash
virtctl addvolume {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros --volume-name={{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk --persist --namespace=$USER
```

```
Successfully submitted add volume request to VM {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros for volume {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk
```

This will add the relevant sections to your `VirtualMachine` manifest. You can show the modified configuration with:

```bash
kubectl get vm {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros -o yaml --namespace=$USER
```

```bash
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cirros
spec:
  [...]
  template:
    [...]
    spec:
      domain:
        devices:
          disks:
          - name: containerdisk
            disk:
              bus: virtio
          - name: cloudinitdisk
            disk:
              bus: virtio
          - name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk
            disk:
              bus: scsi
            serial: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk
      volumes:
      - name: containerdisk
        containerDisk:
          image: quay.io/kubevirt/cirros-container-disk-demo
      - name: cloudinitdisk
        cloudInitNoCloud:
          userData: |
            #cloud-config
      - name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk
        dataVolume:
          hotpluggable: true
          name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-hotplug-disk
[...]
```

[^1]: [Cloud-init labeled drive](https://cloudinit.readthedocs.io/en/latest/reference/datasources/nocloud.html#source-2-drive-with-labeled-filesystem)
