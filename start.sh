#!/bin/bash

# create discovery service
docker start discovery

# start nodes
docker start notary
docker start timon
docker start pumba

# wait
sleep 60s
docker exec -it timon rm /opt/nuts/network-parameters
docker exec -it notary rm /opt/nuts/network-parameters
docker exec -it pumba rm /opt/nuts/network-parameters

# restart
docker restart notary
docker restart timon
docker restart pumba
