#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

# ---------------------------------------------------------------------------------------------------------------------
# Download all necessary binary file
# ---------------------------------------------------------------------------------------------------------------------

echo "Get binaries ..."

cp -f ~/.bashrc ~/.bashrc.bak

curl --silent -Lo kubectl curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.
echo 'kubectl Done.'

curl --silent -Lo aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/aws-iam-authenticator
chmod +x aws-iam-authenticator
sudo mv aws-iam-authenticator /usr/local/bin/
echo 'aws-iam-authenticator Done.'

curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
chmod +x /tmp/eksctl
sudo mv /tmp/eksctl /usr/local/bin
echo 'eksctl Done.'

curl --silent --location "https://github.com/txn2/kubefwd/releases/download/1.14.0/kubefwd_linux_amd64.tar.gz" | tar xz -C /tmp
chmod +x /tmp/kubefwd
sudo mv /tmp/kubefwd /usr/local/bin
echo 'kubefwd Done.'

curl --silent -Lo kubebox https://github.com/astefanutti/kubebox/releases/download/v0.8.0/kubebox-linux
chmod +x kubebox
sudo mv kubebox /usr/local/bin
echo 'kubebox Done.'

curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
echo 'helm Done.'

curl --silent -Lo terraform.zip https://releases.hashicorp.com/terraform/0.12.28/terraform_0.12.28_linux_amd64.zip
unzip terraform.zip
chmod +x terraform
sudo mv terraform /usr/local/bin/
rm terraform.zip
echo 'terraform Done.'

curl --silent -Lo opa https://github.com/open-policy-agent/opa/releases/download/v0.21.1/opa_linux_amd64
chmod +x opa
sudo mv opa /usr/local/bin
echo 'opa Done.'

sudo apt-get install -y jq mysql-client
echo 'jq, mysql-client Done.'

sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

git clone https://github.com/ahmetb/kubectx.git ~/.kubectx
COMPDIR=$(pkg-config --variable=completionsdir bash-completion)
sudo ln -sf ~/.kubectx/completion/kubens.bash $COMPDIR/kubens
sudo ln -sf ~/.kubectx/completion/kubectx.bash $COMPDIR/kubectx

cat << FOE >> ~/.bashrc

#kubectx and kubens
export PATH=~/.kubectx:\$PATH
FOE
echo "kubectx Done. "

git clone https://github.com/jonmosco/kube-ps1.git ~/.kube-ps1

cat << FOE >> ~/.bashrc

#kube-ps1
function get_cluster_short()  {
  echo "\$1" | cut -d . -f1 | cut -d @ -f2
}

source ~/.kube-ps1/kube-ps1.sh
KUBE_PS1_SEPARATOR=''
KUBE_PS1_SYMBOL_COLOR=green
KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
PS1='\[\033[01;34m\]\W\[\033[00m\]\$(__git_ps1 " (%s)" 2>/dev/null) $ '
PS1='\$(kube_ps1) '\$PS1
FOE
echo "kube-ps1 Done. "


cat > ~/.ssh/config << EOF
ServerAliveInterval 120
Host github.com
    AddKeysToAgent yes
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa
EOF

# ---------------------------------------------------------------------------------------------------------------------
# Prepare EKS cluster
# ---------------------------------------------------------------------------------------------------------------------

echo "Prepare EKS cluster ..."
ACOUNT_NAME=$(aws sts get-caller-identity | jq -r '.Arn' | cut -d '/'  -f2)
CLUSTER_NAME=cs-${ACOUNT_NAME}-${RANDOM}

cat > eks.yaml << EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: "${CLUSTER_NAME}"
  region: us-west-2

nodeGroups:
  - name: ng0
    instanceType: t3.large
    desiredCapacity: 2
EOF

# Create eks cluster using eksctl
echo "Creating eks cluster and node group with two t3.large instances ..."
eksctl create cluster -f eks.yaml

# Setup OIDC ID provider
eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve

# Test if kubernate cluster works good
kubectl get all

echo 'Done setting EKS.'
