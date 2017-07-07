FROM centos:centos6.9
MAINTAINER Nicholas Kennedy <nkennedy@novetta.com>

WORKDIR /tmp/

# Install tools & libraries
RUN yum update -y && yum install -y wget libtool tar gcc-c++ epel-release inotify-tools && \
    yum groupinstall -y "Development Tools" && \
    yum install -y zlib-devel openssl-devel unzip perl-ExtUtils-MakeMaker curl-devel; yum -y clean all

#Install Git
WORKDIR /tmp/
RUN wget -O git.zip https://github.com/git/git/archive/master.zip && \
    unzip git.zip && \
    cd git-master && \
    make configure && \
    ./configure --prefix=/usr/local && \
    make all && \
    make install && \
    rm -rf /tmp && mkdir /tmp

# Install golang
ARG GO_VER=1.8.3
WORKDIR /tmp/
RUN wget https://storage.googleapis.com/golang/go${GO_VER}.linux-amd64.tar.gz -O go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm -rf /tmp && mkdir /tmp
ENV PATH="/usr/local/go/bin/:/root/bin:${PATH}"

# Install zeromq
ARG ZMQ_VER=4.1.6
WORKDIR /tmp/
RUN wget https://github.com/zeromq/zeromq4-1/releases/download/v${ZMQ_VER}/zeromq-${ZMQ_VER}.tar.gz -O zmq.tar.gz && \
    tar -xvf zmq.tar.gz && \
    cd zeromq* && \
    ./autogen.sh && \
    ./configure --without-libsodium && \
    make && \
    make install && \
    echo /usr/local/lib > /etc/ld.so.conf.d/local.conf && \
    ldconfig && \ 
    cp ./src/libzmq.pc /usr/lib64/pkgconfig/ && \
    rm -rf /tmp && mkdir /tmp
    
# Install python2.7 (required for cqlsh)
WORKDIR /tmp/
RUN wget https://www.python.org/ftp/python/2.7.8/Python-2.7.8.tgz && \
    tar xvfz Python-2.7.8.tgz && \
    cd Python-2.7.8 && \
    ./configure --prefix=/usr/local && \
    make && \
    make altinstall && \
    rm -rf /tmp && mkdir /tmp

# Install setuptools + pip
WORKDIR /tmp/
RUN wget --no-check-certificate https://pypi.python.org/packages/source/s/setuptools/setuptools-1.4.2.tar.gz && \
    tar -xvf setuptools-1.4.2.tar.gz && \
    cd setuptools-1.4.2 && \
    python2.7 setup.py install && \
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py && \
    python2.7 get-pip.py && \
    pip install cqlsh && \
    ln -s /usr/local/bin/python2.7 /usr/local/bin/python && \
    rm -rf /tmp && mkdir /tmp

ENV GOPATH=/root/go
RUN mkdir -p /root/go/bin && \
    mkdir -p /root/.ssh && \
    chmod 0700 /root/.ssh && \
    ssh-keyscan github.com > /root/.ssh/known_hosts && \
    ssh-keyscan gopkg.in > /root/.ssh/known_hosts && \
    git config --global url."https://".insteadOf git://

RUN go get -v github.com/Masterminds/glide && \
    go get -v github.com/tockins/realize && \
    cp /root/go/bin/realize /root/bin && \
    cp /root/go/bin/glide /root/bin && \
    rm -rf /root/go

#Remove Temp Files
WORKDIR /
RUN yum remove -y wget tar which zlib-devel openssl-devel unzip perl-ExtUtils-MakeMaker curl-devel swig subversion doxygen && \
    yum -y clean all

