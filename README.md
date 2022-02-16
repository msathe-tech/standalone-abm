# Overview

Do you want to start your beginer to pro journey for Anthos Bare Metal? This tutorial guides you through the process to setup Anthos Bare Metal 1.8.2 on a single GCE instance. No prior understanding of Anthos or Anthos Bare Metal is required. You don't need to be a networking or Kubernetes geek to get started. All you need is a single GCE machine with As long as you have access to Google Cloud you will be able to get up and running.

Install and create a compute GCE disk with a custom image.

## 0. Pre-requisities

1. All of the commands highlighted in this document can be run via Cloud Shell or a linux terminal of your choice. Follow the steps here for enabling Cloud Shell SDK: https://cloud.google.com/sdk/docs/install
**NOTE**: For this workshop, we will be using cloud shell.

2. Click on "Cloud Shell" icon on the top right of your selected GCP project. Please authorize Cloud Shell to make a GCP API Call. 

3. **OPTIONAL**: Allow your GCP project to be authenticated. If you are using Cloud Shell, this step can be skipped. Please run 
`$ gcloud auth login` to obtain new credentials. Or if you have already logged in with a different account use `$ gcloud config set account ACCOUNT` to select an already authenticated account to use.

4. Once your account is set, set the `project` property through `gcloud config set project [myProject]`. **NOTE** Change `[myProject]` and use your designated project ID, do not use the project NAME.

5. If prompted, enable the API [compute.googleapis.com] on your project or use the following command `gcloud services enable compute.googleapis.com`.

6. Please update your preferred region and zone through: `gcloud config set compute/zone [myRegion]`. **NOTE** Change `[myRegion]`. For instance, `us-central1-a` is the region of our choice. 

## I. Create a GCE instance using custom image

These steps will first create a SSD persistent disk storage and its associated image which will be used as the boot disk stoage. Finally, you will provision a GCE instance which 

1. Run the following command to create a storage disk with 200 GB disk size with a PD-SSD disk type: 

