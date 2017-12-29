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
yum install -y kubelet-1.8.3
yum install -y docker kubeadm kubectl etcd flannel

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

kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=1.8.3

rm -rf $HOME/.kube
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint node --all=true node-role.kubernetes.io/master:NoSchedule-

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

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

curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

# The following command is gives too much access to the default service account, but it allows helm to create the nginx ingress controller.
kubectl create clusterrolebinding --user system:serviceaccount:kube-system:default kube-system-cluster-admin --clusterrole cluster-admin

helm init
echo Waiting for tiller pod to run before running helm command to create the nginx ingress controller
while true; do
  kubectl get pods --all-namespaces | grep tiller | grep Running
  if [ $? -ne 0 ]; then
    echo "Still waiting..."
  else
    break
  fi
  sleep 5
done

helm install --name nginxchart stable/nginx-ingress --set controller.hostNetwork=true --set rbac.create=true

echo .
echo The GUI should be available in about 15 minutes at http://`hostname`:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy
echo Use the Skip button to login.
echo .
echo In the meantime you could open another SSH session and start running kubectl commands.
echo Or merge your the context in /etc/kubernetes/admin.conf YAML with your local ~/.kube/config file so you can run kubectl commands against your new cluster from there.
echo .
echo If you need to re-run the proxy to get into the GUI, run:  kubectl proxy --address `hostname -I` --accept-hosts '.*'

echo Also, make sure you disable SELinux in /etc/sysconfig/selinux before you reboot.

kubectl get pods --all-namespaces

kubectl proxy --address `hostname -I` --accept-hosts '.*'