# Single-node Kubernetes CentOS Install

Start with a minimal install of CentOS

curl https://raw.githubusercontent.com/rvmey/KubernetesCentosInstall/master/kubinit.sh -o kubinit.sh

chmod +x kubinit.sh

./kubinit.sh

# If you see errors like this, keep waiting.  It should clear up in around 5-10 minutes.

[root@centos ~]# kubectl get pods --all-namespaces

NAMESPACE     NAME                                         READY     STATUS     RESTARTS   AGE

kube-system   etcd-centos.localdomain                      1/1       Running    0          3m

kube-system   kube-apiserver-centos.localdomain            1/1       Running    2          3m

kube-system   kube-controller-manager-centos.localdomain   1/1       Running    0          3m

kube-system   kube-flannel-ds-dttg5                        0/1       Error      4          4m

kube-system   kube-scheduler-centos.localdomain            1/1       Running    0          4m

kube-system   kubernetes-dashboard-747c4f7cf-sldcp         0/1       Init:0/1   0          4m

