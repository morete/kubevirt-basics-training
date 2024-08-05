---
title: "1. Lab Environment"
weight: 1
sectionnumber: 1
---


## Login

{{% alert title="Note" color="info" %}} Authentication depends on the specific Kubernetes cluster environment. You may need special instructions if you are not using our lab environment. Details will be provided by your teacher. {{% /alert %}}


## Webshell

The provided lab environment contains an Eclipse Theia IDE webshell. Within this webshell you can open a terminal with `Terminal > New Terminal` or `Ctrl+Shift+^`. The available environment contains the needed tools like `kubectl` and `virtctl` as well as the configuration needed to access the kubernetes cluster.

### Exiting a console of a virtual machine

In various labs we will connect to the console of a virtual machine using the `virtctl console `. Your terminal will look like this:

```shell
virtctl console kubevirtvm
```

When the terminal is connected to the virtual machine vm the following line appears:
```shell
Successfully connected to kubevirtvm console. The escape sequence is ^
```

This simple escape sequence `^` does not work within the webshell terminal. You have the following options to exit the console:

- Press `Ctrl+AltGr+]]` (yes, press `]` twice)
- Close the webshell terminal and open a new one with `Ctrl+Shift+^`


## Namespace

We're going to use the following Namespace for the labs

- `<user>` where we deploy our Virtual Machines.

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

### Hints

We usually provide help for a task you have to complete. For example if you have to implement a method you most likely find the solution in a _Task Hint_ like this one:

{{% details title="Task Hint" %}}
Your yaml should look like this:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: kubevirtvm
spec:
  running: false
  template:
    spec:
      domain:
        devices:
          disks:
            - name: containerdisk
              disk:
                bus: virtio
          interfaces:
            - name: default
              masquerade: {}
        resources:
          requests:
            memory: 64M
      networks:
        - name: default
          pod: {}
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/kubevirt/cirros-container-disk-demo
```
{{% /details %}}
