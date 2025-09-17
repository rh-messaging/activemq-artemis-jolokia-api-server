#!/usr/bin/env sh

DEFAULT_IMAGE=registry.redhat.io/amq-broker-8/amq-broker-80-jolokia-api-server-rhel9@sha256:17e822d161b631e0fcbc3450b0bdcf31db9ab44183d0c6c17fcedc0343ab07fd
API_SERVER_IMAGE=${DEFAULT_IMAGE}

SCRIPT_NAME=$(basename "$0")

function printUsage() {
  echo "${SCRIPT_NAME}: Deploying to openshift"
  echo "Usage:"
  echo "  ./${SCRIPT_NAME} -i|--image <image url>"
  echo "Options: "
  echo "  -i|--image  Specify the plugin image to deploy. (default is ${DEFAULT_IMAGE})"
  echo "  -c|--certManagerNamespace  give the namespace cert manager is installed in, will search for it in the Subscriptions otherwise"
  echo "  -h|--help   Print this message."
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      printUsage
      exit 0
      ;;
    -i|--image)
      API_SERVER_IMAGE="$2"
      shift
      shift
      ;;
    -c|--certManagerNamespace)
      certManagerNamespace="$2"
      shift
      shift
      ;;
    -*|--*)
      echo "Unknown option $1"
      printUsage
      exit 1
      ;;
    *)
      ;;
  esac
done

# if the user has overridden the certManagerNamespace don't try to search for it
if test -z "$certManagerNamespace"
  then
  # find the cert-manager operator namespace, if this can't be retrived there's no
  # possibility to proceed
  certManagerNamespace=$(oc get Subscriptions --all-namespaces -ojson | jq -r '.items[] | select(.spec.name == "cert-manager") | .metadata.namespace')
  if test -z "$certManagerNamespace"
  then
    certManagerNamespace=$(oc get Subscriptions --all-namespaces -ojson | jq -r '.items[] | select(.spec.name == "openshift-cert-manager-operator") | .metadata.namespace')
    if test -z "$certManagerNamespace"
    then
      echo "Error: cert-manager's namespace can't be determined"
      oc get Subscriptions --all-namespaces
      exit 1
    fi
  fi
fi
echo "cert-manager's namespace: $certManagerNamespace"

# retrieve the cluster domain to produce a valid cluster issuer
clusterDomain=$(oc get -n openshift-ingress-operator ingresscontroller/default -o json | jq -r '.status.domain')
if test -z "$certManagerNamespace"
then
  echo "The cluster domain can't be retrived"
  exit 1
fi
echo "cluster domain: $clusterDomain"

echo "deploying using image: ${API_SERVER_IMAGE}"
oc kustomize deploy \
    | sed "s|image: .*|image: ${API_SERVER_IMAGE}|" \
    | sed "s|- issuer.mydomain.tld|- issuer.${clusterDomain}|" \
    | sed "s|namespace: openshift-operators|namespace: ${certManagerNamespace}|" \
    | oc apply -f -

while ! oc get secret jolokia-api-server-selfsigned-ca-cert-secret   --namespace=${certManagerNamespace}; do echo "Waiting for the CA"; sleep 1; done
# copy the secret from the cert-manager namespace to the jolokia api server
# namespace
oc get secret jolokia-api-server-selfsigned-ca-cert-secret \
    --namespace=${certManagerNamespace} -oyaml \
    | sed s/"namespace: ${certManagerNamespace}"/"namespace: activemq-artemis-jolokia-api-server"/\ \
    | oc apply -n activemq-artemis-jolokia-api-server -f -
