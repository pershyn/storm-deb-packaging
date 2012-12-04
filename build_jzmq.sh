#!/bin/bash
name=jzmq
arch="$(dpkg --print-architecture)"
version=2.1.0-1
buildroot=build
fakeroot=jzmq
origdir="$(pwd)"
description='JZMQ is the Java bindings for ZeroMQ'
export JAVA_HOME="$(readlink -f /usr/bin/javac | sed 's:/bin/javac::')"

#_ MAIN _#
rm -rf ${name}*.deb
mkdir -p tmp && pushd tmp
rm -rf jzmq
git clone https://github.com/nathanmarz/jzmq.git
cd jzmq
wget -O - https://github.com/nathanmarz/jzmq/pull/2.patch | patch -p1
./autogen.sh
./configure
dpkg-buildpackage -rfakeroot
mv "${name}_*.*" ${origdir}
popd
