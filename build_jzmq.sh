#!/bin/bash
set -e
set -u
name=jzmq # jzmq left because this is how it is mentioned in official tested version for storm,
# it probably can be changed to libjzmq later
version=2.1.0-1
libzmq_name=libzmq1 # to be compatible with
libzmq_version=2.1.7
description="JZMQ is the Java bindings for ZeroMQ"
url="https://github.com/nathanmarz/jzmq"
arch="$(dpkg --print-architecture)"
section="misc"
package_version=""
origdir="$(pwd)"
export JAVA_HOME="$(readlink -f /usr/bin/javac | sed 's:/bin/javac::')"

#_ MAIN _#
rm -rf ${name}*.deb
mkdir -p tmp && pushd tmp
rm -rf jzmq*
git clone https://github.com/nathanmarz/jzmq.git
cd jzmq
wget -O - https://github.com/nathanmarz/jzmq/pull/2.patch | patch -p1
./autogen.sh
./configure --with-zeromq=${origdir}/tmp/${libzmq_name}/build/usr/local
make
mkdir build
make install DESTDIR=`pwd`/build

cd build
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
    -d "${libzmq_name} >= ${libzmq_version}" \
    --after-install ${origdir}/shlib.postinst \
    --after-remove ${origdir}/shlib.postuninst \
    -s dir \
    -- .
mv ${name}*.deb ${origdir}
popd
