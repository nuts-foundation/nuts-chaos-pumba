#!/bin/bash

# Stop containers
docker kill discovery > /dev/null 2>&1
docker kill timon-init > /dev/null 2>&1
docker kill pumba-init > /dev/null 2>&1
docker kill notary-init > /dev/null 2>&1
docker kill notary > /dev/null 2>&1
docker kill timonb > /dev/null 2>&1
docker kill pumbab > /dev/null 2>&1
docker kill timonc > /dev/null 2>&1
docker kill pumbac > /dev/null 2>&1
docker kill timon > /dev/null 2>&1
docker kill pumba > /dev/null 2>&1

# remove containers
docker container rm discovery > /dev/null 2>&1
docker container rm timon-init > /dev/null 2>&1
docker container rm notary-init > /dev/null 2>&1
docker container rm pumba-init > /dev/null 2>&1
docker container rm notary > /dev/null 2>&1
docker container rm timonb > /dev/null 2>&1
docker container rm pumbab > /dev/null 2>&1
docker container rm timonc > /dev/null 2>&1
docker container rm pumbac > /dev/null 2>&1
docker container rm timon > /dev/null 2>&1
docker container rm pumba > /dev/null 2>&1

# Docker network
docker network rm nuts-chaos > /dev/null 2>&1

# Discovery files
rm nodes/discovery/*
