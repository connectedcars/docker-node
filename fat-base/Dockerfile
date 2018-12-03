ARG NODE_VERSION=10.x
ARG BRANCH_NAME=master

FROM gcr.io/connectedcars-staging/node-base.${BRANCH_NAME}:$NODE_VERSION

USER root

COPY sidpgp.key /app

# Add stable for a newer lftp version
RUN echo 'deb http://deb.debian.org/debian sid main' >> /etc/apt/sources.list

# Install gpg2
RUN apt-get update && apt-get install gnupg2 -y && rm -rf /var/lib/apt/lists/*

# Add gpg key for sid
RUN cat /app/sidpgp.key | apt-key add -

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

USER node
