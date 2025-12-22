FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-yarn-builder@sha256:69c8f700e3bb61bfdb78c1a1175d61079f491650ca5476c7ec9025518b554aa8 AS build-image

### BEGIN REMOTE SOURCE
# Use the COPY instruction only inside the REMOTE SOURCE block
# Use the COPY instruction only to copy files to the container path $REMOTE_SOURCES_DIR/activemq-artemis-jolokia-api-server/app
ARG REMOTE_SOURCES_DIR=/tmp/remote_source
RUN mkdir -p $REMOTE_SOURCES_DIR/activemq-artemis-jolokia-api-server/app
WORKDIR $REMOTE_SOURCES_DIR/activemq-artemis-jolokia-api-server/app
# Copy package.json and yarn.lock to the container
COPY package.json package.json
COPY yarn.lock yarn.lock
ADD . $REMOTE_SOURCES_DIR/activemq-artemis-jolokia-api-server/app
RUN command -v yarn || npm i -g yarn
### END REMOTE SOURCE

USER root

## Set directory
RUN mkdir -p /usr/src/
RUN cp -r $REMOTE_SOURCES_DIR/activemq-artemis-jolokia-api-server/app /usr/src/
WORKDIR /usr/src/app

## Install dependencies
RUN yarn install  --network-timeout 1000000

## Build application
RUN yarn build
RUN NEWKEY=`/usr/src/app/jwt-key-gen.sh` && sed -i "s/^SECRET_ACCESS_TOKEN=.*/SECRET_ACCESS_TOKEN=$NEWKEY/" /usr/src/app/.env

## Gather productization dependencies
RUN yarn install --network-timeout 1000000 --modules-folder node_modules_prod --production

FROM registry.redhat.io/ubi9/nodejs-20-minimal@sha256:4080d19195946d713665745466786c2df09a547050da323eea53c0cb715ebb02

COPY --from=build-image /usr/src/app/dist /usr/share/amq-spp/dist
COPY --from=build-image /usr/src/app/.env /usr/share/amq-spp/.env
COPY --from=build-image /usr/src/app/node_modules_prod /usr/share/amq-spp/node_modules

WORKDIR /usr/share/amq-spp

USER root
## Upgrade packages
RUN microdnf update -y --setopt=install_weak_deps=0 && rm -rf /var/cache/yum

USER 1001

ENV NODE_ENV=production

CMD ["node", "dist/app.js"]

## Labels
LABEL name="amq-broker-8/amq-broker-80-jolokia-api-server-rhel9"
LABEL description="Red Hat AMQ 8.0.0 Jolokia Api Server"
LABEL maintainer="Howard Gao <hgao@redhat.com>"
LABEL version="8.0.0"
LABEL summary="Red Hat AMQ 8.0.0 Jolokia Api Server"
LABEL amq.broker.version="8.0.0.CON.1.SR1"
LABEL com.redhat.component="amq-broker-jolokia-api-server-rhel9-container"
LABEL io.k8s.display-name="Red Hat AMQ 8.0.0 Jolokia Api Server"
LABEL io.openshift.tags="messaging,amq,integration"
