# docker-node

Docker Ubuntu 18.04 base image for node build and production:

``` bash
docker build --build-arg=NODE_VERSION=10.0.0 --build-arg=NPM_VERSION=6.0.0 --build-arg=YARN_VERSION=1.6.0 --target base -t node-base:10.0.0 -t node-base:10.x .
docker build --build-arg=NODE_VERSION=10.0.0 --build-arg=NPM_VERSION=6.0.0 --build-arg=YARN_VERSION=1.6.0 --target builder -t node-builder:10.0.0 -t node-builder:10.x .

docker build --build-arg=NODE_VERSION=8.11.1 --build-arg=NPM_VERSION=6.0.0 --build-arg=YARN_VERSION=1.6.0 --target base -t node-base:8.11.1 -t node-base:8.x .
docker build --build-arg=NODE_VERSION=8.11.1 --build-arg=NPM_VERSION=6.0.0 --build-arg=YARN_VERSION=1.6.0 --target builder -t node-builder:8.11.1 -t node-builder:8.x .
```