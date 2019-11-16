#!/bin/bash

docker stop tls-debug-kube-apiserver && docker rm tls-debug-kube-apiserver

echo "Starting kube-apiserver"

docker run -d --name tls-debug-kube-apiserver \
--net=host \
-v $PWD/kubernetes:/etc/kubernetes \
k8s.gcr.io/kube-apiserver:v1.16.3 kube-apiserver \
--advertise-address 127.0.0.1 \
--allow-privileged true \
--apiserver-count 1 \
--authorization-mode=Node,RBAC \
--bind-address 127.0.0.1 \
--client-ca-file /etc/kubernetes/ca-vondoom.pem \
--enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
--etcd-cafile /etc/kubernetes/ca.pem \
--etcd-certfile /etc/kubernetes/kube-apiserver.pem \
--etcd-keyfile /etc/kubernetes/kube-apiserver-key.pem \
--etcd-servers https://127.0.0.1:2379 \
--kubelet-certificate-authority /etc/kubernetes/ca.pem \
--kubelet-client-certificate /etc/kubernetes/kube-apiserver.pem \
--kubelet-client-key /etc/kubernetes/kube-apiserver-key.pem \
--kubelet-https true \
--service-cluster-ip-range 10.3.0.0/24 \
--tls-cert-file /etc/kubernetes/kube-apiserver.pem \
--tls-private-key-file /etc/kubernetes/kube-apiserver-key.pem \
--v 2

case $1 in
  "") docker logs tls-debug-kube-apiserver -f ;;
  bootstrap) echo "Not tailing logs while bootstrapping." ;;
esac
