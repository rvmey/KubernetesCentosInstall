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
yum install kubelet-1.8.3
yum install -y docker kubectl kubeadm etcd flannel
yum install -y kubeadm

echo `hostname -I` `hostname` >> /etc/hosts

swapoff -a
sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

systemctl enable docker
systemctl start docker
systemctl enable kubelet
systemctl start kubelet

systemctl disable firewalld
systemctl stop firewalld

cat <<__EOF__ >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
__EOF__
sysctl --system
sysctl -p /etc/sysctl.d/k8s.conf

echo You have to change the kubeadm join line to match the output of the kubeadm init from the master node.
kubeadm join --token 4435a7.02a510caac886c3a 192.168.86.213:6443 --discovery-token-ca-cert-hash sha256:2a687a60a240df2da177a76bae6bfa524e1855290b975aedef5e2556c5e8b271

