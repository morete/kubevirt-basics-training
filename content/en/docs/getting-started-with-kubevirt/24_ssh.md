---
title: "Exposing VM Ports"
weight: 14
labfoldernumber: "01"
sectionnumber: 1.4
description: >
  Accessing ports of the running virtual machine
---

In the previous section we accessed our VM console using the `virtctl` tool. In this section we will expose the SSH port
of our VM and access it directly.

{{% alert title="Note" color="info" %}}
This can be done for any port you want to use. For example if your virtual machine provides a webserver you can expose
the webserver port.
{{% /alert %}}


## Checking available Services

As you see with the following command creating the VM does not create any kubernetes service for it.
```shell
kubectl get service --namespace=$USER
```

In your namespace you should only see the service of your webshell:
```shell
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
$USER-webshell   ClusterIP   10.43.248.212   <none>        3000/TCP   1d
```


## Exposing port 22(ssh) on the kubernetes pod network

To access the SSH port from the kubernetes default pod network we have to create a simple service.
For this we use a Service of type `ClusterIP`.

The needed configuration for the kubernetes `Service` looks like this. Create a file `svc_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm-ssh.yaml` in the `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}` directory and use the following yaml configuration.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm-ssh
spec:
  ports:
  - port: 22
    protocol: TCP
    targetPort: 22
  selector:
    kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm
    kubevirt.io/size: small
  type: ClusterIP
```

Apply the service with:
```shell
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/svc_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm-ssh.yaml --namespace=$USER
```

You may now log in from your webshell terminal to the ssh port of the virtual machine using the following command (password: `gocubsgo`):
```shell
ssh cirros@{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm-ssh.$USER.svc.cluster.local
```

{{% alert title="Note" color="info" %}}
We could also use the `virtctl` command to create a service for us. The command for the service above would be:

```shell
virtctl expose vmi {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --name={{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm-ssh --port=22 --namespace=$USER
```

We will use this approach in the next section.
{{% /alert %}}


## Exposting SSH port for external use

Our exposed Service with type `ClusterIP` is only reachable from within the kubernetes cluster. On our kubernetes
cluster we can expose the port 22(ssh) as a `NodePort` service to access it from the outside of the cluster.

This time we will use the `virtctl` command to expose the port as type `NodePort`. Us this command to create the Service:

```shell
virtctl expose vmi {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm --name={{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm-ssh-np --port=22 --type=NodePort --namespace=$USER
```

If you check your services you should now see both services for your VM:
```shell
kubectl get service --namespace=$USER
```

Which should produce a similar output:
```shell
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-firstvm-ssh   ClusterIP   10.43.89.29     <none>        22/TCP         17m
{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-ssh-np        NodePort    10.43.223.242   <none>        22:32664/TCP   49s
$USER-webshell      ClusterIP   10.43.248.212   <none>        3000/TCP       1d
```

With this, our service is reachable from every node on the indicated port. You may check the PORT(S) column for the
assigned Port. In this example our assigned NodePort is `32664/TCP` which targets port 22 on our VM.

To connect to the NodePort we actually need to know the IPs of our worker-nodes. You can directly get the IPs with:
```shell
kubectl get nodes --selector=node-role.kubernetes.io/master!=true -o jsonpath={.items[*].status.addresses[?\(@.type==\"ExternalIP\"\)].address} --namespace=$USER
```

Which will produce a similar output to this:
```shell
188.245.73.202 116.203.61.242 159.69.207.154
```

{{% alert title="Note" color="info" %}}
You can also see the IPs of the nodes using:

```shell
kubectl get nodes -o wide
```
{{% /alert %}}

Since the NodePort Service is accessible on any worker node you can simply pick one IP and issue the following command
from within your webshell (make sure you replace the IP and the assigned NodPort to match your details):
```shell
ssh cirros@188.245.73.202 -p 32664
```

Using the NodePort is also possible from the outside. You should be able to use the same command from outside your
webshell (for example from your Computer).
