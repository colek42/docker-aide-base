FROM centos:centos6.8
MAINTAINER Nicholas Kennedy <nkennedy@novetta.com>

WORKDIR /tmp/

# Install tools & libraries
RUN yum install wget npm libtool tar gcc-c++ which unzip -y

# Install golang
ARG GO_VER=1.7.4
RUN wget http://storage.googleapis.com/golang/go${GO_VER}.linux-amd64.tar.gz -O go.tar.gz
RUN tar -C /usr/local -xzf go.tar.gz && rm go.tar.gz
ENV PATH="/usr/local/go/bin/:${PATH}"

# Install zeromq
ARG ZMQ_VER=4.1.3
WORKDIR /opt/
RUN wget https://github.com/zeromq/zeromq4-1/releases/download/v${ZMQ_VER}/zeromq-${ZMQ_VER}.tar.gz -O zmq.tar.gz 
RUN tar -xvf zmq.tar.gz && cd zeromq* && ./autogen.sh && ./configure --without-libsodium && make && make install && echo /usr/local/lib > /etc/ld.so.conf.d/local.conf \
  ldconfig && cp ./src/libzmq.pc /usr/lib64/pkgconfig/ && rm /opt/zmq.tar.gz

# build parameters
ARG JAVA_DISTRIBUTION=jdk
ARG JAVA_MAJOR_VERSION=8
ARG JAVA_UPDATE_VERSION=77
ARG JAVA_BUILD_NUMBER=03

ENV JAVA_VERSION=1.${JAVA_MAJOR_VERSION}.0_${JAVA_UPDATE_VERSION}
ENV JAVA_HOME=/opt/java/${JAVA_DISTRIBUTION}${JAVA_VERSION}
ENV PATH=$PATH:$JAVA_HOME/bin

# install java (required by sencha cmd)
RUN export JAVA_TARBALL=${JAVA_DISTRIBUTION}-${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-linux-x64.tar.gz && \
    wget --directory-prefix=/tmp \
         --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
         http://download.oracle.com/otn-pub/java/jdk/${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-b${JAVA_BUILD_NUMBER}/${JAVA_TARBALL} && \
    mkdir -p /opt/java && \
    tar -xzf /tmp/${JAVA_TARBALL} -C /opt/java/ && \
    if  [ "${JAVA_DISTRIBUTION}" = "server-jre" ]; \
      then mv /opt/java/jdk${JAVA_VERSION} ${JAVA_HOME} ; \
    fi && \
    alternatives --install /usr/bin/java java ${JAVA_HOME}/bin/java 100 && \
    yum clean all && rm -rf /var/cache/yum/* && \
    rm -rf /tmp/* && rm -rf /var/log/*

#Sencha CMD https://hub.docker.com/r/israelroldan/docker-sencha-cmd/ (Guy works at sencha)
ARG CMD_VER=6.2.1
RUN wget http://cdn.sencha.com/cmd/${CMD_VER}/no-jre/SenchaCmd-${CMD_VER}-linux-amd64.sh.zip -O senchacmd.zip && unzip senchacmd.zip && rm senchacmd.zip 
RUN chmod +x SenchaCmd-${CMD_VER}*-linux-amd64.sh
RUN ./SenchaCmd-${CMD_VER}*-linux-amd64.sh -q -dir /opt/Sencha/Cmd/${CMD_VER} -Dall=true
RUN rm SenchaCmd-${CMD_VER}*-linux-amd64.sh && chmod +x /opt/Sencha/Cmd/${CMD_VER}/sencha

# Install python2.7 (required for cqlsh)
WORKDIR /tmp/
RUN wget https://www.python.org/ftp/python/2.7.8/Python-2.7.8.tgz
RUN yum install -y zlib-devel openssl-devel
RUN tar xvfz Python-2.7.8.tgz && \
    cd Python-2.7.8 && \
    ./configure --prefix=/usr/local && \
    make && \
    make altinstall

# Install setuptools + pip
RUN cd /tmp && \
    wget --no-check-certificate https://pypi.python.org/packages/source/s/setuptools/setuptools-1.4.2.tar.gz
RUN tar -xvf setuptools-1.4.2.tar.gz && \
    cd setuptools-1.4.2 && \
    python2.7 setup.py install && \
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py && \
    python2.7 get-pip.py
RUN pip install cqlsh
RUN ln -s /usr/local/bin/python2.7 /usr/local/bin/python

# Install File Watcher
RUN wget https://raw.githubusercontent.com/SeanThomasWilliams/dotfiles/master/bin/watchcmd
RUN mv watchcmd /usr/local/bin/watchcmd && chmod +x /usr/local/bin/watchcmd
#Move this to top when I have more bandwidth
RUN yum install -y epel-release && yum update -y && yum install -y inotify-tools

#Remove Temp Files
WORKDIR /
RUN rm -rf /tmp && mkdir /tmp

