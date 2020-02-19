#!/bin/bash

notary_conf=$(pwd)/nodes/notary/node.conf
timon_conf=$(pwd)/nodes/timon/node.conf
pumba_conf=$(pwd)/nodes/pumba/node.conf

# create discovery service
docker start discovery

# commit old containers to new image
docker commit timonc chaos/timon
docker commit pumbac chaos/pumba
docker commit notary chaos/notary
docker container rm timonc
docker container rm pumbac
docker container rm notary

# rewrite corda containers to remove network-params
docker run -d -it --name notary --network=nuts-chaos \
  --entrypoint=/bin/bash \
  chaos/notary

docker run -d -it --name timonc --network=nuts-chaos \
  --entrypoint=/bin/bash \
  chaos/timon

docker run -d -it --name pumbac --network=nuts-chaos \
  --entrypoint=/bin/bash \
  chaos/pumba

sleep 10s

docker exec -it timonc rm /opt/nuts/network-parameters
docker exec -it pumbac rm /opt/nuts/network-parameters
docker exec -it notary rm /opt/nuts/network-parameters
docker kill timonc
docker kill pumbac
docker kill notary
docker commit timonc chaos/timon
docker commit pumbac chaos/pumba
docker commit notary chaos/notary
docker container rm timonc
docker container rm pumbac
docker container rm notary

# start nodes
docker run -d -it --name notary --network=nuts-chaos \
  -v $notary_conf:/opt/nuts/node.conf \
  --entrypoint=java \
  chaos/notary -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console

sleep 60s

docker run -d -it --name timonc --network=nuts-chaos \
  -v $timon_conf:/opt/nuts/node.conf \
  --entrypoint=java \
  chaos/timon -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console

docker run -d -it --name pumbac --network=nuts-chaos \
  -v $pumba_conf:/opt/nuts/node.conf \
  --entrypoint=java \
  chaos/pumba -jar /opt/nuts/corda.jar --network-root-truststore-password=changeit --log-to-console

# start the rest
docker start timon
docker start pumba
docker start timonb
docker start pumbab
