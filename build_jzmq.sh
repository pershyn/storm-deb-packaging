#!/bin/bash
set -e
set -u

name=jzmq # jzmq left because this is how it is mentioned in official tested version for storm,
# it probably can be changed to libjzmq later
version=2.1.0-1
libzmq_name=libzmq1 # to be compatible with libzmq1 in debian repos
libzmq_version=2.1.7
description="JZMQ is the Java bindings for ZeroMQ"
url="https://github.com/nathanmarz/jzmq.git"
arch="$(dpkg --print-architecture)"
section="misc"
package_version=""
origdir="$(pwd)"

# TODO: checkout the JAVA_HOME autoset.
#if [ "${JAVA_HOME}x" == "x" ]; then
#  echo Please set JAVA_HOME before running.
#  exit -1
#fi
# 
export JAVA_HOME="$(readlink -f /usr/bin/javac | sed 's:/bin/javac::')"
buildroot=build

#_ MAIN _#
rm -rf ${name}*.deb
mkdir -p tmp && pushd tmp
rm -rf jzmq
rm -rf ${buildroot}

mkdir -p ${buildroot}
git clone ${url}
cd jzmq

wget -O - ${url}/2.patch | patch -p1 # apply patch TODO: checkout the patch and comment.
./autogen.sh
./configure --with-zeromq=${origdir}/tmp/${libzmq_name}/build/usr/local

# TODO: What is that?
#cd src/
#touch classdist_noinst.stamp
#CLASSPATH=.:./.:$CLASSPATH javac -d . org/zeromq/ZMQ.java org/zeromq/App.java org/zeromq/ZMQForwarder.java org/zeromq/EmbeddedLibraryTools.java org/zeromq/ZMQQueue.java org/zeromq/ZMQStreamer.java org/zeromq/ZMQException.java
#cd ..

make
mkdir build
make install DESTDIR=${origdir}/${buildroot}

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
mv ${origdir}/${buildroot}/*.deb ${origdir}
popd
