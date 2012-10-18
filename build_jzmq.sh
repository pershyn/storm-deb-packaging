#!/bin/bash
name=libjzmq
arch='amd64' # Change to your architecture
version=2.1.7
url='https://github.com/nathanmarz/jzmq.git'
buildroot=build
fakeroot=jzmq
origdir=$(pwd)
description='JZMQ is the Java bindings for ZeroMQ'
# Make sure JAVA_HOME is set. Uncomment if necessary
if [ "${JAVA_HOME}x" == "x" ]; then
  echo Please set JAVA_HOME before running.
  exit -1
fi

#_ MAIN _#
rm -rf ${name}*.deb
rm -rf jzmq
rm -rf ${buildroot}
mkdir -p ${buildroot}
git clone ${url}
cd jzmq
./autogen.sh
./configure

cd src/
touch classdist_noinst.stamp
CLASSPATH=.:./.:$CLASSPATH javac -d . org/zeromq/ZMQ.java org/zeromq/App.java org/zeromq/ZMQForwarder.java org/zeromq/EmbeddedLibraryTools.java org/zeromq/ZMQQueue.java org/zeromq/ZMQStreamer.java org/zeromq/ZMQException.java
cd ..

make
make install DESTDIR=${origdir}/${buildroot}

#_ MAKE DEBIAN _#
cd ${origdir}/${buildroot}
fpm -t deb -n ${name} -v ${version} --description "${description}" --url="${url}" -a ${arch} --prefix=/ -d "libzmq0 >= 2.1.7" -s dir -- .
mv ${origdir}/${buildroot}/*.deb ${origdir}
