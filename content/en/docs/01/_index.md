---
title: "1. Lab Environment"
weight: 1
labfoldernumber: "01"
sectionnumber: 1
---


## Login

{{% alert title="Note" color="info" %}} Authentication depends on the specific Kubernetes cluster environment. You may need special instructions if you are not using our lab environment. Details will be provided by your teacher. {{% /alert %}}


## Webshell

The provided lab environment contains an _Eclipse Theia IDE_[^1]. Your IDE will look something like this:

![Eclipse Theia IDE](theia.png)

* On the left side you can open the file explorer
* The Terminal is accessible using `Ctrl+Shit+^` or using the Menubar `Terminal > New Terminal`

The available environment in the webshell contains all the needed tools like `kubectl` and `virtctl` as well as
the configuration needed to access the kubernetes cluster. If you have a terminal running you can interact with the
kubernetes cluster. For example, you can list your context or get the pods of the current namespace:

```shell
theia(user4) /home/project $ kubectl config get-contexts
CURRENT   NAME    CLUSTER   AUTHINFO   NAMESPACE
          local   local     local      user4
          
theia(user4) /home/project $ kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
user4-webshell-885dbc579-lwhtd   2/2     Running   0          11d
```

You can create files within your webshell or using the file explorer. Using the shell they will show up in the file
explorer and vice versa. Your workplace is persistent and is available for the whole training duration.


### Exiting a console of a virtual machine

In various labs we will connect to the console of a virtual machine using the `virtctl console`. Your terminal will look like this:

```shell
virtctl console kubevirtvm
```

When the terminal is connected to the virtual machine vm the following line appears:
```shell
Successfully connected to kubevirtvm console. The escape sequence is ^
```

This simple escape sequence `^` does not work within the webshell terminal. You have the following options to exit the console:

* Press `Ctrl+AltGr+]]` (yes, press `]` twice)
* Close the webshell terminal and open a new one with `Ctrl+Shift+^`


## Namespace

We're going to use the following Namespace for the labs

* `<user>` where we deploy our Virtual Machines.

Alternatively there is a namespace `<user>-dev` available.

{{% alert title="Note" color="info" %}}
By using the following command, you can switch into another Namespace instead of specifying it for each `kubectl` command.

```bash
kubectl config set-context $(kubectl config current-context) --namespace <namespace>
```

If you get the following error from the command above you first have to initially set your current context:
```shell
error: current-context is not set
error: you must specify a non-empty context name or --current
```

Set the current context with:
```shell
kubectl config use-context local
```

Some prefer to explicitly select the Namespace for each `kubectl` command by adding `--namespace <namespace>` or `-n <namespace>`.
{{% /alert %}}


## General Lab Notes


### Placeholders

In this lab we will use the following placeholders or naming conventions:

* `$USER` your username (for example `user4`)
* `[...]` means that some lines in the listing or command have been omitted for readability.  


### Hints

We usually provide help for a task you have to complete. For example if you have to implement a method you most likely find the solution in a _Task Hint_ like this one:

{{% details title="Task Hint" %}}
Your yaml should look like this:

```yaml
kind: VirtualMachine
metadata:
  name: kubevirtvm
spec:
  running: false
  template:
    spec:
      domain:
        devices: {}
        memory:
          guest: 64Mi
        resources: {}
status: {}
```
{{% /details %}}


### Highlighting important things

We will use the following styling to highlight various things.

{{% alert title="Node" color="info" %}} This is an information providing some additional help or information {{% /alert %}}

{{% alert title="Important" color="warning" %}} This is an important note which you should read and follow.  {{% /alert %}}

{{% alert title="Alert" color="danger" %}} This is an alert or important warning. You should carefully read and follow the details. {{% /alert %}}

[^1]: [Eclipse Theia IDE Project](https://theia-ide.org/)
