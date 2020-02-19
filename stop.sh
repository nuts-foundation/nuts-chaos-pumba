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
