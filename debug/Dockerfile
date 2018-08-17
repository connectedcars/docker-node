FROM ubuntu:18.04 as builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    make g++ libssl-dev git build-essential

RUN apt-get install -y --no-install-recommends wget ca-certificates

RUN wget -q https://nodejs.org/dist/v10.9.0/node-v10.9.0.tar.gz

RUN tar -xzf node-v10.9.0.tar.gz

RUN apt-get install -y --no-install-recommends python

RUN ls -la

WORKDIR node-v10.9.0 

RUN ./configure --debug --prefix=/opt/node-v10.9.0-linux-x64/

RUN make
RUN make install