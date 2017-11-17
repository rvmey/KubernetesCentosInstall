#!/bin/sh
ulimit -n 50000
yum -y update

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
yum install -y docker kubelet kubeadm kubectl etcd flannel

echo `hostname -I` `hostname` >> /etc/hosts
swapoff -a
setenforce 0

systemctl enable docker
systemctl start docker
systemctl enable kubelet
systemctl start kubelet

systemctl disable firewalld
systemctl stop firewalld

sysctl net.bridge.bridge-nf-call-iptables=1

kubeadm init --pod-network-cidr=10.244.0.0/16

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.0/Documentation/kube-flannel.yml

rm -rf $HOME/.kube
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

kubectl taint node --all=true node-role.kubernetes.io/master:NoSchedule-

kubectl get pods --all-namespaces

cat <<EOF > /root/insecuredashboard.yml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: kubernetes-dashboard-rb
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
EOF

kubectl create -f /root/insecuredashboard.yml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

echo The GUI should be available soon at http://`hostname`:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy
echo Use the Skip button to login.

kubectl proxy --address `hostname -I` --accept-hosts '.*'