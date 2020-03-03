# nuts-chaos-pumba
Chaos testing for Nuts

## Install dependencies

(todo, elaborate)
 - install nodejs
 - npm install mocha
 - install pumba 

## setup

run
```shell script
./setup.sh
```

This will create all containers and also initialize everything with the correct keys/network setup. It'll also add organisations and vendors.

## clean

run
```shell script
./clean.sh
```

## run tests

First start the containers:

```shell script
./start.sh
```

Then run tests

```shell script
mocha test --exit
```

or 

```shell script
npm test --exit
```
