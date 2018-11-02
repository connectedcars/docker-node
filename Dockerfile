ARG NODE_VERSION=10.0.0
ARG NPM_VERSION=6.0.0
ARG YARN_VERSION=1.6.0

FROM ubuntu:18.04 as downloader

# Import
ARG NODE_VERSION
ARG YARN_VERSION

# Disable color output 
ENV NO_COLOR=true

# Install base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
		git \
		openssh-client \
		procps \
    gnupg \
    ca-certificates \
		curl \
		wget \
    xz-utils \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt

# Import gpg keys for download verification
RUN mkdir -p /tmp/keys
COPY keys/*.gpg /tmp/keys/
RUN gpg --batch --yes --import /tmp/keys/*.gpg

# Install Yarn
RUN curl -sSLO "https://nodejs.org/dist/v${NODE_VERSION}/node-v$NODE_VERSION-linux-x64.tar.xz"
RUN curl -sSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc"
RUN gpg -q --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc
RUN grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c -
RUN tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /opt --no-same-owner
RUN ln -s /opt/node-v$NODE_VERSION-linux-x64/bin/node /usr/local/bin/node
RUN /opt/node-v$NODE_VERSION-linux-x64/bin/npm install -g npm@$NPM_VERSION

# Install Yarn
RUN curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz"
RUN curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc"
RUN gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz
RUN tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ --no-same-owner

FROM ubuntu:18.04 as base

RUN echo "Building base image"

# Import
ARG NODE_VERSION
ARG YARN_VERSION

# Disable color output 
ENV NO_COLOR=true

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates

# Copy over node
COPY --from=downloader /opt/node-v$NODE_VERSION-linux-x64/ /usr/local
RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Copy over yarn
COPY --from=downloader /opt/yarn-v$YARN_VERSION /usr/local

# Create user for node
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

RUN mkdir -p /app/tmp
RUN chown node:node /app/tmp

USER node

ENV NODE_ENV production
WORKDIR /app

# Disable color output
RUN npm config set color false

FROM ubuntu:18.04 as builder

RUN echo "Building builder image"

# Import
ARG NODE_VERSION
ARG YARN_VERSION

# Disable color output 
ENV NO_COLOR=true

RUN apt-get update && apt-get install -y --no-install-recommends build-essential python git ca-certificates

# Copy over node
COPY --from=downloader /opt/node-v$NODE_VERSION-linux-x64/ /usr/local
RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Copy over yarn
COPY --from=downloader /opt/yarn-v$YARN_VERSION /usr/local

# Setup private repo npm/yarn wrappers
ARG GITHUB_PAT
ADD ./opt /opt
RUN cd /opt/connectedcars/package-auth && yarn
ENV PATH /opt/connectedcars/bin:$PATH

# Disable color output
RUN npm config set color false
