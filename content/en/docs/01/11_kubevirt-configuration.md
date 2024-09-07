---
title: "1.1 KubeVirt Configuration"
weight: 110
labfoldernumber: "01"
sectionnumber: 1.1
description: >
  Kubevirt Configuration
---


## KubeVirt Installation

On the kubernetes cluster used for this training the following operators have been installed.

| Operator Name                    | Namespace  |
|----------------------------------|------------|
| KubeVirt                         | kubevirt   |
| Containerized Data Impoter (CDI) | cdi        |

As the configuration and the required feature flags are subject to change we do not highlight them on every section.


### Emulation

This cluster is using emulation. This has an impact on the VM performance.
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


### Enabled FeatureFlags

In the cluster the following kubevirt feature flags are enabled.

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
```

