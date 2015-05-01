FROM ubuntu:14.04
MAINTAINER Alex Samorukov <samm@os2.kiev.ua>
# this is cross-compilation toolkit based on GCC 5.1 for the powerpcspe devices

# update os
RUN apt-get update && apt-get upgrade -y
# install packages required to build toolchain and native gcc
RUN apt-get install -y  git  autoconf automake libtool gperf bison  \
    build-essential  flex texinfo wget gawk ncurses-dev libgmp-dev \
    libmpfr-dev libmpc-dev libc6-dev-i386
# lets add builder user and work from it
RUN useradd --home /opt/golang builder
ADD configs /opt/golang/configs/
# add turris config and build toolchain
ADD samples /opt/golang/ct-ng/samples/
ADD go-caller.patch /opt/golang/src/
RUN chown -R builder:builder /opt/golang
WORKDIR /opt/golang
# remove root password to allow su and switch to builder
RUN passwd -d root
USER builder
# grab gcc 5.1.0 source and extract it, apply patch from https://bugzilla.redhat.com/show_bug.cgi?id=1212472, 
# remove original tar then
RUN cd /opt/golang/src && wget http://gcc.cybermirror.org/releases/gcc-5.1.0/gcc-5.1.0.tar.bz2 \
    && tar -xjf gcc-5.1.0.tar.bz2 && rm gcc-5.1.0.tar.bz2
RUN cd /opt/golang/src && patch -p0 -d gcc-5.1.0  -i ../go-caller.patch
# fetch crosstool-ng from git, we will use commit known to work fine
RUN cd /opt/golang/src && git clone https://github.com/crosstool-ng/crosstool-ng \
    && cd crosstool-ng && git checkout cd47c091ba6f7d6d9a98c85fc5729a434c99d4ea
# configure and install ct-ng
RUN cd src/crosstool-ng && autoreconf -i && ./configure --prefix=/opt/golang/ct-ng && make install
# build powerpcspe go
RUN cd /opt/golang/ct-ng &&  bin/ct-ng powerpc-turris-linux-gnuspe && bin/ct-ng build && rm -rf .build
# build native go from the same source - required to build go tools for the x86_64 platform
RUN mkdir gccbuild && cd gccbuild \
    && /opt/golang/src/gcc-5.1.0/configure --enable-languages=go --prefix /opt/golang/x-tools/x86_64-linux-gnu \
    && make -j10 && make install && cd /opt/golang && rm -rf gccbuild
# add env scripts and create some links
RUN cd /opt/golang/configs/bin && \
    ln -s /opt/golang/x-tools/x86_64-linux-gnu/bin/gccgo && \
    ln -s /opt/golang/x-tools/x86_64-linux-gnu/bin/go && \
    ln -s /opt/golang/x-tools/x86_64-linux-gnu/bin/gofmt
