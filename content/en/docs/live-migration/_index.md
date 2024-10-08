---
title: "Live migration"
weight: 7
labfoldernumber: "07"
description: >
  Migrate running VMs to other nodes for maintenance or other reasons
---

In this section we will get familiar with KubeVirt's live migration concept and capabilities.

The idea of live migration is a familiar one on virtualization platforms, allowing administrators to keep workload operational while servers are taken offline for various reasons, such as:

* Hardware maintenance (e.g., physical repairs, firmware updates)
* Power management by consolidating workloads onto fewer hypervisors during off-peak times
* And more

Similarly, KubeVirt offers the ability to migrate virtual machines within Kubernetes when this feature is enabled.


## Lab goals

* Know what the concept of live migration is
* Understand when workload can be live-migrated and when not
* Perform a live migration
