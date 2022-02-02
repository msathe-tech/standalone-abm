#!/bin/bash
# IMP: Please change the ens4 to use correct network interface name in the following command. 
# It should be the interface which has your IP on the subnet. 
export CURRENT_IP=$(ip --json a show dev ens4 | jq '.[0].addr_info[0].local' -r)
echo $CURRENT_IP
export PATH=$PATH:/home/#replace-me
export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.config/gcloud/application_default_credentials.json
echo $GOOGLE_APPLICATION_CREDENTIALS
export PROJECT_ID=$(gcloud config get-value project)
echo $PROJECT_ID
#export KUBECONFIG=/home/#replace-me/bmctl-workspace/[#your-cluster-name]/[#your-cluster-name]-kubeconfig
#echo $KUBECONFIG
