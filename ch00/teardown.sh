#!/bin/sh

# Exit if any of the intermediate steps fail
set -e

# Remove Helm Chart
helm delete cluster-autoscaler --namespace=kube-system

# Remove EKS cluster
del=1

while [ $del -ne 0 ] ;
do
  sleep 5 
  echo 'try to delete eks'
  eksctl delete cluster -f eks.yaml
  del=$?
done

echo 'Clean up Done. Please do not forget check at console.'

# Remove binary files
sudo rm -rf /usr/local/bin/kubectl
sudo rm -rf /usr/local/bin/aws-iam-authenticator
sudo rm -rf /usr/local/bin/eksctl
sudo rm -rf /usr/local/bin/kubefwd
sudo rm -rf /usr/local/bin/kubebox
sudo rm -rf /usr/local/bin/terraform
sudo rm -rf /usr/local/bin/opa

sudo rm -rf /opt/kubectx /usr/local/bin/kubectx /usr/local/bin/kubens ~/.kubectx
COMPDIR=$(pkg-config --variable=completionsdir bash-completion)
sudo rm -rf $COMPDIR/kubens $COMPDIR/kubectx
sudo rm -rf ~/.kube-ps1
sudo rm -rf ~/.kube/http-cache/ ~/.kube/cache

cp -f ~/.bashrc.bak ~/.bashrc