---
title: "2. Getting Started with KubeVirt"
weight: 1
labfoldernumber: "02"
sectionnumber: 2
description: >
  In this section we will create and run our first virtual machine.
---


## Goals of this lab

* Get familiar with the lab environment
* Create your first VM using KubeVirt
* Start and Stop a VM using `virtctl` or `kubectl`
* Connect to the console of the VM
* Expose and access ports of your VM
* Making file changes to you VM and observe behaviour


## Folder structure

This is your first lab where you will create and apply files to the kubernetes cluster. It may make sense to structure
your files according to the labs. Feel free to create a folder structure something like

```text
{{% param "labsfoldername" %}}
|-- {{% param "labsubfolderprefix" %}}01
|-- {{% param "labsubfolderprefix" %}}02
|-- {{% param "labsubfolderprefix" %}}03
[...]
```

if you want to initialize the structure you can do it within your terminal with

```shell
mkdir -p {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{01..{{% param "maxlabnumber" %}}}/
```
