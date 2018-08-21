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

FROM ubuntu:18.04 as base

# Import
ARG NODE_VERSION
ARG YARN_VERSION

# Disable color output 
ENV NO_COLOR=true

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates

# Copy over node
COPY --from=builder /opt/node-v10.9.0-linux-x64/ /usr/local
RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Add stable for a newer lftp version
RUN echo 'deb http://deb.debian.org/debian sid main' >> /etc/apt/sources.list

# Install gpg2
RUN apt-get install gnupg2 -y

COPY sidpgp.key /tmp

RUN ls -la /tmp

# Add gpg key for sid
RUN cat /tmp/sidpgp.key | apt-key add -

# Install lftp and openssh and dependencies for puppeteer (chromium)
RUN apt-get update && apt-get -yq install openssh-client lftp/sid \
gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 \
libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 \
libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 \
libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget \
&& rm -rf /var/lib/apt/lists/*

# Add Semler external ftp to known hosts
RUN mkdir -p /home/node/.ssh
RUN ssh-keyscan -t rsa 195.249.218.231 > /home/node/.ssh/known_hosts
RUN chmod 644 /home/node/.ssh/known_hosts

# Create user for node
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node
RUN chown -R node:node /home/node

RUN mkdir -p /app/tmp
RUN chown node:node /app/tmp

USER node

ENV NODE_ENV production
WORKDIR /app

# Disable color output
RUN npm config set color false