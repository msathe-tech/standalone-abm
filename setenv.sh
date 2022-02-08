#!/bin/bash
# IMP: Please change the ens4 to use correct network interface name in the following command.
# It should be the interface which has your IP on the subnet.
export NETWORK_INTERFACE=ens4 ### Replace this value by running and identifying your interface through `ip a`
export CURRENT_IP=$(ip --json a show dev ${NETWORK_INTERFACE} | jq '.[0].addr_info[0].local' -r)
echo INSTANCE_IP=$CURRENT_IP
export ARGOLIS_NAME=ubuntu  ###Replace this value with your Argolis name
export ARGOLIS_DOMAIN=anjalikhatri_altostrat_co ### Replace this with your domain name
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
