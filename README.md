# Overview 

Do you want to start your **beginer to pro** journey for Anthos Bare Metal? 
This tutorial guides you through the process to setup Anthos Bare Metal 1.8.2 on a single GCE instance. 
No prior understanding of Anthos or Anthos Bare Metal is required. 
You don't need to be a networking or Kubernetes geek to get started. 
All you need is a single GCE machine with 
As long as you have access to Google Cloud you will be able to get up and running. 

## Setup GCE 
### Create a GCE instance using custom image 

```
gcloud compute disks create abmvirt-disk --image-project=ubuntu-os-cloud --image-family=ubuntu-2004-lts --zone=us-west1-a --size=200G --type=pd-ssd

gcloud compute images create abmvirt-image --source-disk abmvirt-disk --source-disk-zone us-west1-a --licenses "https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"

gcloud compute instances create abm-on-gce --zone=us-west1-a --image abmvirt-image --can-ip-forward --network default --tags http-server,https-server --min-cpu-platform "Intel Haswell" --scopes cloud-platform --machine-type n1-standard-32
```
### Login to GCE 
Login to GCE 
```
gcloud compute ssh abm-on-gce
```
Install GIT and git clone this repo.
```
git clone https://github.com/msathe-tech/standalone-abm.git
```

# Optional - verify the CPU supports harware virtualization
If you wish to run legacy windows apps on the platform you will require KubeVirt which uses KVM to manage VMs on top of Kubernetes. 
Ensure you have ability to run KVM. Following command checks if the CPU supports harware virtualization. If following command output it 0 it means the CPU doesn't support hardware virtualization. Which means you can run KubeVirt VMs on the ABM. 
```
grep -Eoc '(vmx|svm)' /proc/cpuinfo
```
Check if your system can run hardware-accelerated KVM virtual machines. 
```
sudo apt-get update && sudo apt-get upgrade
sudo apt install cpu-checker
kvm-ok
```
Validate the processor virtualization capability is not disabled in the BIOS. The output should be like following. 
```
INFO: /dev/kvm exists
KVM acceleration can be used
```
Setup your env, take a note of your IP address. 
```
sudo apt install jq
gcloud auth application-default login
gcloud auth login
chmod +x setenv.sh
. ./standalone-abm/setenv.sh
```
## Setup VXLAN on the GCE instance

```
cd ~
standalone-abm/vxlan.sh
```

## Setup SSH access 
Generate SSH keys for the user you are logged in with and give yourself a passwordless ssh access to the machine. 
```
ssh-keygen # don't enter any passphrase, use default file paths 
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
# verify you can login without password
ssh [your-username]@[ip address of your machine] # you can find it from setenv.sh script
```
Now, generate SSH keys for root. 
```
sudo bash
ssh-keygen # don't enter any passphrase, use default file paths 
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
# verify you can login without password
ssh root@[ip address of your machine] # you can find it from setenv.sh script
```

## Install Docker and make it available as non-root user 
```
sudo apt-get install -y docker
sudo apt-get install -y docker.io
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker 
docker run hello-world
```

## Setup bmctl
```
cd ~
gsutil cp gs://anthos-baremetal-release/bmctl/1.8.2/linux-amd64/bmctl bmctl
chmod a+x bmctl
```

## Create ABM cluster config and create the cluster
```
cd $HOME
./bmctl create config -c [cluster-name] \
  --enable-apis --create-service-accounts --project-id=$PROJECT_ID
```

### Use single-gce-abm-with-vxlan.yaml as a reference to populate the 
```
cp standalone-abm/single-gce-abm-with-vxlan.yaml bmctl-workspace/[cluster-name]/[cluster-name].yaml
```
**MAKE SURE YOU EDIT bmctl-workspace/[cluster-name]/[cluster-name].yaml FILE TO REPLACE THE CLUSTER NAME**

## Create cluster 
```
sudo bash
gcloud auth applicatoin-default login
. ./standalone-abm/setenv.sh
./bmctl create cluster -c gce4-abm-cluster
```
## Login to Anthos console
```
chmod +x login-token.sh
./login-token.sh
```
Navigate to Anthos console, click the name of your server, on the right hand panel click *Login*, select the Bearer token option. Use the token above here and login to the cluster. 

# Done!
**Congratulations!**
You got a single machine Anthos cluster running on the simplest cloud. 
You can give yourself pat on your back. You have done it! 
All the next steps are options. 
You got the Kubernetes ready for containerized applicatoins. 

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


# Setup Windows VM
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
--image-path=/absolute_path_to_windows_iso//Win10_20H2_v2_English_x64.iso \
--pvc-name=windows-iso-pvc \
--access-mode=ReadWriteOnce \
--pvc-size=10G \
--uploadproxy-url=https://[cdi-uploadproxy svc IP]:443 \
--insecure  \
--wait-secs=240 \
--storage-class=longhorn

kubectl get pvc

```
## Lauch the VM
```
cd kubevirt
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
