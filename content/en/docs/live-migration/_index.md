---
title: "Live Migration"
weight: 7
labfoldernumber: "07"
sectionnumber: 7
description: >
  Migrate running VMs to other Nodes for maintenance or other reasons
---

In this section we will get familiar with the concept of the Live Migration capabilities in KubeVirt.

The idea of live migration is a familiar one in virtualization platforms, allowing administrators to keep workloads operational while servers are taken offline for various reasons, such as:

* Hardware maintenance (e.g., physical repairs, firmware updates)
* Power management by consolidating workloads onto fewer hypervisors during off-peak times
* And more

Similarly, KubeVirt offers the ability to migrate virtual machines within Kubernetes when this feature is enabled.


## Lab Goals

* Know what the Concept of Live Migration is
* Understand when workload can be live migrated and when not
* Execute a live migration
