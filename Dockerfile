ARG NODE_VERSION=22.0.0
ARG NPM_VERSION=6.0.0
ARG YARN_VERSION=1.6.0

FROM ubuntu:22.04 as downloader

ARG NODE_VERSION
ARG YARN_VERSION
ARG NPM_VERSION
ARG TARGETOS
ARG TARGETARCH

RUN echo "Building downloader image with node version: ${NODE_VERSION} for $TARGETOS/${TARGETARCH}"

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

# Do npm upgrade in same step as it will fail with "EXDEV: cross-device link not permitted" if it's not done in the same go:
# https://github.com/meteor/meteor/issues/7852
RUN if [ "$TARGETOS/${TARGETARCH}" = "linux/amd64" ]; then \
		echo Downloading amd64 binaies; \
		NODE_TAR_NAME="node-v$NODE_VERSION-linux-x64"; \
	elif [ "$TARGETOS/${TARGETARCH}" = "linux/arm64" ]; then \
		echo Downloading arm64 binaies; \
		NODE_TAR_NAME="node-v$NODE_VERSION-linux-arm64"; \
	else \
		echo "Unsupported target os and platform $TARGETOS/${TARGETARCH}"; \
		exit 1; \
	fi; \
	curl -sSLO --fail "https://nodejs.org/dist/v${NODE_VERSION}/${NODE_TAR_NAME}.tar.xz" \
	&& curl -sSLO --compressed --fail "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt.asc" \
		&& gpg -q --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
		&& echo "Extracting node and installing NPM version: ${NPM_VERSION}" \
		&& grep " $NODE_TAR_NAME.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
		&& tar -xJf "$NODE_TAR_NAME.tar.xz" -C /opt --no-same-owner \
		&& mv /opt/$NODE_TAR_NAME /opt/node-v$NODE_VERSION \
		&& ln -s /opt/node-v$NODE_VERSION/bin/node /usr/local/bin/node \
		&& /opt/node-v$NODE_VERSION/bin/npm install -g npm@$NPM_VERSION

# Install Yarn
RUN echo "Downloading Yarn version: $YARN_VERSION"
RUN curl -fSLO --compressed --fail "https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-v${YARN_VERSION}.tar.gz"
RUN curl -fSLO --compressed --fail "https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-v${YARN_VERSION}.tar.gz.asc"
RUN gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz
RUN tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ --no-same-owner

#
# Build a common base image for both node-base and node-builder
#
FROM ubuntu:22.04 as common

ARG NODE_VERSION
ARG YARN_VERSION
ARG TARGETOS
ARG TARGETARCH

# Make sure we run latest ubuntu and install some basic packages
RUN apt-get update -qq && \
	apt-get dist-upgrade -qq -y --no-install-recommends && \
	apt-get install -qq -y --no-install-recommends ca-certificates locales && \
	rm -rf /var/lib/apt/lists/*

# Set UTF8 locals
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "LANG=en_US.UTF-8" > /etc/locale.conf
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8'
ENV LANGUAGE='en_US:en'
ENV LC_ALL='en_US.UTF-8'

# Disable color output and be less verbose
ENV NO_COLOR=true
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Copy over node
COPY --from=downloader /opt/node-v$NODE_VERSION/ /usr/local
RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Copy over yarn
COPY --from=downloader /opt/yarn-v$YARN_VERSION /usr/local

# Disable npm color output and be less verbose
RUN npm config set color false --global

# Read NPM token from environment variable
RUN npm config set '//registry.npmjs.org/:_authToken' '${NPM_TOKEN}' --global

# npm will bail if NPM_TOKEN is not set to a value, empty is fine and original 
# docker build is broken with setting ENV so we need to wrap the npm command 
# https://github.com/docker/cli/issues/3344
COPY --chown=root:root files/opt/connectedcars/bin /opt/connectedcars/bin
ENV PATH /opt/connectedcars/bin:$PATH

# Make sure we can install mysql-server from Ubuntu 18.04 as this is the last
# version with mysql 5.7, also pin mysql-server to Ubuntu 18.04 as we have 
# some repos that install it expecting mysql 5.7
COPY --chown=root:root files/etc/apt/ /etc/apt/
RUN if [ "${TARGETOS}/${TARGETARCH}" = "linux/amd64" ]; then \
		echo Addding bionic for amd64 binaies; \
		rm -f /etc/apt/sources.list.d/bionic-ports.list; \
	elif [ "${TARGETOS}/${TARGETARCH}" = "linux/arm64" ]; then \
		echo Addding bionic Downloading arm64 binaies; \
		rm -f /etc/apt/sources.list.d/bionic.list; \
	else \
		echo "Unsupported target os and platform ${TARGETOS}/${TARGETARCH}"; \
		exit 1; \
	fi;

# Install common libs from older ubuntu versions so most binaies would work
RUN apt-get update -qq && \
	apt-get install -qq -y --no-install-recommends libssl1.1 && \
	rm -rf /var/lib/apt/lists/*

# Work arround issues for older node versions:
# https://github.com/nodejs/node/discussions/43184
# https://nodejs.org/en/blog/vulnerability/july-2022-security-releases/#dll-hijacking-on-windows-high-cve-2022-32223
RUN sed -i 's/^providers = provider_sect.*/#&/' /etc/ssl/openssl.cnf

