#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

kubectl delete -n opa -f manifests/admission-controller.yaml
kubectl delete -n opa -f manifests/webhook-configuration.yaml
kubectl delete -n opa cm basic-auditing
kubectl delete -n default -f manifests/nginx-no-resource-management.yaml
kubectl delete -n default -f manifests/nginx-resource-management.yaml
kubectl delete -n default -f manifests/nginx-not-official-image.yaml

rm -rf ca.crt
rm -rf ca.key
rm -rf ca.srl

rm -rf server.crt
rm -rf server.csr
rm -rf server.key

rm -rf resources/webhook-configuration.yaml