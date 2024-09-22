---
title: "Accessing the console"
weight: 13
labfoldernumber: "01"
sectionnumber: 1.3
description: >
  Opening a console on your virtual machine
---


## Console Access

If your VM is running you can open a console to the VM using the `virtctl` tool.

First list your VMs to get the name of your VirtualMachine.

```shell
kubectl get vm --namespace=$USER
```

The output should be:

```shell
NAME            AGE   STATUS    READY
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm   10m   Running   True
```


### {{% task %}} Entering the console

Now enter the console with
```shell
virtctl console {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --namespace=$USER
```

Congratulations. You successfully connected to your VMs console. The expected output is:

```shell
Successfully connected to {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm console. The escape sequence is ^]

login as 'cirros' user. default password: 'gocubsgo'. use 'sudo' for root.
training-worker-0 login:
```

{{% alert title="Note" color="info" %}}
You probably have to hit `Enter` to get to the login prompt.
{{% /alert %}}

Now use the default credentials to login.

* User: `cirros`
* Password: `gocubsgo`

And execute a couple of commands
```shell
whoami
ping acend.ch
```

{{% alert title="Note" color="info" %}}
Remember that you have to press `Ctrl+AltGr+]]` (`]` twice) to exit the console.
{{% /alert %}}
