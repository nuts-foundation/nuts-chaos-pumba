#!/bin/bash

# create discovery service
docker start discovery

docker start notary
docker start pumbac
docker start timonc

# start the rest
docker start timon
docker start pumba
docker start timonb
docker start pumbab
