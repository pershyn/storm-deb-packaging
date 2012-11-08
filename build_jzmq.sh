#!/bin/bash
name=libjzmq
arch='amd64' # Change to your architecture
version=2.1.7
url='https://github.com/nathanmarz/jzmq.git'
buildroot=build
fakeroot=jzmq
origdir=$(pwd)
prefix="/usr"
description='JZMQ is the Java bindings for ZeroMQ'
# Make sure JAVA_HOME is set. Uncomment if necessary
test -z "${JAVA_HOME}" && export JAVA_HOME='/usr/lib/jvm/j2sdk1.6-oracle'

#_ MAIN _#
rm -rf ${name}*.deb
rm -rf jzmq
rm -rf ${buildroot}
mkdir -p ${buildroot}
git clone ${url}
cd jzmq
./autogen.sh
./configure --prefix=${prefix}
# Something in the Makefile doesn't work right with
# Ubuntu Precise.  See:
# https://github.com/zeromq/jzmq/issues/114#issuecomment-6927797
touch src/classdist_noinst.stamp
cd src/
CLASSPATH=.:./.:$CLASSPATH
javac -d . org/zeromq/ZMQ.java org/zeromq/App.java org/zeromq/ZMQForwarder.java org/zeromq/EmbeddedLibraryTools.java org/zeromq/ZMQQueue.java org/zeromq/ZMQStreamer.java org/zeromq/ZMQException.java
cd ..
make
make install DESTDIR=${origdir}/${buildroot}

#_ MAKE DEBIAN _#
cd ${origdir}/${buildroot}
fpm -t deb -n ${name} -v ${version} --description "${description}" --url="${url}" -a ${arch} --prefix=/ -d "oracle-j2sdk1.6" -d "libzmq0 >= 2.1.7" -s dir -- .
mv ${origdir}/${buildroot}/*.deb ${origdir}
