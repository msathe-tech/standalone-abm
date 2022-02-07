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
