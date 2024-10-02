---
title: "Cloud-init"
weight: 42
labfoldernumber: "04"
description: >
  Use cloud-init to initialize your VM
---

In this section we will use cloud-init to initialize a Fedora Cloud[^1] VM. Cloud-init is the de-facto standard for providing
startup scripts to VMs.

Cloud-init is widely adopted. Some of the known users of cloud-init are:

* Ubuntu
* Arch Linux
* CentOS
* Red Hat
* FreeBSD
* Fedora
* Gentoo Linux
* openSUSE


## Supported data sources

KubeVirt supports the `cloudInitNoCloud` and `cloudInitConfigDrive` data source methods.

{{% alert title="Note" color="info" %}}
As it is the simplest data source you should stick to `cloudInitNoCloud` as the go to data source. Only if `cloudInitNoCloud` is not supported
by the cloud-init implementation you should switch to `cloudInitConfigDrive`. For example the implementation of coreos-cloudinit was known to
require the `cloudInitConfigDrive` data source. However, as CoreOS has built Ignition this implementation is superseded but there
may be more implementations.
{{% /alert %}}


### `cloudInitNoCloud` data source

`cloudInitNoCloud` is a flexible data source to configure an instance locally. It can work without network access but can also
fetch configuration from a remote server. The relevant configuration of a `cloudInitNoCloud` data source in a VM looks like this:

```yaml
volumes:
  - name: cloudinitdisk
    cloudInitNoCloud:
      userData: "#cloud-config"
[...]
```

This volume must be referenced after the VM disk in the `spec.template.spec.domain.devices.disks` section:

```yaml
- name: cloudinitdisk
  disk:
    bus: virtio
```

Using the `cloudInitNoCloud` attribute gives us the following possibilities to provide our configuration:

* `userData`: inline `cloudInitNoCloud` configuration in the user data format
* `userDataBase64`: `cloudInitNoCloud` configuration in the user data format as a base64-encoded string
* `secretRef`: reference to a K8s Secret containing `cloudInitNoCloud` userdata
* `networkData`: inline `cloudInitNoCloud` network data
* `networkDataBase64`: `cloudInitNoCloud` network data as a base64-encoded string
* `networkDataSecretRef`: reference to a K8s Secret containing `cloudInitNoCloud` network data

The most convenient for the lab is to use the `cloudInitNoCloud` user data method.

The user data format recognizes the following headers. Depending on the header, the content is interpreted and executed
differently. For example, if you use the `#!/bin/sh` header the content is treated as an executable shell script.

| User data format     | Content Header                  | Expected Content-Type     |
|----------------------|---------------------------------|---------------------------|
| Cloud config data    | `#cloud-config`                 | text/cloud-config         |
| User data script     | `#!`                            | text/x-shellscript        |
| Cloud boothook       | `#cloud-boothook`               | text/cloud-boothook       |
| MIME multi-part      | `Content-Type: multipart/mixed` | multipart/mixed           |
| Cloud config archive | `#cloud-config-archive`         | text/cloud-config-archive |
| Jinja template       | `## template: jinja`            | text/jinja                |
| Include file         | `#include`                      | text/x-include-url        |
| Part handler         | `#part-handler`                 | text/part-handler         |

If you want to combine multiple items, you can do that using #cloud-config-archive.

Here is an example how to configure multiple items:

```yaml
volumes:
  - name: cloudinitdisk
    cloudInitNoCloud:
      userData: |
        #cloud-config-archive
        - type: "text/cloud-config"
          content: |
            timezone: Europe/Zurich
        - type: "text/x-shellscript"
          content: |
            #!/bin/sh
            yum install -y nginx
```

