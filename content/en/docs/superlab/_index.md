---
title: "Super Lab"
weight: 9
labfoldernumber: "09"
description: >
 Deploy a sample application mixing virtual machines and containerized workload.
---

In this section we will deploy a Fedora based virtual machine hosting a MariaDB database. We will also deploy a simple
containerized web application which accesses the virtual machine using the default kubernetes pod network.


## Lab goals

* Build your own sample application using concepts like
  * VM disk creation using DataVolumes
  * Disk preparation using provisioning virtual machines
  * Cloud-Init startup scripts
  * Instance types and preferences
  * Mounting secrets and additional disks
  * Exposing ports using services
  * Mixing virtual machines workload and containers workload
  * Provide metrics for prometheus monitoring
