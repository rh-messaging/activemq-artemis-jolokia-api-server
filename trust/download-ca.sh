#!/bin/bash
optstring=":i:c:|l|h" 
Help()
{
    # Display Help
    echo "Download the CA of an issuer and stores it in the ca.crt file, requires jq and base64"
    echo
    echo "Syntax: scriptTemplate [$optstring]"
    echo "options:"
    echo "h                  Print this Help."
    echo "i issuer           The issuer to whom download the CA."
    echo "c clusterissuer    The issuer to whom download the CA."
    echo "l                  List issuers."
    echo
}

while getopts $optstring option; do
    case $option in
        h) # display Help
            Help
            exit;;
        l) # display Help
            echo issuers:
            echo
            oc get issuers
            echo
            echo clusterissuers:
            echo
            oc get clusterissuers
            exit;;
        c) # display Help
            certManagerNamespace=$(oc get Subscriptions --all-namespaces -ojson | jq -r '.items[] | select(.spec.name == "cert-manager") | .metadata.namespace')
            secretName=$(oc get clusterissuer ${OPTARG} -n ${certManagerNamespace} -ojson | jq -r '.spec.ca.secretName')
            echo Downloading the secret ${secretName} from the issuer ${OPTARG} in the ca.crt file:
            oc get secrets ${secretName} -n ${certManagerNamespace} -o json | jq -r '.data."tls.crt"' | base64 -d > ca.crt
            echo
            openssl x509 -in ca.crt -text -noout
            exit;;
        i) # display Help
            secretName=$(oc get issuer ${OPTARG} -o json | jq -r '.spec.ca.secretName')
            echo Downloading the secret ${secretName} from the issuer ${OPTARG} in the ca.crt file:
            oc get secrets ${secretName} -o json | jq -r '.data."tls.crt"' | base64 -d > ca.crt
            echo
            openssl x509 -in ca.crt -text -noout
            exit;;
        :)
            echo Error missing an argument
            Help
            exit 1;;
        \?) # incorrect option
            echo "Error: Invalid option ${OPTARG}"
            exit;;
    esac
done

