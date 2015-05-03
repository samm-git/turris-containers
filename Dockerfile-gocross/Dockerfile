FROM ubuntu:14.04
MAINTAINER Alex Samorukov <samm@os2.kiev.ua>
# this is cross-compilation toolkit based on GCC 5.1 for the powerpcspe devices

# update os
RUN apt-get update && apt-get upgrade -y
# install packages required to build toolchain and native gcc
RUN apt-get install -y  git  autoconf automake libtool gperf bison  \
    build-essential  flex texinfo wget gawk ncurses-dev libgmp-dev \
    libmpfr-dev libmpc-dev
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
# switch user and set home
USER builder
# grab gcc 5.1.0 source and extract it, apply patch from https://bugzilla.redhat.com/show_bug.cgi?id=1212472, 
# remove original tar then
ENV GCC_VERSION=5.1.0
RUN cd /opt/golang/src && wget http://gcc.cybermirror.org/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2 \
    && tar -xjf gcc-${GCC_VERSION}.tar.bz2 && rm gcc-${GCC_VERSION}.tar.bz2
RUN cd /opt/golang/src && patch -p0 -d gcc-${GCC_VERSION}  -i ../go-caller.patch
# fetch crosstool-ng from git, we will use commit known to work fine
ENV CT_NG_COMMIT=cd47c091ba6f7d6d9a98c85fc5729a434c99d4ea
RUN cd /opt/golang/src && git clone https://github.com/crosstool-ng/crosstool-ng \
    && cd crosstool-ng && git checkout $CT_NG_COMMIT
# configure and install ct-ng
RUN cd src/crosstool-ng && autoreconf -i && ./configure --prefix=/opt/golang/ct-ng && make install
# build powerpcspe go
RUN cd /opt/golang/ct-ng && bin/ct-ng powerpc-turris-linux-gnuspe && bin/ct-ng build && rm -rf .build
# build native go from the same source - required to build go tools for the x86_64 platform
RUN mkdir gccbuild && cd gccbuild \
    && /opt/golang/src/gcc-${GCC_VERSION}/configure --disable-multilib \
	--enable-languages=go --prefix /opt/golang/x-tools/x86_64-linux-gnu \
    && make -j `nproc` && make install && cd /opt/golang && rm -rf gccbuild
# add env scripts and create some links
RUN mkdir /opt/golang/configs/bin && cd /opt/golang/configs/bin && \
    ln -s /opt/golang/x-tools/x86_64-linux-gnu/bin/gccgo && \
    ln -s /opt/golang/x-tools/x86_64-linux-gnu/bin/go && \
    ln -s /opt/golang/x-tools/x86_64-linux-gnu/bin/gofmt

