#!/usr/bin/env bash

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)

export KUBECONFIG=$(cat .kubeconfig)
NAMESPACE=$(cat .namespace)
BRANCH="main"
SERVER_NAME="default"
TYPE="instances"
LAYER="2-services"
TIMEOUT=60

COMPONENT_NAME="ibm-cp4i-apic-instance"

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

if [[ ! -f "argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml" ]]; then
  echo "ArgoCD config missing - argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
  exit 1
fi

echo "Printing argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
cat "argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"

if [[ ! -f "payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml" ]]; then
  echo "Application values not found - payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
  exit 1
fi

echo "Printing payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
cat "payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"

count=0
until kubectl get namespace "${NAMESPACE}" 1> /dev/null 2> /dev/null || [[ $count -eq 20 ]]; do
  echo "Waiting for namespace: ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for namespace: ${NAMESPACE}"
  exit 1
else
  echo "Found namespace: ${NAMESPACE}. Sleeping for 30 seconds to wait for everything to settle down"
  sleep 1
fi

DEPLOYMENT="${COMPONENT_NAME}-${BRANCH}"
APIC_CRD="apiconnectclusters.apiconnect.ibm.com"
TIMEOUT=60
count=0
DESIRED_STATE="Ready"

until [[ $(kubectl get ${APIC_CRD}  -n  ${NAMESPACE} -o jsonpath="{range .items[*]}{.status.phase}{end}") == ${DESIRED_STATE} ||  $count -eq ${TIMEOUT} ]]; do
  echo "Waiting for ${APIC_CRD} to come up in ${NAMESPACE}"
  count=$((count + 1))
  sleep 60
done

if [[ $count -eq ${TIMEOUT} ]]; then
  echo "Timed out waiting for ${APIC_CRD} in ${NAMESPACE}"
  kubectl get all -n "${NAMESPACE}"
  exit 1
else
  echo "Found an instances of ${APIC_CRD} in a Running state in ${NAMESPACE}"
fi
#kubectl rollout status "deployment/${DEPLOYMENT}" -n "${NAMESPACE}" || exit 1

cd ..
rm -rf .testrepo
