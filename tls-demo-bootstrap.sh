export KUBE_HOSTS="kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local"

mkdir -p ca
mkdir -p etcd/{data,tls}
mkdir -p kubernetes
mkdir -p admin-client

echo "Generating CAs"
cfssl gencert -initca ca-csr.json | cfssljson -bare ca/ca
cfssl gencert -initca ca-vondoom-csr.json | cfssljson -bare ca/ca-vondoom
cp ca/ca.pem etcd/tls
cp ca/ca.pem kubernetes
cp ca/ca-vondoom.pem kubernetes

echo "Generating admin client cert"
cfssl gencert -ca=ca/ca.pem -ca-key=ca/ca-key.pem -config=ca-config.json -profile=kubernetes admin-client-csr.json | cfssljson -bare admin-client/admin-client
cfssl gencert -ca=ca/ca.pem -ca-key=ca/ca-key.pem -config=ca-config.json -profile=kubernetes admin-client-correct-csr.json | cfssljson -bare admin-client/admin-client-correct

echo "Generating etcd certs"
cfssl gencert -ca=ca/ca.pem -ca-key=ca/ca-key.pem -config=ca-config.json -profile=expired etcd-csr.json | cfssljson -bare etcd/tls/etcd
sleep 2
cfssl gencert -ca=ca/ca.pem -ca-key=ca/ca-key.pem -config=ca-config.json -profile=kubernetes etcd-correct-csr.json | cfssljson -bare etcd/tls/etcd-fixed
cfssl gencert -ca=ca/ca.pem -ca-key=ca/ca-key.pem -config=ca-config.json -profile=kubernetes -hostname 127.0.0.1,localhost etcd-correct-csr.json | cfssljson -bare etcd/tls/etcd-correct

echo "Generating kube-apiserver cert"
cfssl gencert -ca=ca/ca.pem -ca-key=ca/ca-key.pem -config=ca-config.json -profile=kubernetes -hostname 10.3.0.1,127.0.0.1,localhost,$KUBE_HOSTS kube-apiserver-csr.json | cfssljson -bare kubernetes/kube-apiserver

echo "Generating kube-scheduler cert"
cfssl gencert -ca=ca/ca.pem -ca-key=ca/ca-key.pem -config=ca-config.json -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kubernetes/kube-scheduler

echo "Generating admin client kubeconfigs"
kubectl config set-cluster tls-debug-demo --certificate-authority=ca/ca.pem --embed-certs=true --server=https://127.0.0.1:6443 --kubeconfig admin-client/admin-kubeconfig.yaml

kubectl config set-credentials admin --client-certificate=admin-client/admin-client.pem --client-key=admin-client/admin-client-key.pem --embed-certs=true --kubeconfig admin-client/admin-kubeconfig.yaml

kubectl config set-context default --cluster=tls-debug-demo --user=admin --kubeconfig admin-client/admin-kubeconfig.yaml

kubectl config use-context default --kubeconfig admin-client/admin-kubeconfig.yaml

cp admin-client/admin-kubeconfig.yaml admin-client/admin-kubeconfig-correct.yaml

kubectl config set-credentials admin --client-certificate=admin-client/admin-client-correct.pem --client-key=admin-client/admin-client-correct-key.pem --embed-certs=true --kubeconfig admin-client/admin-kubeconfig-correct.yaml

kubectl config set-cluster tls-debug-demo --certificate-authority=ca/ca.pem --embed-certs=true --server=https://127.0.0.1:6443 --kubeconfig=kubernetes/kube-scheduler-kubeconfig.yaml

kubectl config set-credentials system:kube-scheduler --client-certificate=kubernetes/kube-scheduler.pem --client-key=kubernetes/kube-scheduler-key.pem --embed-certs=true --kubeconfig=kubernetes/kube-scheduler-kubeconfig.yaml

kubectl config set-context default --cluster=tls-debug-demo --user=system:kube-scheduler --kubeconfig=kubernetes/kube-scheduler-kubeconfig.yaml

kubectl config use-context default --kubeconfig=kubernetes/kube-scheduler-kubeconfig.yaml

# Run the initial configuration of the components

./run-etcd.sh bootstrap
./run-kube-apiserver.sh bootstrap
./run-kube-scheduler.sh bootstrap