#
# Build node-base image
#
FROM common as base

ARG NODE_VERSION

RUN echo "Building base image with node version: ${NODE_VERSION}"

# Create user for node
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node
RUN mkdir -p /app/tmp
RUN chown node:node /app/tmp

USER node

ENV NODE_ENV production
WORKDIR /app

FROM common as builder

ARG NODE_VERSION

RUN echo "Building builder image with node version: ${NODE_VERSION}"

# Install basic build tools
RUN apt-get update -qq && \
	apt-get install -qq -y --no-install-recommends build-essential python3 git openssh-client && \
	rm -rf /var/lib/apt/lists/*

# Install mysql 5.7 and 8.x dependencies and download both versions to /opt
RUN apt-get update -qq && \
	apt-get install -qq -y --no-install-recommends mysql-client-core-8.0 && \
	apt-get install -qq -y --no-install-recommends $(apt-cache depends mysql-server-core-5.7 mysql-server-core-8.0 | grep Depends | sed "s/.*ends:\ //" | tr '\n' ' ') && \
 	apt-get download mysql-server-core-5.7 mysql-server-core-8.0 && \
 	dpkg-deb -x mysql-server-core-5.7_*.deb /opt/mysql-5.7 && \
	dpkg-deb -x mysql-server-core-8.0_*.deb /opt/mysql-8.0 && \
	rm -f mysql-server-core-*.deb && \
	rm -rf /var/lib/apt/lists/*

# Set environment variables where you can find mysqld
ENV MYSQLD_57=/opt/mysql-5.7/usr/sbin/mysqld
ENV MYSQLD_80=/opt/mysql-8.0/usr/sbin/mysqld
ENV MYSQLD=${MYSQLD_80}
# Add mysql 8.0 to path so builds not using environment will still work
RUN ln -s /opt/mysql-8.0/usr/sbin/mysqld /usr/local/sbin

# Fix for npm "prepare" not running under root
RUN groupadd --gid 1000 builder \
  && useradd --uid 1000 --gid builder --no-log-init --shell /bin/bash --create-home builder

RUN mkdir -p /app/tmp
RUN chown -R builder:builder /app

# Cache ssh host key verification for github.com
RUN ssh-keyscan github.com > /etc/ssh/ssh_known_hosts

# Build fat base
FROM base as fat-base

USER root

# Install lftp and openssh and dependencies for puppeteer (chromium)
RUN apt-get update && apt-get -yq install openssh-client lftp \
	gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 \
	libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 \
	libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 \
	libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
	ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget \
	&& rm -rf /var/lib/apt/lists/*

# Add Semler external ftp to known hosts
RUN mkdir -p /home/node/.ssh
RUN ssh-keyscan -t rsa semftpext01.semler.dk > /home/node/.ssh/known_hosts
RUN chmod 644 /home/node/.ssh/known_hosts

# Enable deprecated host key algorithm for Semler's ftp server
RUN touch /home/node/.ssh/config
RUN echo "Host semftpext01.semler.dk" >> /home/node/.ssh/config
RUN echo "  HostKeyAlgorithms +ssh-rsa" >> /home/node/.ssh/config
RUN chmod 644 /home/node/.ssh/config

USER node