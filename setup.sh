#!/bin/bash

# Docker network
docker network create \
  nuts-chaos

# create containers
notary_conf=$(pwd)/nodes/notary/node.conf
timon_conf=$(pwd)/nodes/timon/node.conf
pumba_conf=$(pwd)/nodes/pumba/node.conf
docker run -d --name=discovery --network=nuts-chaos nutsfoundation/nuts-discovery:latest-dev

docker run -d --name=notary-init --network=nuts-chaos -v $notary_conf:/opt/nuts/node.conf nutsfoundation/nuts-consent-cordapp:latest-dev -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console --initial-registration
docker run -d --name=timon-init --network=nuts-chaos -v $timon_conf:/opt/nuts/node.conf nutsfoundation/nuts-consent-cordapp:latest-dev -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console --initial-registration
docker run -d --name=pumba-init --network=nuts-chaos -v $pumba_conf:/opt/nuts/node.conf nutsfoundation/nuts-consent-cordapp:latest-dev -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console --initial-registration

# wait for containers to complete
docker wait notary-init
docker wait timon-init
docker wait pumba-init

# create new images
docker commit notary-init chaos/notary
docker commit timon-init chaos/timon
docker commit pumba-init chaos/pumba

# remove old
docker container rm notary-init
docker container rm timon-init
docker container rm pumba-init

# create corda containers
docker create -it --name notary --network=nuts-chaos \
  --hostname=notary \
  -v $notary_conf:/opt/nuts/node.conf \
  chaos/notary -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console

docker create -it --name timonc --network=nuts-chaos \
  -v $timon_conf:/opt/nuts/node.conf \
  --entrypoint=java \
  chaos/timon -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console

docker create -it --name pumbac --network=nuts-chaos \
  -v $pumba_conf:/opt/nuts/node.conf \
  --entrypoint=java \
  chaos/pumba -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console

# create bridge containers
timon_props=$(pwd)/nodes/timon/application.properties
pumba_props=$(pwd)/nodes/pumba/application.properties

docker create -it --name timonb --network=nuts-chaos \
  -v $timon_props:/opt/nuts/application.properties \
  nutsfoundation/nuts-consent-bridge:latest-dev

docker create -it --name pumbab --network=nuts-chaos \
  -v $pumba_props:/opt/nuts/application.properties \
  nutsfoundation/nuts-consent-bridge:latest-dev

# create service containers
timon_yaml=$(pwd)/nodes/timon/nuts.yaml
pumba_yaml=$(pwd)/nodes/pumba/nuts.yaml

docker create -it --name timon --network=nuts-chaos \
  -e NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
  -v $timon_yaml:/opt/nuts/nuts.yaml \
  nutsfoundation/nuts-service-space:latest

docker create -it --name pumba --network=nuts-chaos \
  -e NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
  -v $pumba_yaml:/opt/nuts/nuts.yaml \
  nutsfoundation/nuts-service-space:latest
