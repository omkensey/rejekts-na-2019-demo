#!/bin/bash

docker stop tls-debug-kube-scheduler && docker rm tls-debug-kube-scheduler

echo "Starting kube-scheduler"

docker run -d --name tls-debug-kube-scheduler \
--net=host \
-v $PWD/kubernetes:/etc/kubernetes \
--restart on-failure \
k8s.gcr.io/kube-scheduler:v1.16.3 kube-scheduler \
--kubeconfig /etc/kubernetes/kube-scheduler-kubeconfig.yaml \
--v 2

case $1 in
  "") docker logs tls-debug-kube-scheduler -f ;;
  bootstrap) echo "Not tailing logs while bootstrapping." ;;
esac
