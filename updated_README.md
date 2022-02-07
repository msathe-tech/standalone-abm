# Overview

Do you want to start your beginer to pro journey for Anthos Bare Metal? This tutorial guides you through the process to setup Anthos Bare Metal 1.8.2 on a single GCE instance. No prior understanding of Anthos or Anthos Bare Metal is required. You don't need to be a networking or Kubernetes geek to get started. All you need is a single GCE machine with As long as you have access to Google Cloud you will be able to get up and running.

Install and create a compute GCE disk with a custom image.

## 0. Pre-requisities

1. All of the commands highlighted in this document can be run via Cloud Shell or a linux terminal of your choice. Follow the steps here for enabling Cloud Shell SDK: https://cloud.google.com/sdk/docs/install
**NOTE**: For this workshop, we will be using cloud shell.

2. Click on "Cloud Shell" icon on the top right of your selected GCP project. Please authorize Cloud Shell to make a GCP API Call. 

3. **OPTIONAL**: Allow your GCP project to be authenticated. If you are using Cloud Shell, this step can be skipped. Please run 
`$ gcloud auth login` to obtain new credentials. Or if you have already logged in with a different account use `$ gcloud config set account ACCOUNT` to select an already authenticated account to use.

4. Once your account is set, set the `project` property through `gcloud config set project [myProject]`. **NOTE** Change `[myProject] and use your designated project ID instead of the project NAME.

5. Please update your preferred region and zone through: `gcloud config set compute/zone [myRegion]`. **NOTE** Change `[myRegion]`. For instance, `us-central-a` is the region of our choice. Next, Enable the API [compute.googleapis.com] on your project.


## I. Create a GCE instance using custom image

These steps will first create a SSD persistent disk storage and its associated image which will be used as the boot disk stoage. Finally, you will provision a GCE instance which 

1. Run the following command to create a storage disk with 200 GB disk size with a PD-SSD disk type: 

```
$ gcloud compute disks create abmvirt-disk --image-project=ubuntu-os-cloud --image-family=ubuntu-2004-lts --size=200G --type=pd-ssd
```

Once deployed, the output should look similar to this:

```
Created [https://www.googleapis.com/compute/v1/projects/anjali-test/zones/us-central1-a/disks/abmvirt-disk].
WARNING: Some requests generated warnings:
 - Disk size: '200 GB' is larger than image size: '10 GB'. You might need to resize the root repartition manually if the operating system does not support automatic resizing. See https://cloud.google.com/compute/docs/disks/add-persistent-disk#resize_pd for details.

NAME: abmvirt-disk
ZONE: us-central1-a
SIZE_GB: 200
TYPE: pd-ssd
STATUS: READY
```

2. Next, create a compute image against the newly created storage disk:

```
$ gcloud compute images create abmvirt-image --source-disk abmvirt-disk --licenses "https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"
```

Once deployed, the output should look similar to this:

```
Created [https://www.googleapis.com/compute/v1/projects/anjali-test/global/images/abmvirt-image].
NAME: abmvirt-image
PROJECT: anjali-test
FAMILY:
DEPRECATED:
STATUS: READY
```

3. Before proceeding to create your GCE instance, ensure you have a VPC network. For this workshop, please create a default network through the following command. **NOTE**: Please replace `myProject` with your project ID.

```
$ gcloud compute networks create default --project=[myProject] --subnet-mode=auto --mtu=1460 --bgp-routing-mode=regional
```

Output should look like something similar:

```
Created [https://www.googleapis.com/compute/v1/projects/helloworld-hjkt/global/networks/default].
NAME: default
SUBNET_MODE: AUTO
BGP_ROUTING_MODE: REGIONAL
IPV4_RANGE:
GATEWAY_IPV4:
...
```

3. Create a firewall rule on the `default` vpc network to allow the following TCP ports of: 22, 3389, 443 and PING.

```
$ gcloud compute firewall-rules create custom-allow-ssh --network default --allow tcp:22,tcp:3389,tcp:443,tcp:8080,icmp
```

Output should look like something similar:

```
Creating firewall...working..Created [https://www.googleapis.com/compute/v1/projects/helloworld-001-340616/global/firewalls/custom-allow-ssh].
Creating firewall...done.
NAME: custom-allow-ssh
NETWORK: default
DIRECTION: INGRESS
PRIORITY: 1000
ALLOW: tcp:22,tcp:3389,tcp:443,tcp:8080,icmp
DENY:
DISABLED: False
```

4. Finally, create the GCE instance and attach the storage disk from the above steps:  

```
$ gcloud compute instances create abm-on-gce --image abmvirt-image --can-ip-forward --network default --tags http-server,https-server --min-cpu-platform "Intel Haswell" --scopes cloud-platform --machine-type n1-standard-32
```

Once deployed, the output should look similar to this: 

```
Created [https://www.googleapis.com/compute/v1/projects/anjali-test/zones/us-central1-a/instances/abm-on-gce].
NAME: abm-on-gce
ZONE: us-central1-a
MACHINE_TYPE: n1-standard-32
PREEMPTIBLE:
INTERNAL_IP: 10.128.0.6
EXTERNAL_IP: 34.122.30.121
STATUS: RUNNING
```

When your GCE instance is up and running, you will see there are two disk types associated with this instance. One is a the persistent SSD called `abmvirt-disk` and another standard persistent disk type called `abm-on-gce`. We are working on improving the experience of not having 2 storage disks.

## II: Login to the newly created GCE Instance

1. SSH into the newly created GCE instance

```
$ gcloud compute ssh abm-on-gce
```

If a public/private key for SSH does not exist for gcloud, go ahead and generate one. You can keep the passphrase as empty.
Once you're allowed SSH access, the output will look something like this:

```
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.11.0-1028-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Tue Feb  1 19:39:26 UTC 2022

  System load:  0.16               Processes:             344
  Usage of /:   0.9% of 193.66GB   Users logged in:       0
  Memory usage: 0%                 IPv4 address for ens4: 10.128.0.6
  Swap usage:   0%


1 update can be applied immediately.
To see these additional updates run: apt list --upgradable


The list of available updates is more than a week old.
To check for new updates run: sudo apt update

anjalikhatri@abm-on-gce:-$
```

2. Clone the following GIT repository and get started with setting up Anthos Bare Metal. 

```
$ git clone https://github.com/msathe-tech/standalone-abm.git
```

Output will look something like this:

```
Cloning into 'standalone-abm'...
remote: Enumerating objects: 63, done.
remote: Counting objects: 100% (63/63), done.
remote: Compressing objects: 100% (55/55), done.
remote: Total 63 (delta 31), reused 26 (delta 6), pack-reused 0
Unpacking objects: 100% (63/63), 18.80 KiB | 1013.00 KiB/s, done.
```

## III: Continue the configuration of the GCE instance to prep for ABM Install

1. Setup the GCE environment and install the necessary updates and jq binaries

```
$ sudo apt-get update -y
$ sudo apt install jq -y
```

2. Authentication your gcloud for login against your user profile and project ID.

```
$ gcloud auth application-default login
$ gcloud auth login
```

3. Update access permissions for the following set environment script and make a note of your IP address:

```
$ cd standalone-abm
$ chmod +x setenv.sh
```

4. Edit the `setenv.sh` script to your current home path. 

Please update Line 6 with your assigned Argolis principal name. For instance, if your id is: `ubuntu@anjalikhatri.altostrat.com` the value will be `ubuntu`.
```
#!/bin/bash
# IMP: Please change the ens4 to use correct network interface name in the following command.
# It should be the interface which has your IP on the subnet.
export CURRENT_IP=$(ip --json a show dev ens4 | jq '.[0].addr_info[0].local' -r)
echo INSTANCE_IP=$CURRENT_IP
export ARGOLIS_NAME=ubuntu  ###Replace this value with your Argolis name
export GCE_CLUSTER_PATH=${ARGOLIS_NAME}_anjalikhatri_altostrat_co
echo USERNAME=$GCE_CLUSTER_PATH
export PATH=$PATH:/home/$GCE_CLUSTER_PATH
export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.config/gcloud/application_default_credentials.json
echo $GOOGLE_APPLICATION_CREDENTIALS
export PROJECT_ID=$(gcloud config get-value project)
export CLUSTER_NAME=abm-cluster
echo PROJECT_ID=$PROJECT_ID
#export KUBECONFIG=/home/${GCE_CLUSTER_PATH}/bmctl-workspace/${CLUSTER_NAME}/${CLUSTER_NAME}-kubeconfig
#echo $KUBECONFIG
```

5. Run the script

```
$ . ./setenv.sh
```

The output should look similar to the following:
```
$ . ./setenv.sh
INSTANCE_IP=10.128.0.2
USERNAME=ubuntu_anjalikhatri_altostrat_co
/home/ubuntu_anjalikhatri_altostrat_co/.config/gcloud/application_default_credentials.json
PROJECT_ID=helloworld-001-340616
```

6. Next, setup the VXLAN on the GCE instance. To get started, chmod permissions on the vxlan script, logged in as root.

```
$ cd ~
$ sudo bash
$ cd standalone-abm
$ chmod +x vxlan.sh
```

4. Run the command `ip a` and make a note of your network interface and use the one that shows for your IP address. 

5. Update line 7 within the `vxlan.sh` script with the network interface name. 
In my instance, it should be `ens4` instead of `eno1`.

6. Next, run the script and ensure you get a successful ping against the vxlan IP of 10.200.0.2. A successful ping confirms your vxlan setup is complete.

```
$ ./vxlan.sh
```

Output should look like something similar:

```
<<REDACTED>>
64 bytes from 10.200.0.2: icmp_seq=97 ttl=64 time=0.035 ms
64 bytes from 10.200.0.2: icmp_seq=98 ttl=64 time=0.035 ms
64 bytes from 10.200.0.2: icmp_seq=99 ttl=64 time=0.036 ms
^C
--- 10.200.0.2 ping statistics ---
99 packets transmitted, 99 received, 0% packet loss, time 100353ms
rtt min/avg/max/mdev = 0.021/0.037/0.055/0.004 ms
```

### A: Setup SSH Access for GCE default (non-root) user and enable passwordless SSH private access to your machine

1. Exit from `root` user
```
$ exit 
```

2. Generate RSA Keygen. Don't enter any passphrase (leave empty) and use the default file paths.
Perform this setp for BOTH non-root AND root user.

```
$ ssh-keygen 
$ cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

Verify you can login without password, you can find the IP address and username from `setenv.sh` script from seciton III, step 5. 
For instance, it should be like `ssh ubuntu_anjalikhatri_altostrat_co@10.128.0.2` for non-root user.
For instance, it should be like `ssh root@10.128.0.2` for root user.

```
$ ssh [your-username]@[ip-address-of-your-machine] 
$ exit 
```

### B: Install Docker and make it available as non-root user

1. Install docker on GCE

```
$ sudo apt-get install -y docker
$ sudo apt-get install -y docker.io
```

2. Add docker to a group and existing user profile

```
$ sudo groupadd dockerdock
$ sudo usermod -aG docker $USER
```

3. Confirm docker is running and its latest version

```
$ newgrp docker 
$ docker run hello-world
```

4. Validate the version of Docker:
```
$ docker -v
Docker version 20.10.7, build 20.10.7-0ubuntu5~20.04.2
```

### C: Setup the CTL for ABM

1. Install and setup the BMCTL 

```
$ cd ~
$ gsutil cp gs://anthos-baremetal-release/bmctl/1.8.2/linux-amd64/bmctl bmctl
$ chmod a+x bmctl
```

### D: Create the ABM Cluster Configuration file

1. Set the following environment variable for your exisitng project ID, ABM cluster name. 

   **NOTE**: Change the name in accordance to your project ID.

```
ARGOLIS_NAME=ubuntu ###Replace this value with your argolis user.
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME=abm-cluster
GCE_CLUSTER_PATH=${ARGOLIS_NAME}_anjalikhatri_altostrat_co
```

**Can Skip, since this was done earlier**
2. Ensure you've enabled auth for your GCP service by following the steps here
```
$ gcloud auth login --update-adc
```

2. Create the ABM configuration
```
$ cd $HOME
$ ./bmctl create config -c $CLUSTER_NAME --enable-apis --create-service-accounts --project-id=$PROJECT_ID
```
ls
Output should look similar to this:

```
$ ./bmctl create config -c $CLUSTER_NAME --enable-apis --create-service-accounts --project-id=$PROJECT_ID
[2022-02-04 15:32:44+0000] Enabling APIs for GCP project helloworld-hjkt

[2022-02-04 15:32:47+0000] Creating service accounts with keys for GCP project helloworld-hjkt

[2022-02-04 15:32:53+0000] Service account keys stored at folder bmctl-workspace/.sa-keys

[2022-02-04 15:32:53+0000] Created config: bmctl-workspace/abm-cluster/abm-cluster.yaml
```

3. Use the following script `single-gce-abm-with-vxlan.yaml` as a reference to populate the ABM cluster configuration file.

```
cp standalone-abm/single-gce-abm-with-vxlan.yaml bmctl-workspace/$CLUSTER_NAME/$CLUSTER_NAME.yaml
```

4. Open up the 

### E. Create ABM Cluster

1. Follow the steps below to create your ABM cluster

```
sudo bash
gcloud auth application-default login
. ./standalone-abm/setenv.sh
./bmctl create cluster -c abm-cluster
```

Output for the cluster creation should look like this
```
# ./bmctl create cluster -c abm-cluster
Please check the logs at bmctl-workspace/abm-cluster/log/create-cluster-20220205-002259/create-cluster.log
[2022-02-05 00:23:09+0000] Creating bootstrap cluster... OK
[2022-02-05 00:24:23+0000] Installing dependency components... OK
[2022-02-05 00:25:21+0000] Waiting for preflight check job to finish... OK
[2022-02-05 00:26:41+0000] - Validation Category: machines and network
[2022-02-05 00:26:41+0000]      - [PASSED] node-network
[2022-02-05 00:26:41+0000]      - [PASSED] 10.200.0.2
[2022-02-05 00:26:41+0000]      - [PASSED] 10.200.0.2-gcp
[2022-02-05 00:26:41+0000]      - [PASSED] gcp
[2022-02-05 00:26:41+0000] Flushing logs... OK
[2022-02-05 00:26:42+0000] Applying resources for new cluster
[2022-02-05 00:26:42+0000] Waiting for cluster to become ready OK
[2022-02-05 00:32:42+0000] Writing kubeconfig file
[2022-02-05 00:32:42+0000] kubeconfig of created cluster is at bmctl-workspace/abm-cluster/abm-cluster-kubeconfig, please run
[2022-02-05 00:32:42+0000] kubectl --kubeconfig bmctl-workspace/abm-cluster/abm-cluster-kubeconfig get nodes
[2022-02-05 00:32:42+0000] to get cluster node status.
[2022-02-05 00:32:42+0000] Please restrict access to this file as it contains authentication credentials of your cluster.
[2022-02-05 00:32:42+0000] Waiting for node pools to become ready OK
[2022-02-05 00:33:02+0000] Moving admin cluster resources to the created admin cluster
I0205 00:33:04.006110  104440 request.go:655] Throttling request took 1.037944195s, request: GET:https://10.200.0.49:443/apis/baremetal.cluster.gke.io/v1?timeout=30s
I0205 00:33:14.296632  104440 request.go:655] Throttling request took 1.038154681s, request: GET:https://10.200.0.49:443/apis/events.k8s.io/v1beta1?timeout=30s
I0205 00:33:24.327507  104440 request.go:655] Throttling request took 1.423030881s, request: GET:https://10.200.0.49:443/apis/cluster.x-k8s.io/v1alpha2?timeout=30s
I0205 00:33:34.355850  104440 request.go:655] Throttling request took 1.839398199s, request: GET:https://10.200.0.49:443/apis/networking.k8s.io/v1?timeout=30s
I0205 00:33:45.111635  104440 request.go:655] Throttling request took 1.038563488s, request: GET:https://10.200.0.49:443/apis/certificates.k8s.io/v1?timeout=30s
I0205 00:33:55.128709  104440 request.go:655] Throttling request took 1.437699603s, request: GET:https://10.200.0.49:443/apis/snapshot.storage.k8s.io/v1?timeout=30s
I0205 00:34:05.144655  104440 request.go:655] Throttling request took 1.836807193s, request: GET:https://10.200.0.49:443/apis/acme.cert-manager.io/v1?timeout=30s
I0205 00:34:15.161963  104440 request.go:655] Throttling request took 1.636866451s, request: GET:https://10.200.0.49:443/apis/scheduling.k8s.io/v1beta1?timeout=30s
[2022-02-05 00:34:18+0000] Waiting for node update jobs to finish OK
[2022-02-05 00:35:58+0000] Flushing logs... OK
[2022-02-05 00:35:58+0000] Deleting bootstrap cluster... OK
```

2. Go back to the `setenv.sh` script and uncomment lines 15 and 16 and update the parameters for project ID and cluster name.

It should look something like this:
```
export KUBECONFIG=/home/${GCE_CLUSTER_PATH}/bmctl-workspace/${CLUSTER_NAME}/${CLUSTER_NAME}-kubeconfig
echo $KUBECONFIG
```

### F: Login to Anthos console

1. Now that Anthos is installed, you need to update your $PATH to specify the newly generated Kube Config file for ABM cluster. Execute these steps in both `non-root` and `root` user.

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

2. Generate a toke for Anthos Console Login.

```
chmod +x login-token.sh
./login-token.sh
```

3. Navigate to Anthos console, click the name of your server, on the right hand panel click Login, select the Bearer token option. Use the token above here and login to the cluster.

4. Setup stackdriver monitoring and logging for workloads, enable Prometheus metrics capture for apps

```
kubectl patch stackdriver stackdriver --type=merge -p '{"spec":{"scalableMonitoring": false}}' -n kube-system
kubectl patch stackdriver stackdriver --type=merge -p '{"spec":{"enableStackdriverForApplications": true}}' -n kube-system
```

Output will look something similar:

```
$ kubectl patch stackdriver stackdriver --type=merge -p '{"spec":{"scalableMonitoring": false}}' -n kube-system --kubeconfig=$HOME/.kube/abm-cluster-kubeconfig
stackdriver.addons.sigs.k8s.io/stackdriver patched

$ kubectl patch stackdriver stackdriver --type=merge -p '{"spec":{"enableStackdriverForApplications": true}}' -n kube-system --kubeconfig=$HOME/.kube/abm-cluster-kubeconfig
stackdriver.addons.sigs.k8s.io/stackdriver patched
```

4. Get a status of the running pods 

```
$ kubectl get po -n kube-system
NAME                                                        READY   STATUS        RESTARTS   AGE
anet-operator-57cb7b979b-77qt7                              1/1     Running       0          33m
anetd-bxv44                                                 1/1     Running       0          33m
anthos-cluster-operator-776cbfb748-fgxws                    2/2     Running       0          32m
anthos-multinet-controller-5c6bcb85d-d6r7x                  1/1     Running       0          32m
cap-controller-manager-777fc99b75-vxg6l                     2/2     Running       0          32m
clientconfig-operator-69c54567c-vtpfb                       1/1     Running       0          32m
core-dns-autoscaler-cf765587-qg6kk                          1/1     Running       0          32m
coredns-7969dcc8cb-gjshz                                    1/1     Running       0          31m
csi-snapshot-controller-5556cbf9db-6gr9z                    1/1     Running       0          32m
csi-snapshot-validation-79cf5bd895-jlq7s                    1/1     Running       0          32m
etcd-abm-on-gce                                             1/1     Running       0          33m
etcd-defrag-qtbs5                                           1/1     Running       0          32m
haproxy-abm-on-gce                                          1/1     Running       1          33m
keepalived-abm-on-gce                                       1/1     Running       1          33m
kube-apiserver-abm-on-gce                                   1/1     Running       0          33m
kube-control-plane-metrics-proxy-sfh7r                      1/1     Running       0          31m
kube-controller-manager-abm-on-gce                          1/1     Running       0          33m
kube-proxy-tdz7x                                            1/1     Running       0          33m
kube-scheduler-abm-on-gce                                   1/1     Running       0          33m
kube-state-metrics-67d8f6bb4-h9qxt                          1/1     Running       0          31m
localpv-p7zlh                                               1/1     Running       0          32m
metallb-controller-64d846c6d4-9xvwf                         1/1     Running       0          32m
metallb-speaker-7g6z9                                       1/1     Running       0          32m
metrics-server-65cdc7466f-lfl2t                             2/2     Running       0          31m
metrics-server-operator-77669cd95b-tmllh                    1/1     Running       0          32m
node-exporter-4svq2                                         1/1     Running       0          31m
sp-anthos-static-provisioner-5d58d7bf9c-cc7dl               2/2     Running       0          32m
stackdriver-log-forwarder-sgpp2                             1/1     Terminating   0          31m
stackdriver-metadata-agent-cluster-level-59c566db8d-7j6zf   1/1     Running       0          41s
stackdriver-operator-689f98bc98-6phjv                       1/1     Running       0          32m
stackdriver-prometheus-app-0                                2/2     Running       0          41s
stackdriver-prometheus-k8s-0                                2/2     Running       0          82s
```
