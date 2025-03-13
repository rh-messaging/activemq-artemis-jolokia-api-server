#!/usr/bin/env sh

oc kustomize deploy | oc delete -f -
oc delete secret jolokia-api-server-selfsigned-ca-cert-secret -n activemq-artemis-jolokia-api-server
oc delete secret jolokia-api-server-selfsigned-ca-cert-secret -n openshift-operators
