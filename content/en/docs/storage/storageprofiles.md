---
title: "Using StorageProfiles"
weight: 62
labfoldernumber: "06"
description: >
  Setting defaults for storage provisioning using storage profiles
---

When working with storage and the containerized data importer, one usually wants to have meaningful defaults. Let us have a look
at how we can configure storage profiles to be used with KubeVirt.

{{% alert title="Warning" color="warning" %}}
Due to the cluster-wide configuration of storage classes, the resources and commands in this lab are not meant to be created and executed!
{{% /alert %}}


## What are storage profiles

For each available StorageClass, KubeVirt creates a StorageProfile resource. StorageProfiles serve as a source of information about
the recommended parameters for a PVC. They are used when provisioning a PVC using a DataVolume. Having recommended parameters
defined centrally in a StorageProfile reduces the complexity of your DataVolume definition.

You can check the StorageProfiles with:

```yaml
kubectl get storageprofiles --namespace=$USER
```

```
NAME             AGE
hcloud-volumes   38d
longhorn         38d
```

You may check the configuration of the StorageProfile with:

```yaml
kubectl describe storageprofile longhorn --namespace=$USER
```

```
Name:         longhorn
Namespace:    
Labels:       app=containerized-data-importer
              app.kubernetes.io/component=storage
              app.kubernetes.io/managed-by=cdi-controller
              cdi.kubevirt.io=
Annotations:  <none>
API Version:  cdi.kubevirt.io/v1beta1
Kind:         StorageProfile
Metadata:
  Creation Timestamp:  2024-07-27T07:54:21Z
  Generation:          2
  Owner References:
    API Version:           cdi.kubevirt.io/v1beta1
    Block Owner Deletion:  true
    Controller:            true
    Kind:                  CDI
    Name:                  cdi
    UID:                   a9f271d9-e57a-4199-b61d-28dd6925587c
  Resource Version:        16172528
  UID:                     5ebfeeb1-c45d-44b6-8d48-d31cfc501110
Spec:
Status:
  Clone Strategy:                  snapshot
  Data Import Cron Source Format:  pvc
  Provisioner:                     driver.longhorn.io
  Snapshot Class:                  longhorn-snapshot-vsc
  Storage Class:                   longhorn
Events:                            <none>
```


## Create a DataVolume

Let's have a look how this works. Assume we create a DataVolume `my-dv` with the following specification and apply it to the cluster:

```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: my-dv
spec:
  source:
    blank: {}
  storage:
    resources:
      requests:
        storage: 128Mi
```

The DataVolume will not be created. Describe the DataVolume with:

```bash
kubectl describe datavolume my-dv --namespace=$USER
```

We see that CDI is lacking some information to create the PVC and returns an error:

```
Status:
  Conditions:
    Message:               no accessMode defined on StorageProfile for longhorn StorageClass
    Reason:                ErrClaimNotValid
    Status:                Unknown
```

This means that the controller did not know which access mode to use for the PVC.


### Define StorageProfiles

Besides others, a storage profile `spec` block can take the following parameters:

* `claimPropertySets`
  * `accessMode` - Contains the desired access modes the volume should have
  * `volumeMode` - Defines what type of volume is required by the claim
* `cloneStrategy` - Defines the preferred method for performing a CDI clone
  * `copy` - Copy blocks of data over the network
  * `snapshot` - Clones the volume by creating a temporary VolumeSnapshot and restores it to a new PVC
  * `csi-clone` - Clones the volume using a CSI clone

If you want to read more about parameters, defaults and how storage profiles are used, check the [StorageProfiles documentation](https://github.com/kubevirt/containerized-data-importer/blob/main/doc/storageprofile.md#parameters).


### Setting AccessMode and VolumeMode

To fix the issue above and provide default values for the storage profile `longhorn`, we can set defaults in the `spec`
block of the storage profile.

Let's assume we add the `accessMode` and `volumeMode` to the `longhorn` storage profile like this:

```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: StorageProfile
metadata:
  name: longhorn
[...]
spec:
  claimPropertySets:
    - accessModes:
      - ReadWriteOnce
      volumeMode: Filesystem
[...]
```

As soon as we have the storage profile configured and in place, we can re-apply our DataVolume:

```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: my-dv
spec:
  source:
    blank: {}
  storage:
    resources:
      requests:
        storage: 128Mi
```

It is now successfully provisioned using the defaults from the storage profile:

```bash
kubectl describe datavolume my-dv --namespace=$USER
```

```
Status:
  Conditions:
    Message:               PVC my-dv Bound
    Reason:                Bound
    Status:                True
```
