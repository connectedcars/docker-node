ARG NODE_VERSION=22.0.0

FROM common

ARG NODE_VERSION

RUN echo "Building builder image with node version: ${NODE_VERSION}"

# make sure we can install mysql from official apt repository
COPY --chown=root:root files/etc/apt/sources.list.d/mysql.sources /etc/apt/sources.list.d/

# Install basic build tools
RUN apt-get update -qq && \
  apt-get install -qq -y --no-install-recommends build-essential python3 git openssh-client mysql-community-client-core && \
  apt-get install -qq -y --no-install-recommends $(apt-cache depends mysql-community-server-core=8.4* mysql-community-server-core=8.0* | grep Depends | sed "s/.*ends:\ //" | tr '\n' ' ') && \
  apt-get download mysql-community-server-core=8.4* mysql-community-server-core=8.0* && \
  dpkg-deb -x mysql-community-server-core_8.0*.deb /opt/mysql-8.0 && \
  dpkg-deb -x mysql-community-server-core_8.4*.deb /opt/mysql-8.4 && \
  rm -f mysql-community-server-core_*.deb && \
  apt-get -y autoclean && \
  apt-get -y clean && \
  rm -rf /var/lib/apt/lists/*

## Set environment variables where you can find mysqld
ENV MYSQLD_84=/opt/mysql-8.4/usr/sbin/mysqld
ENV MYSQLD_80=/opt/mysql-8.0/usr/sbin/mysqld
ENV MYSQLD=${MYSQLD_80}
## Add mysql 8.0 to path so builds not using environment will still work
RUN ln -s /opt/mysql-8.0/usr/sbin/mysqld /usr/local/sbin

# Fix for npm "prepare" not running under root
RUN groupadd --gid 1001 builder \
  && useradd --uid 1001 --gid builder --no-log-init --shell /bin/bash --create-home builder

RUN mkdir -p /app/tmp
RUN chown -R builder:builder /app

# Cache ssh host key verification for github.com
RUN ssh-keyscan github.com > /etc/ssh/ssh_known_hosts

#COPY --from=downloader mysql-apt-config_0.8.34-1_all.deb .
#RUN wget https://dev.mysql.com/get/mysql-apt-config_0.8.34-1_all.deb

#RUN dpkg -i mysql-apt-config_0.8.34-1_all.deb


#
#RUN exit
#
## Install mysql 8.0 and 8.4 dependencies and download both versions to /opt
#RUN apt-get update -qq && \
#	apt-get install -qq -y --no-install-recommends mysql-client-core-8.0 && \
#	apt-get install -qq -y --no-install-recommends $(apt-cache depends mysql-server-core-8.4 mysql-server-core-8.0 | grep Depends | sed "s/.*ends:\ //" | tr '\n' ' ') && \
# 	apt-get download mysql-server-core-5.7 mysql-server-core-8.0 && \
# 	dpkg-deb -x mysql-server-core-5.7_*.deb /opt/mysql-5.7 && \
#	dpkg-deb -x mysql-server-core-8.0_*.deb /opt/mysql-8.0 && \
#	rm -f mysql-server-core-*.deb && \
#	rm -rf /var/lib/apt/lists/*
#
## Set environment variables where you can find mysqld
#ENV MYSQLD_84=/opt/mysql-8.4/usr/sbin/mysqld
#ENV MYSQLD_80=/opt/mysql-8.0/usr/sbin/mysqld
#ENV MYSQLD=${MYSQLD_80}
## Add mysql 8.0 to path so builds not using environment will still work
#RUN ln -s /opt/mysql-8.0/usr/sbin/mysqld /usr/local/sbin
#
## Fix for npm "prepare" not running under root
#RUN groupadd --gid 1000 builder \
#  && useradd --uid 1000 --gid builder --no-log-init --shell /bin/bash --create-home builder
#
#RUN mkdir -p /app/tmp
#RUN chown -R builder:builder /app
#
## Cache ssh host key verification for github.com
#RUN ssh-keyscan github.com > /etc/ssh/ssh_known_hosts