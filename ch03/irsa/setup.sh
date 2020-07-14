#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

export AWS_DEFAULT_OUTPUT="json"

ACCOUNT_NAME=$(aws sts get-caller-identity | jq -r .Arn | cut -d '/'  -f2)
ACCOUNT_ID=$(aws sts get-caller-identity | jq -r .Account)
ROLE_NAME=eks-as-${ACCOUNT_NAME}-$(date +%s)
CLUSTER_NAME=$(aws eks list-clusters | jq -r '.clusters[]' | grep cs-${ACCOUNT_NAME}- | head -1)

cat > cluster-autoscaler-chart-values.yaml << EOF
awsRegion: us-west-2

rbac:
  create: true
  serviceAccountAnnotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

autoDiscovery:
  clusterName: ${CLUSTER_NAME}
  enabled: true
EOF

jq -n --arg ROLE_NAME "$ROLE_NAME" \
--arg CLUSTER_NAME "$CLUSTER_NAME" \
'{"role_name": $ROLE_NAME, "cluster_name": $CLUSTER_NAME}'