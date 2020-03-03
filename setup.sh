#!/bin/bash

# Docker network
docker network create \
  nuts-chaos

# configs
notary_conf=$(pwd)/nodes/notary/node.conf
timon_conf=$(pwd)/nodes/timon/node.conf
pumba_conf=$(pwd)/nodes/pumba/node.conf
discovery_db=$(pwd)/nodes/discovery

echo "Starting discovery service"
docker run -d --name=discovery --network=nuts-chaos \
  -e SPRING_DATASOURCE_URL=jdbc:h2:file:/opt/nuts/data/discovery \
  -v $discovery_db:/opt/nuts/data \
  nutsfoundation/nuts-discovery:latest-dev

sleep 10s

echo "Running initial registration for 3 corda nodes"
docker run -d --name=notary-init --network=nuts-chaos -v $notary_conf:/opt/nuts/node.conf nutsfoundation/nuts-consent-cordapp:latest-dev -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console --initial-registration
docker run -d --name=timon-init --network=nuts-chaos -v $timon_conf:/opt/nuts/node.conf nutsfoundation/nuts-consent-cordapp:latest-dev -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console --initial-registration
docker run -d --name=pumba-init --network=nuts-chaos -v $pumba_conf:/opt/nuts/node.conf nutsfoundation/nuts-consent-cordapp:latest-dev -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console --initial-registration

# wait for containers to complete
docker wait notary-init
docker wait timon-init
docker wait pumba-init

# create new images
echo "Commiting Corda registration to new image"
docker commit notary-init chaos/notary
docker commit timon-init chaos/timon
docker commit pumba-init chaos/pumba

# remove old
docker container rm notary-init
docker container rm timon-init
docker container rm pumba-init

# create corda containers
echo "Creating 2 Corda containers"
docker create --name timonc --network=nuts-chaos \
  -v $timon_conf:/opt/nuts/node.conf \
  --entrypoint=java \
  chaos/timon -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console --no-local-shell

docker create --name pumbac --network=nuts-chaos \
  -v $pumba_conf:/opt/nuts/node.conf \
  --entrypoint=java \
  chaos/pumba -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console --no-local-shell

# create bridge containers
timon_props=$(pwd)/nodes/timon/application.properties
pumba_props=$(pwd)/nodes/pumba/application.properties

echo "Creating 2 bridge containers"
docker create --name timonb --network=nuts-chaos \
  -v $timon_props:/opt/nuts/application.properties \
  nutsfoundation/nuts-consent-bridge:latest-dev

docker create --name pumbab --network=nuts-chaos \
  -v $pumba_props:/opt/nuts/application.properties \
  nutsfoundation/nuts-consent-bridge:latest-dev

# create service containers
timon_yaml=$(pwd)/nodes/timon/nuts.yaml
pumba_yaml=$(pwd)/nodes/pumba/nuts.yaml
timon_keys=$(pwd)/nodes/timon/keys
pumba_keys=$(pwd)/nodes/pumba/keys
registry=$(pwd)/nodes/registry

echo "Creating 2 service containers"
docker create --name timon --network=nuts-chaos \
  -e NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
  -p 11323:1323 \
  -v $timon_yaml:/opt/nuts/nuts.yaml \
  -v $timon_keys:/opt/nuts/keys \
  -v $registry:/opt/nuts/data \
  nutsfoundation/nuts-service-space:latest

docker create --name pumba --network=nuts-chaos \
  -e NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
  -p 21323:1323 \
  -v $pumba_yaml:/opt/nuts/nuts.yaml \
  -v $pumba_keys:/opt/nuts/keys \
  -v $registry:/opt/nuts/data \
  nutsfoundation/nuts-service-space:latest

# notary setup
# destroys itself
echo "Letting notary register itself"
docker run -d --name notary --network=nuts-chaos \
  --hostname=notary \
  -v $notary_conf:/opt/nuts/node.conf \
  chaos/notary -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console --no-local-shell

# wait for container
docker wait notary

# commit
echo "Commit notary changes"
docker commit notary chaos/notary
docker container rm notary

# rewrite corda containers to remove network-params
echo "Running notary bin.bash"
docker run -d -it --name notary --network=nuts-chaos \
  --entrypoint=/bin/bash \
  chaos/notary

sleep 10s

echo "Removing networkparams from notary"
docker exec notary rm /opt/nuts/network-parameters
echo "Kill notary"
docker kill notary
echo "Commit notary changes"
docker commit notary chaos/notary
docker container rm notary

# recreate notary
echo "Creating notary container"
docker create --name notary --network=nuts-chaos \
  -v $notary_conf:/opt/nuts/node.conf \
  --entrypoint=java \
  chaos/notary -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console --no-local-shell

echo "Stopping discovery"
docker stop discovery