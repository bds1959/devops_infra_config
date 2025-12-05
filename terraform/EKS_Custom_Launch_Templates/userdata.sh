#!/bin/bash
set -ex
EKS_CLUSTER_API="${api_server}"
EKS_CLUSTER_CA="${certificate_authority}"
EKS_CLUSTER_DNS_IP="${dns_cluster_ip}"

/etc/eks/bootstrap.sh ${cluster_name} \
  --apiserver-endpoint "$EKS_CLUSTER_API" \
  --b64-cluster-ca "$EKS_CLUSTER_CA" \
  --dns-cluster-ip "$EKS_CLUSTER_DNS_IP" \
  --container-runtime containerd \
  --kubelet-extra-args '--max-pods=${max_pods}' \
  --use-max-pods false
