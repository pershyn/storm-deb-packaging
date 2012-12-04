#!/bin/bash
name=libzmq0
version=2.1.7
description="The 0MQ lightweight messaging kernel is a library which extends the
standard socket interfaces with features traditionally provided by
specialised messaging middleware products. 0MQ sockets provide an
abstraction of asynchronous message queues, multiple messaging
patterns, message filtering (subscriptions), seamless access to
multiple transport protocols and more.
.
This package contains the ZeroMQ shared library."
url="http://www.zeromq.org/"
arch="$(dpkg --print-architecture)"
section="misc"
package="zeromq-${version}.tar.gz"
download_url="http://download.zeromq.org/${package}"
origdir="$(pwd)"

#_ MAIN _#
rm -rf ${name}*.deb
if [[ ! -f "${package}" ]]; then
  wget ${download_url}
fi
mkdir -p tmp && pushd tmp
rm -rf libzmq0
tar -zxf "${origdir}/${package}"
mv zeromq-${version} libzmq0
cd libzmq0
mkdir build
./configure
make
make install DESTDIR=`pwd`/build

#_ MAKE DEBIAN _#
cd build
fpm -t deb \
    -n ${name} \
    -v ${version} \
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
mv libzmq0*.deb ${origdir}
popd
