---
title: "KubeVirt configuration"
weight: 12
type: docs
description: >
  Getting to know the lab environment.
  KubeVirt-specific configuration on the lab cluster.
---


## KubeVirt installation

On the Kubernetes cluster used for this training, the following Operators have been installed:

| Operator name                    | Namespace  |
|----------------------------------|------------|
| KubeVirt                         | kubevirt   |
| Containerized Data Impoter (CDI) | cdi        |

As the configuration and the required feature flags are subject to change, we do not highlight them in every section.


### Emulation

For local development and test environments, the emulation can be turned on. This may have a huge impact to the performance.

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      useEmulation: true
[...]
```

The Lab cluster is not using emulation.


### Enabled Kubernetes feature flags

In the cluster, the following KubeVirt feature flags are enabled:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
      - Sidecar
      - CommonInstancetypesDeploymentGate
      - ExperimentalIgnitionSupport
      - HotplugVolumes
      - ExpandDisks
      - Snapshot
      - VMExport
      - BlockVolume
```
