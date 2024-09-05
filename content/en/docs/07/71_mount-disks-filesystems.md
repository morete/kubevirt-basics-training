---
title: "7.1 Mount Disks and Filesystems"
weight: 710
labfoldernumber: "07"
sectionnumber: 7.1
description: >
  Mounting storage as disks and filesystems.
---

There are multiple ways of mounting a disk to a virtual machine. In this section we will mount various disks to our vm.


## Block and Volume devices

KubeVirt support mounting `block` or `filesystem` volumes. Filesystem is the default behaviour of kubernetes. Whether you
can use `block` devices or not depends on your CSI driver supporting block volumes.

When creating a DataVolume we can specify whether the disk should be a Filesystem disk or a block device. Requesting a
blank volume will look like this:
```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: lab07-fs-disk
spec:
  source:
    blank: {}
  storage:
    volumeMode: Filesystem
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 128Mi
```

TODO
