ARG NODE_VERSION=10.0.0
ARG NPM_VERSION=6.0.0
ARG YARN_VERSION=1.6.0

FROM ubuntu:18.04 as downloader

# Import
ARG NODE_VERSION
ARG YARN_VERSION

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

# Install Yarn

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
  ; do \
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done

RUN curl -SLO "https://nodejs.org/dist/v${NODE_VERSION}/node-v$NODE_VERSION-linux-x64.tar.xz"
RUN curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc"
RUN gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc
RUN grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c -
RUN tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /opt --no-same-owner
RUN ln -s /opt/node-v$NODE_VERSION-linux-x64/bin/node /usr/local/bin/node
RUN /opt/node-v$NODE_VERSION-linux-x64/bin/npm install -g npm@$NPM_VERSION

# Install Yarn

RUN set -ex \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done
RUN curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz"
RUN curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc"
RUN gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz
RUN tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ --no-same-owner

FROM ubuntu:18.04 as base

# Import
ARG NODE_VERSION
ARG YARN_VERSION

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

# Import
ARG NODE_VERSION
ARG YARN_VERSION

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
