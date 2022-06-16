#!/bin/bash

# Functions
intro () {
  printf "\n\n############################################################\n"
  printf "# $1\n"
  printf "############################################################\n"
}


# Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

CHART_PATH="$SCRIPT_DIR/.local/"
SECRETS_PATH="$SCRIPT_DIR/secrets"
DOMAIN="dataos.local"

intro "Create Cluster"
kind create cluster --name 'dpib' --config $SCRIPT_DIR/kind/config.yaml

# Script Directories
intro "Directories"
printf "Script Path: $SCRIPT_DIR\n"
printf "Chart Path: $CHART_PATH\n"
printf "Secrets Path: $SECRETS_PATH\n"
printf "Domain: $DOMAIN\n"


intro "Create Directories"

DIRECTORIES=(
  ssl
  secrets
)

for i in $DIRECTORIES; do 
  printf "$SCRIPT_DIR/$i"
  if [ ! -d $SCRIPT_DIR/$i ]; then
    mkdir $SCRIPT_DIR/$i
  fi
done

intro "Create Root Certificiate"
openssl req \
  -x509 \
  -sha256 \
  -nodes \
  -days 365 \
  -newkey rsa:2048 \
  -subj '/O=example Inc./CN=example.c\nom' \
  -keyout $SCRIPT_DIR/cicd-apps/ssl/dataos.local.key \
  -out $SCRIPT_DIR/cicd-apps/ssl/dataos.local.crt

intro "SSL Certificates"
openssl req \
  -out $SCRIPT_DIR/cicd-apps/ssl/apps.dataos.local.csr \
  -newkey rsa:2048 \
  -nodes \
  -keyout $SCRIPT_DIR/cicd-apps/ssl/apps.dataos.local.key \
  -subj "/CN=dataos.local/O=dataos organization"

intro "x509 Cert"
openssl x509 \
  -req \
  -sha256 \
  -days 365 \
  -CA $SCRIPT_DIR/cicd-apps/ssl/dataos.local.crt \
  -CAkey $SCRIPT_DIR/cicd-apps/ssl/dataos.local.key \
  -set_serial 0 \
  -in $SCRIPT_DIR/cicd-apps/ssl/apps.dataos.local.csr \
  -out $SCRIPT_DIR/cicd-apps/ssl/apps.dataos.local.crt

intro "Install ArgoCD Pre-reqs"
# We'll use Kustomize instead, Argo reccomends.
# kubectl apply -f $SCRIPT_DIR/cicd-apps/argo-base/argo-namespace.yaml
# helm repo add argo-helm https://argoproj.github.io/argo-helm
# 
# ARGO_INSTALLED=$(helm list --all-namespaces | grep argo-cd)
# if [ "$ARGO_INSTALLED" == "" ]; then
#   helm install argo-helm/argo-cd \
#     --namespace cicd \
#     --generate-name \
#     -f $SCRIPT_DIR/cicd-apps/argo-cd/values.yaml
# else
#   printf "ArgoCD already installed....skipping"
# fi

intro "Apply k8s yaml to ensure we have namespaces"
for i in $(ls $SCRIPT_DIR/cicd-apps); do 
  if [ ! -d $i ]; then
    printf "Apply Directory: $SCRIPT_DIR/cicd-apps/$i"
    kubectl apply -f $SCRIPT_DIR/cicd-apps/$i
  else
    printf "Empty Directory, skipping..."
  fi
done

# Create SSL Secrets
# kubectl delete -n istio-system secret ssl-secret
# kubectl create -n istio-system secret tls ssl-secret \
#   --key=$SCRIPT_DIR/cicd-apps/ssl/apps.dataos.local.key \
#   --cert=$SCRIPT_DIR/cicd-apps/ssl/apps.dataos.local.crt

# intro "Installing Helm Charts"
# # Helm Chart
# helm repo add istio https://istio-release.storage.googleapis.com/charts
# helm install istio-base istio/base
# helm install istiod istio/istiod -n istio-system --wait
# helm install istio-ingress istio/gateway -n istio-ingress
# 
# 
# intro "Installing Istio Gateway & Virtual Service"
# # Add gateway and virtual service, why can't this be in a yaml file?
# cat <<EOF | kubectl apply -f -
# ---
# apiVersion: networking.istio.io/v1alpha3
# kind: Gateway
# metadata:
#   name: dataos
# spec:
#   selector:
#     istio: ingressgateway # use istio default ingress gateway
#   servers:
#   - port:
#       number: 443
#       name: https
#       protocol: HTTPS
#     tls:
#       mode: SIMPLE
#       credentialName: ssl-credential # must be the same as secret
#     hosts:
#     - dataos.local
# ---
# apiVersion: networking.istio.io/v1alpha3
# kind: VirtualService
# metadata:
#   name: dataos-vs
# spec:
#   hosts:
#   - "dataos.local"
#   gateways:
#   - dataos-gateway
#   http:
#   - match:
#     - uri:
#         prefix: /argocd
#     - uri:
#         prefix: /
#     route:
#     - destination:
#         port:
#           number: 8000
#         host: dataos.local
# EOF

