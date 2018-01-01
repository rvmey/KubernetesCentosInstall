# Kubernetes CentOS install including an Nginx based ingress controller

Start with a minimal install of CentOS

curl https://raw.githubusercontent.com/rvmey/KubernetesCentosInstall/master/kubinit.sh -o kubinit.sh

chmod +x kubinit.sh

./kubinit.sh

Use kubworker.sh to add worker nodes.

NOTE:  You might notice the master node installs with 1.8.3, but once it's up and running you can use yum -y update to update it to 1.9.0.  For some reason 1.9.0 wouldn't create the cluster but 1.8.3 does.  

I used these scripts to create the cluster I used for this video:  https://youtu.be/MyvRFbHErJQ
