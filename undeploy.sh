#!/usr/bin/env sh

function printUsage() {
  echo "${SCRIPT_NAME}: Deleting the jolokia api server from openshift"
  echo "Usage:"
  echo "  ./${SCRIPT_NAME} -i|--image <image url>"
  echo "Options: "
  echo "  -c|--certManagerNamespace  give the namespace cert manager is installed in, will search for it in the Subscriptions otherwise"
  echo "  -h|--help   Print this message."
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      printUsage
      exit 0
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
      exit 1
    fi
  fi
fi
echo "cert-manager's namespace: $certManagerNamespace"
oc kustomize deploy \
    | sed "s|namespace: openshift-operators|namespace: ${certManagerNamespace}|" \
    | oc delete -f -
oc delete secret jolokia-api-server-selfsigned-ca-cert-secret -n activemq-artemis-jolokia-api-server
oc delete secret jolokia-api-server-selfsigned-ca-cert-secret -n ${certManagerNamespace}
