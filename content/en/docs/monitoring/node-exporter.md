---
title: "Prometheus Node Exporter"
weight: 84
labfoldernumber: "08"
description: >
  Monitoring VMs using the Node Exporter
---

The Prometheus Node Exporter is a key component used for collecting operating system metrics from Linux and Windows systems. It exposes a wide range of system-level metrics that Prometheus can scrape, making it useful for monitoring the health and performance of physical and virtual machines.

Some of the key metrics collected by Node Exporter include:

* CPU usage: Tracks how much CPU time is being used by user and system processes.
* Memory usage: Monitors free and used memory, swap space, and buffer/cache utilization.
* Disk I/O: Provides insights into disk read/write operations and storage usage.
* Network statistics: Captures metrics on data sent and received over network interfaces.
* File system usage: Monitors available and used space on file systems.

Node Exporter runs as a lightweight daemon on each node and is easy to install and configure. It works out of the box, exposing most common system metrics through the /metrics endpoint, but can also be extended with additional collectors to gather more specialized data. These metrics can be visualized through tools like Grafana, helping administrators monitor and troubleshoot infrastructure performance.

Together with the other monitoring capabilities, the internal view to OS level metrics that the Node Exporter enables completes the comprehensive monitoring.

The goal of this lab is:

* Installing the Node Exporter binary in a VM
* exposing those Node Exporter metrics on the pod network
* provide capabilities to integrate those white box metrics to an existing prometheus stack.


## {{% task %}} install the Node Exporter using cloud-init

First, we are going to define our `cloud-init` configuration. Create a file called `cloudinit-node-exporter.yaml` in the folder `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}` with the following content:

```yaml
#cloud-config
password: kubevirt
chpasswd: { expire: False }
bootcmd:
  - ["curl", "-o", "/tmp/node_exporter-amd64.tar.gz", "-L", "https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz"]
  - ["sudo", "tar", "xvfz", "/tmp/node_exporter-amd64.tar.gz", "-C", "/tmp/"]
  - ["sudo", "/tmp/node_exporter-1.8.2.linux-amd64/node_exporter"]

```

```bash
kubectl create secret generic {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit-node-exporter --from-file=userdata={{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/cloudinit-node-exporter.yaml --namespace=$USER
```

Create virtual machine, referencing the configuration from above by creating a new file `vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-node-exporter.yaml` in the folder `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/` with the following content:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-node-exporter
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-node-exporter
    spec:
      domain:
        devices:
          disks:
            - name: containerdisk
              disk:
                bus: virtio
            - name: cloudinitdisk
              disk:
                bus: virtio
          interfaces:
          - name: default
            masquerade: {}
        resources:
          requests:
            memory: 1024M
      networks:
      - name: default
        pod: {}
      {{< onlyWhen tolerations >}}tolerations:
        - effect: NoSchedule
          key: baremetal
          operator: Equal
          value: "true"
      {{< /onlyWhen >}}volumes:
        - name: containerdisk
          containerDisk:
            image: {{% param "fedoraCloudCDI" %}}
        - name: cloudinitdisk
          cloudInitNoCloud:
            secretRef:
              name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit-node-exporter
```

Create your VM with:

```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-node-exporter.yaml --namespace=$USER
```

and start it:

```bash
virtctl start {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-node-exporter --namespace=$USER
```


## {{% task %}} Exposing the Node Exporter

We have spawned a virtual machine that uses cloud-init and installs the Node Exporter, which provides Node metrics on the port 9100. Let us test the metrics:

Create the following Kubernetes Service (file: `service-node-exporter.yaml` folder: `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}`):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-node-exporter
spec:
  ports:
  - port: 9100
    protocol: TCP
    targetPort: 9100
  selector:
    kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-node-exporter
  type: ClusterIP
```

And create it with:

```bash
kubectl apply -f  {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/service-node-exporter.yaml --namespace=$USER
```

Test your working webserver from your webshell:

```bash
curl -s http://{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-node-exporter.$USER.svc.cluster.local:9100/metrics
```


## End of lab

{{% alert title="Cleanup resources" color="warning" %}}  {{% param "end-of-lab-text" %}}

Stop the `VirtualMachineInstance`:

```bash
virtctl stop {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-node-exporter   --namespace=$USER
```

{{% /alert %}}
