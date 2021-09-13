ARG NODE_VERSION=14.17.6
ARG NPM_VERSION=6.0.0
ARG YARN_VERSION=1.6.0

FROM ubuntu:20.04 as downloader

# Import
ARG NODE_VERSION
ARG YARN_VERSION
ARG NPM_VERSION

RUN echo "Building downloader image with node version: ${NODE_VERSION}"

# Disable color output and be less verbose
ENV NO_COLOR=true
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Install base dependencies
RUN apt-get update -qq && apt-get install -qq -y --no-install-recommends \
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

RUN echo "Downloading NodeJS version: $NODE_VERSION"
RUN curl -sSLO --fail "https://nodejs.org/dist/v${NODE_VERSION}/node-v$NODE_VERSION-linux-x64.tar.xz" \
 	&& curl -sSLO --compressed --fail "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
	&& gpg -q --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc

# Do npm upgrade in same step as it will fail with "EXDEV: cross-device link not permitted" if it's not done in the same go:
# https://github.com/meteor/meteor/issues/7852
RUN echo "Extracting node and installing NPM version: $NPM_VERSION"
RUN grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c -
RUN tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /opt --no-same-owner \
	&& ln -s /opt/node-v$NODE_VERSION-linux-x64/bin/node /usr/local/bin/node \
	&& /opt/node-v$NODE_VERSION-linux-x64/bin/npm install -g npm@$NPM_VERSION

# Install Yarn
RUN echo "Downloading Yarn version: $YARN_VERSION"
RUN curl -fSLO --compressed --fail "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz"
RUN curl -fSLO --compressed --fail "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc"
RUN gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz
RUN tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ --no-same-owner

FROM ubuntu:20.04 as base

# Import
ARG NODE_VERSION
ARG YARN_VERSION

RUN echo "Building base image with node version: ${NODE_VERSION}"

# Disable color output and be less verbose
ENV NO_COLOR=true
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update -qq && \
	apt-get dist-upgrade -qq -y --no-install-recommends && \
	apt-get install -qq -y --no-install-recommends ca-certificates && \
	rm -rf /var/lib/apt/lists/*

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

# Disable color output and be less verbose
RUN npm config set color false

FROM ubuntu:20.04 as builder

# Import
ARG NODE_VERSION
ARG YARN_VERSION

RUN echo "Building builder image with node version: ${NODE_VERSION}"

# Disable color output 
ENV NO_COLOR=true
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update -qq && \
	apt-get dist-upgrade -qq -y --no-install-recommends && \
	apt-get install -qq -y --no-install-recommends build-essential python git ca-certificates openssh-client software-properties-common && \
	add-apt-repository "deb http://mirrors.kernel.org/ubuntu/ bionic main" && \
	rm -rf /var/lib/apt/lists/*

# Make sure we use mysql-server from Ubuntu 18.04
RUN echo 'Package: mysql-server\n\
Pin: release n=bionic\n\
Pin-Priority: 1001\n' > /etc/apt/preferences.d/mysql 

# Copy over node
COPY --from=downloader /opt/node-v$NODE_VERSION-linux-x64/ /usr/local
RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Copy over yarn
COPY --from=downloader /opt/yarn-v$YARN_VERSION /usr/local

# Disable color output
RUN npm config set color false

# When running as root don't drop to directory user
RUN npm config set unsafe-perm true
RUN npm config set user root
RUN npm config set group root

# Setup github token injection wrappers for npm and yarn
RUN npm install -g https://github.com/connectedcars/node-package-json-rewrite
RUN mkdir -p /opt/connectedcars/bin
RUN ln -s /usr/local/bin/package-json-rewrite /opt/connectedcars/bin/npm
RUN ln -s /usr/local/bin/package-json-rewrite /opt/connectedcars/bin/yarn
ENV PATH /opt/connectedcars/bin:$PATH

# Read NPM token from environment variable
RUN npm config set '//registry.npmjs.org/:_authToken' '${NPM_TOKEN}' --global

# Fix for npm "prepare" not running under root
RUN groupadd builder && useradd --no-log-init --create-home -r -g builder builder
RUN mkdir -p /app/tmp
RUN chown -R builder:builder /app

# Disable SSH host key verification
ENV GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

# Add github.com keys to to known_hosts as a fallback if the user overview GIT_SSH_COMMAND
RUN mkdir /home/builder/.ssh
RUN chown -R builder:builder /home/builder/.ssh
RUN ssh-keyscan -t rsa github.com > /home/builder/.ssh/known_hosts
RUN chown -R builder:builder /home/builder/.ssh
RUN mkdir /root/.ssh
RUN ssh-keyscan -t rsa github.com > /root/.ssh/known_hosts

# Copy in the encypted ssh key
COPY --chown=builder:builder build.key /home/builder
RUN chmod 600 /home/builder/build.key
ENV SSH_KEY_PATH=/home/builder/build.key
