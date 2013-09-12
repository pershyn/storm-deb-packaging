#!/bin/bash
set -e
set -u

# build options
fakeroot=libzmq0
buildroot=build
origdir=$(pwd)
prefix="/usr"
src_package="zeromq-${version}.tar.gz"
download_url="http://download.zeromq.org/${src_package}"

# package info

version=2.1.7
url="http://www.zeromq.org/"
arch="$(dpkg --print-architecture)"
section="misc"
package_version=""
description="The 0MQ lightweight messaging kernel is a library which extends the


standard socket interfaces with features traditionally provided by
specialised messaging middleware products. 0MQ sockets provide an
abstraction of asynchronous message queues, multiple messaging
patterns, message filtering (subscriptions), seamless access to
multiple transport protocols and more.
.
This package contains the ZeroMQ shared library."


# install dependencies TODO: it should not be done here
# apt-get install -y uuid-dev

# download package
if [[ ! -f "${src_package}" ]]; then
  wget ${download_url}
fi

#_ MAIN _#
rm -rf ${name}*.deb

#_ MAKE DIRECTORIES _#
rm -rf ${fakeroot}
mkdir -p ${fakeroot}
rm -rf ${buildroot}
mkdir -p ${buildroot}
#_ DOWNLOAD & COMPILE _#
cd ${fakeroot}
wget ${package}
tar -zxvf *.gz
cd zeromq-${version}/
./configure --prefix=${prefix}
make
make install DESTDIR=${origdir}/${buildroot}

#_ MAKE DEBIAN _#
cd ${origdir}/${buildroot}
fpm -t deb \
    -n ${name} \
    -v ${version}${package_version} \
    --description "${description}" \
    --url="${url}" \
    -a ${arch} \
    --category ${section} \
    --vendor "" \
    -m "${USER}@localhost" \
    --prefix=/ \
    -d "libc6 >= 2.7" -d "libgcc1 >= 1:4.1.1" -d "libstdc++6 >= 4.1.1" -d "libuuid1 >= 2.16" \
    --after-install ${origdir}/shlib.postinst \
    --after-remove ${origdir}/shlib.postuninst \
    -s dir \
    -- .
mv *.deb ${origdir}
popd
