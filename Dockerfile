FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-yarn-builder@sha256:c1678723b2a425c129ad180fcca772b061acf06a73b2e5ec76de078d6ae84643 AS build-image

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

FROM registry.redhat.io/ubi9/nodejs-20-minimal@sha256:550397db3b3f03d800655ed18b89afb4e5df328769b45e12821be31add37f026

COPY --from=build-image /usr/src/app/dist /usr/share/amq-spp/dist
COPY --from=build-image /usr/src/app/.env /usr/share/amq-spp/.env
COPY --from=build-image /usr/src/app/node_modules_prod /usr/share/amq-spp/node_modules

WORKDIR /usr/share/amq-spp

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
