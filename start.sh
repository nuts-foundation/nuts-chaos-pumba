#!/bin/bash

notary_conf=$(pwd)/nodes/notary/node.conf
timon_conf=$(pwd)/nodes/timon/node.conf
pumba_conf=$(pwd)/nodes/pumba/node.conf

# create discovery service
docker start discovery

# destroys itself
docker run -d -it --name notary --network=nuts-chaos \
  --hostname=notary \
  -v $notary_conf:/opt/nuts/node.conf \
  chaos/notary -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console --no-local-shell

# wait for container
sleep 60s
docker kill notary

# commit
docker commit notary chaos/notary
docker container rm notary

# rewrite corda containers to remove network-params
docker run -d -it --name notary --network=nuts-chaos \
  --entrypoint=/bin/bash \
  chaos/notary

sleep 20s

docker exec -it notary rm /opt/nuts/network-parameters
docker kill notary
docker commit notary chaos/notary
docker container rm notary

# start nodes
docker run -d -it --name notary --network=nuts-chaos \
  -v $notary_conf:/opt/nuts/node.conf \
  --entrypoint=java \
  chaos/notary -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console --no-local-shell

docker start pumbac
docker start timonc

# start the rest
docker start timon
docker start pumba
docker start timonb
docker start pumbab
