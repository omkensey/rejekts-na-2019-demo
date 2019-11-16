# TLS debugging demo

This demo uses a stub installation of Kubernetes (only a single etcd and kube-apiserver, the kube-scheduler controller, and associated config files, in a configuration derived from Kelsey Hightower's [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)) to provide a sandbox in which to experiment with debugging TLS in Kubernetes.  The components all bind to 127.0.0.1 so this can run on any single system.

The initial state of the stub cluster is that etcd, kube-apiserver and the admin client kubeconfig are all misconfigured.  Correct configuration files are provided to rectify most of these; the user is encouraged to implement them by changing the run-* scripts that start each component.

## Prerequisites

* The system running the demo environment must have Docker installed, and the demo should be run using a user with permission to run the `docker` CLI without sudo.  This user should also be able to sudo to clean up the etcd data directory afterward.

* `cfssl`, `cfssljson`, `kubectl`, and `jq` must be installed.  The demo runs v1.16.3 of the Kubernetes control plane components used, so `kubectl` will need to be compatible with that version.

* SELinux enforcement must be turned off (`setenforce 0`) or the scripts must be modified to allow for SELinux (at a minimum the `docker` scripts need the `:Z` flag for their volume mounts).

## Starting up the demo

* Run the `tls-demo-bootstrap.sh` script
* Examine the state of the containers `tls-debug-etcd`, `tls-debug-kube-apiserver` and `tls-debug-kube-scheduler`.  Some of them may not be running.

* Fix the etcd server by editing the script to replace `etcd.pem` with `etcd-fixed.pem`, and `etcd-key.pem` with `etcd-fixed-key.pem`.  Run the `run-etcd.sh` script to restart etcd with the new options.  You may also need to run the scripts for `kube-apiserver` and `kube-scheduler`.

* Examining the container logs again, you should notice that there is still a problem with the etcd server.  Edit its script again and replace `etcd-fixed.pem` with `etcd-correct.pem`, then run the script again.  Re-run the kube-apiserver and kube-scheduler scripts if necessary.

* Check the container logs again; we're not done yet!  `kube-scheduler` is not authorized, but its certificates are correct; the issue lies with the kube-apiserver.  Inspect its client certificate config flags, then check the files (they're in the `kube-apiserver` directory) by using `openssl -noout -text -in [certificate file]`.  You should spot the file with the issue pretty quickly (hint: look at certificate issuer attributes).  Fix and run the `kube-apiserver` script.

* Check the container logs again; you maty still see errors but the components should be running without crashing now.  Try running a kubectl command like `kubectl get pods`.  There's still a problem, this time with the client certificate setup in your kubeconfig.  Examine the admin client cert data by decoding it with the `parse-kubectl-client-cert.sh` script.  The admin-kubeconfig-correct.yaml file in the `admin-client` directory has a correct certificate embedded in it; switch to it with `export KUBECONFIG="admin-client/admin-kubeconfig-correct.yaml"`.  Examine the correct certificate data by running `parse-kubectl-client-cert.sh` again; you should now also be able to run simple kubectl commands like `kubectl get pods` (there won't be any, but you should no longer get an authorization error).

## Reset and cleanup

Run the `tls-demo-cleanup.sh` script to reset the demo -- this will stop (if necessary) and delete the containers and delete the files generated by the bootstrap script, leaving only the files originally unpacked from the demo repo.  If you are done , you can just delete the directory afterward.
