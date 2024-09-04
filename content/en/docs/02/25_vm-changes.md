---
title: "2.5 Changing files"
weight: 250
labfoldernumber: "02"
sectionnumber: 2.5
description: >
  Changing files in your running VM.
---

In the previous section we gained access to the vm console. In this section we will use this access to make a change
to our running vm and observe what happens if we restart the VM.


### {{% task %}} Create a File

Head over to your vm console with:
```shell
virtctl console {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

Login with the specified credentials and create a file:

```shell
touch myfile
```

And verify that the file really is present:

Check the file status with:
```shell
stat myfile
```

Exit the console and restart your vm with:

```shell
virtctl restart {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

The output should be:

```shell
VM {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm was scheduled to restart
```

Ask yourself:

* After restarting, is the created file still present?
* If yes or no, why?

{{% details title="Task Hint" %}}

Check yourself with entering the console again with:
```shell
virtctl console {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

Check the file status with:
```shell
stat myfile
```

The output fill be:
```shell
stat: can't stat 'myfile': No such file or directory
```

This means that the file is gone. but why?

Do you remember that we added a Container Disk to our VM manifest in the first section? A Container Disk is always
ephemeral and is therefore an easy way to provide a disk wich does not have to be persistent. We will have a closer
look about storage in a later section.
{{% /details %}}


## End of lab

{{% alert title="Cleanup resources" color="warning" %}}  {{% param "end-of-lab-text" %}}

Stop your running VM with
```shell
virtctl stop {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```
{{% /alert %}}

