#!/usr/bin/env sh

# find the cert-manager operator namespace, if this can't be retrived there's no
# possibility to proceed
certManagerNamespace=$(oc get Subscriptions --all-namespaces -ojson | jq -r '.items[] | select(.spec.name == "cert-manager") | .metadata.namespace')
if test -z "$certManagerNamespace"
then
  certManagerNamespace=$(oc get Subscriptions --all-namespaces -ojson | jq -r '.items[] | select(.spec.name == "openshift-cert-manager-operator") | .metadata.namespace')
  if test -z "$certManagerNamespace"
  then
    echo "cert-manager's namespace can't be determined, defaulting to default namespace"
    certManagerNamespace="openshift-operators"
  fi
fi
echo "cert-manager's namespace: $certManagerNamespace"
oc kustomize deploy \
    | sed "s|namespace: openshift-operators|namespace: ${certManagerNamespace}|" \
    | oc delete -f -
oc delete secret jolokia-api-server-selfsigned-ca-cert-secret -n activemq-artemis-jolokia-api-server
oc delete secret jolokia-api-server-selfsigned-ca-cert-secret -n ${certManagerNamespace}
