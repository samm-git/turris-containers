FROM gocross:latest
MAINTAINER Alex Samorukov <samm@os2.kiev.ua>
USER root
# Get lvm2 source for compiling statically
RUN git clone -b v2_02_103 https://git.fedorahosted.org/git/lvm2.git /usr/local/lvm2
# set crosscompilation flags
ENV PATH=/go/bin:/opt/golang/x-tools/powerpc-turris-linux-gnuspe/bin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    CC=powerpc-turris-linux-gnuspe-gcc CXX=powerpc-turris-linux-gnuspe-g++
# install lvm2/ppc
RUN cd /usr/local/lvm2 && \
    ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes ./configure \
    --prefix=/opt/golang/x-tools/powerpc-turris-linux-gnuspe/powerpc-turris-linux-gnuspe/sysroot/ \
    --host=powerpc-turris-linux-gnuspe --enable-static_link && \
     make device-mapper && make install_device-mapper
# install sqlite/ppc
RUN cd /root && wget http://www.sqlite.org/2015/sqlite-autoconf-3080900.tar.gz && \
    tar -xzf sqlite-autoconf-3080900.tar.gz && cd sqlite-autoconf-3080900 && \
    ./configure --prefix=/opt/golang/x-tools/powerpc-turris-linux-gnuspe/powerpc-turris-linux-gnuspe/sysroot/ \
    --host=powerpc-turris-linux-gnuspe && make install
# docker configuration, to enable btrfs backend we should cross-comoile btrfs-tools, so let disable it for now
# aufs is n/a on the target device
ENV DOCKER_BUILDTAGS="exclude_graphdriver_btrfs  exclude_graphdriver_aufs"
# configure go cross compilation
ENV GOARCH=ppc \
    GCCGO=/opt/golang/x-tools/powerpc-turris-linux-gnuspe/bin/powerpc-turris-linux-gnuspe-gccgo \
    GOPATH=/go:/go/src/github.com/docker/docker/vendor \
    GOROOT=/opt/golang/x-tools/powerpc-turris-linux-gnuspe/powerpc-turris-linux-gnuspe/sysroot/lib/go/5.1.0/powerpc-turris-linux-gnuspe \
    LD_LIBRARY_PATH=/opt/golang/x-tools/x86_64-linux-gnu/lib64 \
    CGO_ENABLED=1 CGO_CFLAGS=-I/opt/golang/x-tools/powerpc-turris-linux-gnuspe/powerpc-turris-linux-gnuspe/sysroot/include/
# set some go softlinkgs
RUN mkdir -p /go/bin && cd /go/bin && ln -s /opt/golang/x-tools/x86_64-linux-gnu/bin/gccgo \
    && ln -s /opt/golang/x-tools/x86_64-linux-gnu/bin/go \
    && ln -s /opt/golang/x-tools/x86_64-linux-gnu/bin/gofmt
# get docker/release, trunk seems to be broken
ENV DOCKER_VERSION=1.6.1
RUN git clone -b v${DOCKER_VERSION} https://github.com/docker/docker /go/src/github.com/docker/docker
# add  PPC/gccgo patches
ADD patches/*diff /go/src/patches/
# patch docker
RUN cd /go/src/github.com/docker/docker && cat /go/src/patches/*.diff | patch -p1
# finally - compile docker
RUN cd /go/src/github.com/docker/docker && hack/make.sh gccgo
# install opkg tools
RUN cd /root/ && git clone http://git.yoctoproject.org/git/opkg-utils && cd opkg-utils && make CC=gcc && make install
# create docker ipk
ADD docker-opkg /root/docker-opkg
RUN cd /root/ && cp /go/src/github.com/docker/docker/bundles/${DOCKER_VERSION}/gccgo/docker-${DOCKER_VERSION} docker-opkg/opt/docker/bin/docker && \
  cp /go/src/github.com/docker/docker/contrib/check-config.sh docker-opkg/opt/docker/bin/docker-check-config.sh && \
  sed -i "s|@size|`du docker-opkg/ -b -s|awk '{print $1}'`|" docker-opkg/CONTROL/control && \
  sed -i "s|@docker_version|$DOCKER_VERSION|" docker-opkg/CONTROL/control && \
  opkg-build docker-opkg

