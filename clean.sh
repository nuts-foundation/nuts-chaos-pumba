#!/bin/bash

# Docker network
docker network rm nuts-chaos

# Stop containers
docker kill discovery
docker kill timon-init
docker kill pumba-init
docker kill notary-init
docker kill notary
docker kill timon
docker kill pumba

# remove containers
docker container rm discovery
docker container rm timon-init
docker container rm notary-init
docker container rm pumba-init
docker container rm notary
docker container rm timon
docker container rm pumba
