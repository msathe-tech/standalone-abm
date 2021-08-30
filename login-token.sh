#!/bin/bash
cat <<EOF > cloud-console-reader.yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cloud-console-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "persistentvolumes"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["get", "list", "watch"]
EOF

kubectl apply -f cloud-console-reader.yaml
KSA_NAME=abm-console-service-account
kubectl create serviceaccount ${KSA_NAME}
kubectl create clusterrolebinding cloud-console-reader-binding \
--clusterrole cloud-console-reader \
--serviceaccount default:${KSA_NAME}

kubectl create clusterrolebinding cloud-console-view-binding \
--clusterrole view \
--serviceaccount default:${KSA_NAME}

kubectl create clusterrolebinding \
cloud-console-cluster-admin-binding \
--clusterrole cluster-admin \
--serviceaccount default:${KSA_NAME}

SECRET_NAME=$(kubectl get serviceaccount ${KSA_NAME} \
-o jsonpath='{$.secrets[0].name}') 

echo "User following token in Anthos console to Login to the cluster"

kubectl get secret ${SECRET_NAME} \
-o jsonpath='{$.data.token}' \
| base64 --decode

echo ""