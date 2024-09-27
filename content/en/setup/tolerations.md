---
title: "Tolerations"
weight: 13
type: docs
description: >
  Used taints and tolerations on the lab cluster.
onlyWhen: tolerations
---


## Necessary tolerations

Our lab cluster uses tainted nodes, therefore some of the to-be-applied manifests will need a toleration.
The labs will tell you when to use it, but you can always find it here as an easy reference:


```yaml
[...]
tolerations:
  - effect: NoSchedule
    key: baremetal
    operator: Equal
    value: "true"
[...]
```
