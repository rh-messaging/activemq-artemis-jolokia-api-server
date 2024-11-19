FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-yarn-builder@sha256:4f578a4e083bedd7467643b26bedf284f2d1062ed22416662d3556a3f4482cb1 AS BUILD_IMAGE

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

FROM registry-proxy.engineering.redhat.com/rh-osbs/ubi8-nodejs-20-minimal@sha256:8db813739bca22520fac586eb2bcedc53e5703d6181686cadd2b5225a9a533cb

COPY --from=build-image /usr/src/app/dist /usr/share/amq-spp/dist
COPY --from=build-image /usr/src/app/.env /usr/share/amq-spp/.env
COPY --from=build-image /usr/src/app/node_modules_prod /usr/share/amq-spp/node_modules

WORKDIR /usr/share/amq-spp

USER 1001

ENV NODE_ENV=production

CMD ["node", "dist/app.js"]

## Labels
LABEL name="amq-broker-7/amq-broker-713-jolokia-api-server-rhel8"
LABEL description="Red Hat AMQ 7.13 Jolokia API Server"
LABEL maintainer="Howard Gao <hgao@redhat.com>"
LABEL version="0.1.1"
LABEL summary="Red Hat AMQ 7.13 Jolokia Api Server"
LABEL amq.broker.version="7.13.0.CON.1.ER1"
LABEL com.redhat.component="amq-broker-jolokia-api-server-rhel8-container"
LABEL io.k8s.display-name="Red Hat AMQ Jolokia API Server"
LABEL io.openshift.tags="messaging,amq,integration"