```
gcloud compute disks create abmvirt-disk --image-project=ubuntu-os-cloud --image-family=ubuntu-2004-lts --size=200G --type=pd-ssd
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
gcloud compute images create abmvirt-image --source-disk abmvirt-disk --licenses "https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"
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

3. Before proceeding to create your GCE instance, ensure you have a VPC network. For this workshop, please create a default network through the following command. 

```
gcloud compute networks create default --subnet-mode=auto --mtu=1460 --bgp-routing-mode=regional
```

Output should look like something similar:

```
Created [https://www.googleapis.com/compute/v1/projects/helloworld-hjkt/global/networks/default].
NAME: default
SUBNET_MODE: AUTO
BGP_ROUTING_MODE: REGIONAL
IPV4_RANGE:
GATEWAY_IPV4:
```

4. Create a firewall rule on the `default` vpc network to allow the following TCP ports of: 22, 3389, 443 and PING.

```
gcloud compute firewall-rules create custom-allow-ssh --network default --allow tcp:22,tcp:3389,tcp:443,tcp:8080,icmp
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

5. Finally, create the GCE instance and attach the storage disk from the above steps:  

```
gcloud compute instances create abm-on-gce --image abmvirt-image --can-ip-forward --network default --tags http-server,https-server --min-cpu-platform "Intel Haswell" --scopes cloud-platform --machine-type n1-standard-32
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

1. SSH into the newly created GCE instance. If you run into an error saying the connection to host was refused, please wait a few minutes and validate the GCE instance is up before trying this step. 

```
gcloud compute ssh abm-on-gce
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
git clone https://github.com/msathe-tech/standalone-abm.git
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

## [OPTIONAL] verify the CPU supports harware virtualization

1. If you wish to run legacy windows apps on the platform you will require KubeVirt which uses KVM to manage VMs on top of Kubernetes. Ensure you have ability to run KVM. Following command checks if the CPU supports harware virtualization. If following command output it 0 it means the CPU doesn't support hardware virtualization. Which means you can run KubeVirt VMs on the ABM. 

```
grep -Eoc '(vmx|svm)' /proc/cpuinfo
```

2. Check if your system can run hardware-accelerated KVM virtual machines. 

```
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install cpu-checker -y
kvm-ok
```

3. Validate the processor virtualization capability is not disabled in the BIOS. The output should be like following. 

```
INFO: /dev/kvm exists
KVM acceleration can be used
```

## III: Continue the configuration of the GCE instance to prep for ABM Install

1. Setup the GCE environment and install the necessary updates and jq binaries

```
sudo apt-get update -y
sudo apt install jq -y
```

2. Authentication your gcloud for login against your user profile and project ID.

```
gcloud auth application-default login
```

3. Update access permissions for the following set environment script and make a note of your IP address:

```
cd standalone-abm
chmod +x setenv.sh
```

4. Update the `setenv.sh` script for the following values.

Run the command `ip a` and make a note of your network interface name, it should be `ens4`. If it is NOT `ens4`, please update Line 4 with your network interface name.

Please update Line 7 with your assigned Argolis principal name. For instance, if your id is: `ubuntu@anjalikhatri.altostrat.com` the value will be `ubuntu`.
Pleave validate Line 8 domain name. For this workshop, since it is running on Argolis, this value should not change.
```
#!/bin/bash
# IMP: Please change the ens4 to use correct network interface name in the following command.
# It should be the interface which has your IP on the subnet.
export NETWORK_INTERFACE=ens4 ### Replace this value by running and identifying your interface through `ip a`
export CURRENT_IP=$(ip --json a show dev ${NETWORK_INTERFACE} | jq '.[0].addr_info[0].local' -r)
echo INSTANCE_IP=$CURRENT_IP
export ARGOLIS_NAME=ubuntu  ###Replace this value with your Argolis name
export ARGOLIS_DOMAIN=anjalikhatri_altostrat_co ### Replace with your domain name.
export GCE_CLUSTER_PATH=${ARGOLIS_NAME}_${ARGOLIS_DOMAIN}
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
. ./setenv.sh
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
cd ~
sudo bash
cd standalone-abm
chmod +x vxlan.sh
```

7. Update line 7 within the `vxlan.sh` script with the network interface name. 
In my instance, it should be `ens4` instead of `eno1`.

8. Next, run the script and ensure you get a successful ping against the vxlan IP of 10.200.0.2. A successful ping confirms your vxlan setup is complete.

```
./vxlan.sh
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

Step the ping output by running Ctrl-Z (on Mac).

### A: Setup SSH Access for GCE NON-ROOT and ROOT users and enable passwordless SSH private access to your machine.

1. Exit from `root` user and ensure you're on `non-root` 
```
exit 
```

2. Generate RSA Keygen. Don't enter any passphrase (leave empty) and use the default file paths (Keep pressing enter).
Perform this step for NON-ROOT user.

```
ssh-keygen 
```
Authorize the passwordless ssh access.
```
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

Verify you can login without password, you can find the IP address and username from `setenv.sh` script from seciton III, step 5. 

For instance, it should be like `ssh ubuntu_anjalikhatri_altostrat_co@10.128.0.2` for non-root user.

```
ssh [your-username]@[ip-address-of-your-machine] 
exit 
```

3. Generate RSA Keygen. Don't enter any passphrase (leave empty) and use the default file paths (Keep pressing enter).
Perform this setp for ROOT user.

```
sudo bash
ssh-keygen 
```
Authorize the passwordless ssh access.
```
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

Verify you can login without password, you can find the IP address and username from `setenv.sh` script from seciton III, step 5. 

For instance, it should be like `ssh root@10.128.0.2` for root user.

```
ssh [your-username]@[ip-address-of-your-machine] 
exit 
exit
```

### B: Install Docker and make it available as non-root user

1. Install docker on GCE

```
sudo apt-get install -y docker
sudo apt-get install -y docker.io
```

2. Add docker to a group and existing user profile

```
sudo groupadd dockerdock
sudo usermod -aG docker $USER
```

3. Confirm docker is running and its latest version

```
newgrp docker 
docker run hello-world
```

4. Validate the version of Docker:
```
docker -v
```
Docker version 20.10.7, build 20.10.7-0ubuntu5~20.04.2

### C: Setup the CTL for ABM

1. Install and setup the BMCTL 

```
cd ~
gsutil cp gs://anthos-baremetal-release/bmctl/1.8.2/linux-amd64/bmctl bmctl
chmod a+x bmctl
```

### D: Create the ABM Cluster Configuration file

1. Validate the following environment variable output matches your current environment. These values were set in `setenv.sh` script earlier. 

```
echo $ARGOLIS_NAME
echo $PROJECT_ID
echo $CLUSTER_NAME
echo $GCE_CLUSTER_PATH
```

Output should be similar BUT validate this matches your environment

```
$ echo $ARGOLIS_NAME
ubuntu

$ echo $PROJECT_ID
helloworld-010

$ echo $CLUSTER_NAME
abm-cluster

$ echo $GCE_CLUSTER_PATH
ubuntu_anjalikhatri_altostrat_co
```

If the environment variables are incorrect, please re-run the `setenv.sh` script as the following and re-validate your output by running the echo commands
```
. ./standalone-abm/setenv.sh
```

2. Create the ABM configuration
```
cd $HOME
./bmctl create config -c $CLUSTER_NAME --enable-apis --create-service-accounts --project-id=$PROJECT_ID
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
First, replace the placeholder "[PROJECT-ID]" with your project ID in the sample YAML. 
```
sed -i 's/\[PROJECT-ID\]/helloworld-madhav/g' standalone-abm/single-gce-abm-with-vxlan.yaml
```
***Please verify  ``` standalone-abm/single-gce-abm-with-vxlan.yaml ``` the values and paths are accurate. ***

```
cp standalone-abm/single-gce-abm-with-vxlan.yaml bmctl-workspace/$CLUSTER_NAME/$CLUSTER_NAME.yaml
```

4. Open up the `$CLUSTER_NAME.yaml` file and update the following. In this case, it will be called `abm-cluster.yaml` and update the following lines:

Update Lines 6,7,8,9,10, 34 and 102 by replacing the [PROJECT-ID] with YOUR assigned ID, remove the brackets as well
Oringinal file looks like this
```
6  gcrKeyPath: bmctl-workspace/.sa-keys/[PROJECT-ID]-anthos-baremetal-gcr.json
7  sshPrivateKeyPath: /root/.ssh/id_rsa #<path to SSH private key, used for node access>
8  gkeConnectAgentServiceAccountKeyPath: bmctl-workspace/.sa-keys/[PROJECT-ID]-anthos-baremetal-connect.json
9  gkeConnectRegisterServiceAccountKeyPath: bmctl-workspace/.sa-keys/[PROJECT-ID]-anthos-baremetal-register.json
10 cloudOperationsServiceAccountKeyPath: bmctl-workspace/.sa-keys/[PROJECT-ID]-anthos-baremetal-cloud-ops.json

34     projectID: [PROJECT-ID]
102    projectID: [PROJECT-ID]
```

To easily update the project-IDs, run the following sed command. Replace `helloworld-009` with your actual project-ID

```
sed -i 's/\[PROJECT-ID\]/helloworld-009/g' bmctl-workspace/$CLUSTER_NAME/$CLUSTER_NAME.yaml
```

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
$ ./bmctl create cluster -c abm-cluster
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

2. Go back to the `setenv.sh` script and uncomment lines 17 and 18 and validate the environment variables for project ID and cluster name are correct.

Uncomment the lines that should look like this:
```
export KUBECONFIG=/home/${GCE_CLUSTER_PATH}/bmctl-workspace/${CLUSTER_NAME}/${CLUSTER_NAME}-kubeconfig
echo $KUBECONFIG
```

Run the `setenv.sh` script

```
. ./setenv.sh
```

### F: Login to Anthos console

1. Now that Anthos is installed, you need to update your $PATH to specify the newly generated Kube Config file for the newly created ABM cluster. Execute these steps as both `non-root` and `root` users.

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

3. Navigate to Anthos console, click the name of your server, on the right hand panel click Login, select the Bearer token option. Copy the token from the output from above and use that to login to the cluster.

After you enter the token, the cluster should show up as being healthy.

4. Enable and setup stackdriver monitoring and logging for workloads, enable Prometheus metrics capture for apps

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

5. Get a status of the running pods 

```
$ kubectl get po -n kube-system
```

The output will look something similar

```
NAME                                                       READY   STATUS    RESTARTS   AGE
anet-operator-57cb7b979b-pzlzg                             1/1     Running   0          11m
anetd-vxqqr                                                1/1     Running   0          11m
anthos-cluster-operator-776cbfb748-kxxsp                   2/2     Running   0          11m
anthos-multinet-controller-5c6bcb85d-bbqgg                 1/1     Running   0          11m
cap-controller-manager-777fc99b75-9njpt                    2/2     Running   0          11m
clientconfig-operator-69c54567c-lztkg                      1/1     Running   0          11m
core-dns-autoscaler-cf765587-6t94v                         1/1     Running   0          11m
coredns-7969dcc8cb-lbfhr                                   1/1     Running   0          11m
csi-snapshot-controller-5556cbf9db-l5w6v                   1/1     Running   0          11m
csi-snapshot-validation-79cf5bd895-pl69g                   1/1     Running   0          11m
etcd-abm-on-gce                                            1/1     Running   0          12m
etcd-defrag-m26hh                                          1/1     Running   0          11m
haproxy-abm-on-gce                                         1/1     Running   1          12m
keepalived-abm-on-gce                                      1/1     Running   1          12m
kube-apiserver-abm-on-gce                                  1/1     Running   0          12m
kube-control-plane-metrics-proxy-cnxpx                     1/1     Running   0          10m
kube-controller-manager-abm-on-gce                         1/1     Running   0          12m
kube-proxy-xslkq                                           1/1     Running   0          11m
kube-scheduler-abm-on-gce                                  1/1     Running   0          12m
kube-state-metrics-67d8f6bb4-tqs79                         1/1     Running   0          10m
localpv-9xrbf                                              1/1     Running   0          11m
metallb-controller-64d846c6d4-szv86                        1/1     Running   0          11m
metallb-speaker-7q7mj                                      1/1     Running   0          11m
metrics-server-65cdc7466f-lmm69                            2/2     Running   0          10m
metrics-server-operator-77669cd95b-kqsfm                   1/1     Running   0          11m
node-exporter-jzqd8                                        1/1     Running   0          10m
sp-anthos-static-provisioner-5d58d7bf9c-ldxzr              2/2     Running   0          11m
stackdriver-log-forwarder-nxw49                            1/1     Running   0          17s
stackdriver-metadata-agent-cluster-level-55897684b-ghvsk   1/1     Running   0          27s
stackdriver-operator-689f98bc98-l658f                      1/1     Running   0          11m
stackdriver-prometheus-app-0                               2/2     Running   0          27s
stackdriver-prometheus-k8s-0                               2/2     Running   0          34s
```

# Congratulations, you've successfully installed ABM on a single node GCE instance in your GCP project.

# Optional 

## Longhorn for CSI storage layer
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.1.2/deploy/longhorn.yaml
kubectl get pods --namespace longhorn-system --watch
kubectl -n longhorn-system get pod
```
Verify Longhorn is listed as a storageclass and make it a default storageclass
```
kubectl get sc
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get sc
```
### Setup UI console for Longhorn
```
USER=<USERNAME_HERE>; PASSWORD=<PASSWORD_HERE>; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth
kubectl -n longhorn-system create secret generic basic-auth --from-file=auth
kubectl get svc -n longhorn-system
```
As you can see the longhorn-frontend service is not exposed outside the cluster. You can use service type LoadBalancer. 
Since we are using VXLAN the ABM will allocate external IP from the range we provided in the cluster configuration file which is a range of VXLAN IPs. 
```
kubectl edit svc longhorn-frontend -n longhorn-system # Change spec.type from ClusterIP to LoadBalancer
kubectl get svc -n longhorn-system 
```
# Optional - if you want to run Windows VM on ABM

## Enable KubeVirt on the cluster
```
kubectl --kubeconfig bmctl-workspace/CLUSTER_NAME/CLUSTER_NAME-kubeconfig get pods -n kubevirt
```
Add following section if you- 
```
spec:
  anthosBareMetalVersion: 1.8.3
  kubevirt:
    useEmulation: true
  bypassPreflightCheck: false
```
Or following if your hardware permits. If you set **useEmulation: false** and your hardware doesn't support then pre-flight check will fail during cluster creation. 
```
spec:
  anthosBareMetalVersion: 1.8.3
  kubevirt:
    useEmulation: false
  bypassPreflightCheck: false
```
## Download and save ISO image
Download the Windows 2010 image from [here](https://www.microsoft.com/en-us/software-download/windows10ISO). 
Upload the image to a GCS bucket so that you can download it on any machine later.
```
gsutil cp [/path/to]/Win10_21H1_English_x64.iso gs://[your gcs bucket]
```

And then download the ISO image on the machine you want to run the kubectl. 
```
gsutil cp gs://[your gcs bucket]/Win10_21H1_English_x64.iso .
```

**Note** if you have the GCS bucket in another project that you've access to then you can use 
```
gcloud auth login
gcloud config set project[project-where-gcs-bucket-has-windows-image]
gsutil cp gs://[your gcs bucket]/Win10_21H1_English_x64.iso .
gcloud config set project[project-where-your-GCE-for-ABM-is-running]
```

## Setup Windows VM
Install virtctl
```
sudo -E ./bmctl install virtctl
kubectl plugin list
```
Take the IP of cdi-uploadproxy. 
```
kubectl get svc -n cdi
```

Upload the ISO image. 
```
kubectl get sc

kubectl virt image-upload \
--image-path=/home/madhavhsathe/Win10_21H1_English_x64.iso \
--pvc-name=windows-iso-pvc \
--access-mode=ReadWriteOnce \
--pvc-size=10G \
--uploadproxy-url=https://10.200.0.70:443 \
--insecure  \
--wait-secs=240 \
--storage-class=longhorn

kubectl get pvc

```
## Lauch the VM
```
cd kubevirt
# Edit the PVC YAML to change the size of the main disk as per your machine size. 
kubectl create -f windows-pvc.yaml 
kubectl create -f windows-vm.yaml
```
Verify the PVC and VM are created
```
kubectl get pvc
kubectl get vm
kubectl get vmi
```

# Setup VNC to access UI console for the GCE instance
You need a UI console to kickstart the Windows installation. 
For that we are going to setup VNC on the machine. 
You will be asked to set the password. Please note this password. 
```
cd vnc
./setup-vnc.sh
```
Wait for all packages to be installed and VNC server to start.
Verify that the VNC server has started.
```
ps aux | grep vnc
```
Now **copy script in xstartup.sh to $HOME/.vnc/xstartup**.
And restart the VNC server.
```
vncserver -kill :1
vncserver -geometry 1920x1080
```
Ensure you have the firewall on GCP to allow access to port 5901.
```
gcloud compute firewall-rules create vncserver --allow tcp:5901 --source-ranges 0.0.0.0/0
```
Launch your VNC client. You can download [Real VNC](https://www.realvnc.com/en/connect/download/viewer/) for your desktop. 
Access the GCE instance using its [public IP]:5901.
Access the VM you started earlier. 
```
kubectl get vm
kubectl virt vnc [your-vm]
```
You will need to install the Windows operating system.

# Take Backup on GCP
Create a GCP bucket, enable Interoperability. 
Remove the default key and create a new one.
Set the project as default project for interoperable access.

Create K8s secret using following command for the key you just added. 
```
export ACCESS_KEY=<<your access key>
export SECRET= <<your secret>>
export ENDPOINT=https://storage.googleapis.com
```
Create the secret in **longhorn-system** namespace so that Longhorn can access this bucket using the GCS endpoint and key. 
```
kubectl create secret generic gcp-storage-secret \
    --from-literal=AWS_ACCESS_KEY_ID=${ACCESS_KEY} \
    --from-literal=AWS_SECRET_ACCESS_KEY=${SECRET} \
    --from-literal=AWS_ENDPOINTS=${ENDPOINT} \
    -n longhorn-system
```
