# Jolokia api-server

The Jolokia api-server is an express js server that serves an OpenApi defined
api as an overlay to jolokia servers, translating the jolokia answers to json
when needed.

Checkout the api.md file to know more about what operations are currently
supported.

## Dev setup

### Create the cluster issuer

To allow the jolokia api server to trust the broker in case the broker is using
a TLS secured connection, you'll need to have a trust bundle to load. The trust
bundle will come from a cluster issuer that is also used to issue certs for the
broker.

One way to obtain this cluster issuer correctly configured is to deploy the
upstream's jolokia api server to your cluster regardless to the fact that you
may also run it locally alongside the bridge when developing locally.

To do that follow the section about deploying.

#### using the cluster issuer to secure the connection

The cluster issuer needs to be used to generate the cert the broker would use
for its console.

An example for a broker called ex-aao within the myproject namespace would
be:

> [!NOTE]
> you need to adapt the domain name in the CR with the one of your cluster. One
> way to obtain it is to this one liner:
> `oc get -n openshift-ingress-operator ingresscontroller/default -o json | jq '.status.domain'`

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ex-aao-console-certificate-cert
  namespace: myproject
spec:
  secretName: ex-aao-console-certificate-cert-secret
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048

  isCA: false

  commonName: ex-aao-console-cert

  dnsNames:
    - ex-aao-wconsj-0-svc-rte-default.mydomain.tld
    - ex-aao-wconsj-0-svc.default
  issuerRef:
    name: jolokia-api-server-selfsigned-issuer
    kind: ClusterIssuer
    group: cert-manager.io
```

### Build and start

If you have followed the previous step, you need to download the trust bundle so
that your dev env has access to it and can connect to a TLS broker.

```sh
cd trust
./download-ca.sh -c jolokia-api-server-selfsigned-issuer
cd ..
yarn build
yarn start
```

## Documentation generation

After updating the `openapi.yml` file, please make sure to generate the
documentation:

```sh
yarn run build-api-doc
```

## Production build

1. Build the image:
   ```sh
   docker build -t quay.io/arkmq-org/activemq-artemis-jolokia-api-server:latest .
   ```
2. Push the image to image registry:
   ```sh
   docker push quay.io/arkmq-org/activemq-artemis-jolokia-api-server:latest
   ```

### deploy the service

```sh
./deploy.sh [-i <image> -n]
```

The optional `-i <image>` (or `--image <image>`) argument allows you to pass in
the plugin image. If not specified the default
`quay.io/arkmq-org/activemq-artemis-jolokia-api-server:latest` is
deployed. for example:

```sh
./deploy.sh -i quay.io/<repo-username>/activemq-artemis-jolokia-api-server:1.0.1
```

The optional -ns (or --nosec) argument can be used to disable security.

The `deploy.sh` script uses `oc kustomize` (built-in
[kustomize](https://github.com/kubernetes-sigs/kustomize)) command to configure
and deploy the plugin using resources and patches defined under ./deploy
directory.

To undeploy, run

```sh
./undeploy.sh
```

### Accessing a jolokia endpoint

When an authenticated client sends a request to the api-server, it should
present its token in the request header.

'Authorization: Bearer `token`'

It also need to give the `targetEndpoint` in the query part of the request if
the request is to access an jolokia endpoint.

For example `/execBrokerOperation?targetEndpoint=broker1`.

### Direct Proxy

Direct Proxy means a client can pass a broker's endpoint info to the api-server
in order to access it via the api-server. For example the [self-provisioning
plugin](https://github.com/arkmq-org/activemq-artemis-self-provisioning-plugin)
uses this api to access the jolokia of a broker's jolokia endpoint.
