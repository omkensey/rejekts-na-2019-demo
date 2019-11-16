#!/bin/bash

docker stop tls-debug-etcd && docker rm tls-debug-etcd

echo "Starting etcd"

docker run -d --name tls-debug-etcd \
--net=host \
-v ${PWD}/etcd/tls:/etc/etcd/tls \
-v ${PWD}/etcd/data:/var/etcd/data \
quay.io/coreos/etcd:v3.4.0 etcd \
--client-cert-auth \
--cert-file /etc/etcd/tls/etcd.pem \
--key-file /etc/etcd/tls/etcd-key.pem \
--trusted-ca-file /etc/etcd/tls/ca.pem \
--listen-client-urls https://127.0.0.1:2379 \
--advertise-client-urls https://127.0.0.1:2379 \
--data-dir /var/etcd/data

case $1 in
  "") docker logs tls-debug-etcd -f ;;
  bootstrap) echo "Not tailing logs while bootstrapping." ;;
esac