Check [cloud-init's network configuration sources](https://cloudinit.readthedocs.io/en/latest/reference/network-config.html) for more information about the network data format.
Be aware that there is a different format used whenever you use `cloudInitNoCloud` or `cloudInitConfigDrive`.

{{% alert title="Important" color="warning" %}}
Make sure you use `secretRef` or `networkDataSecretRef` whenever you provide sensitive data like credentials, certificates and so on.
{{% /alert %}}


### `cloudInitConfigDrive` data source

The `cloudInitConfigDrive` data source works identically to the `cloudInitNoCloud` data source by defining:

```yaml
volumes:
- name: cloudinitdisk
  cloudInitConfigDrive:
    userData: "#cloud-config"
[...]
```

The volume must be referenced after the VM disk in the `spec.template.spec.domain.devices.disks` section:

```yaml
- name: cloudinitdisk
  disk:
    bus: virtio
```

When using `cloudInitConfigDrive`, the network data has to be in the [OpenStack Metadata Service Network](https://specs.openstack.org/openstack/nova-specs/specs/liberty/implemented/metadata-service-network-info.html) format.


## {{% task %}} Creating a cloud-init config Secret

We are now going to create a Fedora Cloud VM and provide a cloud-init userdata configuration to initialize our VM.

First, we are going to define our configuration. Create a file called `cloudinit-userdata.yaml` in the folder `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}` with the following content:

```yaml
#cloud-config
password: kubevirt
chpasswd: { expire: False }
```

This will set the password of the default user (`fedora` for Fedora Core) to `kubevirt` and configure the password
to never expire.

We need to create the Secret from this configuration. You can use the following command to create it:

```bash
kubectl create secret generic {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit --from-file=userdata={{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/cloudinit-userdata.yaml --namespace=$USER
```

The output should be:

```
secret/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit created
```

You can inspect the Secret with:

```bash
kubectl get secret {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit -o yaml --namespace=$USER
```

```
apiVersion: v1
data:
  userdata: I2Nsb3VkLWNvbmZpZw[...]
type: Opaque
kind: Secret
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit
[...]
```

It would also be possible to create the Secret as a resource or use a secret management solution. But for the lab it is more
convenient to create it from the raw configuration using the `kubectl` tool.


## {{% task %}} Creating a VirtualMachine using cloud-init

Create a file `vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit.yaml`
in the folder `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}`
and start with the following VM configuration:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit
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
            memory: 2Gi
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
```

Extend the VM configuration to include our Secret `{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit` we created above.

{{% details title="Task Hint: Solution" %}}
Your VirtualMachine configuration should look like this:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit
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
            memory: 2Gi
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
              name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit
```
{{% /details %}}

Make sure you create your VM with:

```bash
kubectl apply -f {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/vm_{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit.yaml --namespace=$USER
```

Start the VM and verify whether logging in with the defined user and password works as expected.

{{% details title="Solution" %}}
Start the newly-created VM. This might take a couple of minutes:

```bash
virtctl start {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit --namespace=$USER
```

Connect to the console and log in as soon as the prompt shows up:

```bash
virtctl console {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit --namespace=$USER
```

You will also see the cloud-init execution messages in the console log during startup:

```bash
[...]
[  OK  ] Started systemd-logind.service - User Login Management.
[  147.604999] cloud-init[796]: Cloud-init v. 23.4.4 running 'init-local' at Fri, 06 Sep 2024 11:42:25 +0000. Up 147.17 seconds.
         Starting systemd-hostnamed.service - Hostname Service...
[...]

[  210.442576] cloud-init[973]: Cloud-init v. 23.4.4 finished at Fri, 06 Sep 2024 11:43:29 +0000. Datasource DataSourceNoCloud [seed=/dev/vdb][dsmode=net].  Up 210.34 seconds
[...]
```

{{% alert title="Note" color="info" %}}
Hit the `Enter` key if the login prompt doesn't show up automatically.
{{% /alert %}}

{{% /details %}}


## {{% task %}} Enhance your startup script

In the previous section we have created a VM using a cloud-init script. Enhance the startup script with the following functionality:

* Set the timezone to `Europe/Zurich`
* Install the nginx package
* Write a custom nginx.conf to `/etc/nginx/nginx.conf`
* Start the nginx service

For the custom nginx configuration, you can use the following content:

```text
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
  worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log  /var/log/nginx/access.log  main;
    
    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;
    
    include             /etc/nginx/mime.types;
    default_type        text/plain;
    
    server {
        listen       80;
        server_name  _;
        root         /usr/share/nginx/html;
        
        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;
        
        location /health {
            return 200 'ok';
        }
        
        location / {
            set $response 'Hello from ${hostname}\n';
            set $response '${response}GMT time:   $date_gmt\n';
            set $response '${response}Local time: $date_local\n';
        
            return 200 '${response}';
        }
    }
}
```

{{% details title="Solution" %}}
Your cloud-init configuration (`cloudinit-userdata.yaml`) will look like this:

```yaml
#cloud-config
password: kubevirt
chpasswd: { expire: False }
packages:
  - nginx
timezone: Europe/Zurich
write_files:
  - content: |
      user nginx;
      worker_processes auto;
      error_log /var/log/nginx/error.log;
      pid /run/nginx.pid;

      events {
        worker_connections 1024;
      }

      http {
          log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
          '$status $body_bytes_sent "$http_referer" '
          '"$http_user_agent" "$http_x_forwarded_for"';

          access_log  /var/log/nginx/access.log  main;

          sendfile            on;
          tcp_nopush          on;
          tcp_nodelay         on;
          keepalive_timeout   65;
          types_hash_max_size 4096;

          include             /etc/nginx/mime.types;
          default_type        text/plain;

          server {
              listen       80;
              server_name  _;
              root         /usr/share/nginx/html;

              # Load configuration files for the default server block.
              include /etc/nginx/default.d/*.conf;

              location /health {
                return 200 'ok';
              }

              location / {
                set $response 'Hello from ${hostname}\n';
                set $response '${response}GMT time:   $date_gmt\n';
                set $response '${response}Local time: $date_local\n';

                return 200 '${response}';
              }
          }
      }
    path: /etc/nginx/nginx.conf
runcmd:
  - systemctl enable nginx
  - systemctl start nginx
```
{{% /details %}}

You need to recreate your Secret:

```bash
kubectl delete secret {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit --namespace=$USER
kubectl create secret generic {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit --from-file=userdata={{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/cloudinit-userdata.yaml --namespace=$USER
```

Next, we need to restart our VM to pick up the changes in the cloud-init configuration:

```bash
virtctl restart {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit --namespace=$USER
```

{{% alert title="Note" color="info" %}}
It may take some minutes until your server is fully provisioned. While booting you may watch out for the message `Reached target cloud-init.target` in your VM's console using:

```bash
virtctl console {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit --namespace=$USER
```
{{% /alert %}}


## {{% task %}} Testing your webserver on your virtual machine

We have spawned a virtual machine that uses cloud-init and installs a simple nginx webserver. Let us test the webserver:

Create the following Kubernetes Service (file: `service-cloudinit.yaml` folder: `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}`):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    kubevirt.io/domain: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit
  type: ClusterIP
```

And create it with:

```bash
kubectl apply -f  {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/service-cloudinit.yaml --namespace=$USER
```

Test your working webserver from your webshell:

```bash
curl -s {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit.$USER.svc.cluster.local
```

You should see an output similar to this:

```
Hello from {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit
GMT time:   Thursday, 22-Aug-2024 14:13:17 GMT
Local time: Thursday, 22-Aug-2024 16:13:17 CEST
```


## {{% task %}} (Optional) Expose the Service

The nginx webserver is now only accessible within our Kubernetes cluster. In this optional lab we are going to expose it to the internet.

For that, we need to create an Ingress resource. Create a file called `ingress-cloudinit.yaml` in the folder `{{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}` with the following content:

```yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit
spec:
  rules:
    - host: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit-<user>.<appdomain>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service: 
                name: {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit
                port: 
                  number: 80
  tls:
  - hosts:
    - {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit-<user>.<appdomain>
```

Make sure all occurrences of

* `<user>` - your username (eg. `user4`)
* `<appdomain>` - ask the trainer

are replaced accordingly, before you create the Ingress by executing:

```bash
kubectl apply -f  {{% param "labsfoldername" %}}/{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}/ingress-cloudinit.yaml --namespace=$USER
```

After that open a new browser tab and enter the URL:
`https://{{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit-<user>.<appdomain>`

Congratulations, you've successfully exposed nginx, running in a Fedora VM on Kubernetes, to the internet!


## End of lab

{{% alert title="Cleanup resources" color="warning" %}}  {{% param "end-of-lab-text" %}}

Stop your running VM with:

```bash
virtctl stop {{% param "labsubfolderprefix" %}}{{% param "labfoldernumber" %}}-cloudinit --namespace=$USER
```
{{% /alert %}}


## References

You can find additional information about cloud-init here:

* [Cloud-init module reference](https://cloudinit.readthedocs.io/en/latest/reference/modules.html#modules)
* [Cloud-init examples](https://cloudinit.readthedocs.io/en/latest/reference/examples.html)

[^1]: [Fedora Cloud](https://fedoraproject.org/cloud/)
