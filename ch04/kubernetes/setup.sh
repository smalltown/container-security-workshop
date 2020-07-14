#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

# create the opa namespace
kubectl apply -f manifests/opa-namespace.yaml
kubens opa

# create certificate authority and key pair for OPA
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -days 100000 -out ca.crt -subj "/CN=admission_ca"

openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/CN=opa.opa.svc" -config server.conf
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 100000 -extensions v3_req -extfile server.conf

kubectl create secret tls opa-server --cert=server.crt --key=server.key --dry-run -o yaml | kubectl apply -f -

# create OPA admission-controller
kubectl apply -f manifests/admission-controller.yaml

# not controll resource in kube-system and opa namespace
kubectl label ns kube-system openpolicyagent.org/webhook=ignore --overwrite=true
kubectl label ns opa openpolicyagent.org/webhook=ignore --overwrite=true

# register OPA as an admission controller
cat > manifests/webhook-configuration.yaml <<EOF
kind: ValidatingWebhookConfiguration
apiVersion: admissionregistration.k8s.io/v1beta1
metadata:
  name: opa-validating-webhook
webhooks:
  - name: validating-webhook.openpolicyagent.org
    namespaceSelector:
      matchExpressions:
      - key: openpolicyagent.org/webhook
        operator: NotIn
        values:
        - ignore
    rules:
      - operations: ["CREATE", "UPDATE"]
        apiGroups: ["*"]
        apiVersions: ["*"]
        resources: ["*"]
    clientConfig:
      caBundle: $(cat ca.crt | base64 | tr -d '\n')
      service:
        namespace: opa
        name: opa
EOF

kubectl apply -f manifests/webhook-configuration.yaml

# create OPA policy
kubectl create configmap -n opa basic-auditing --from-file=policies/basic-auditing.rego