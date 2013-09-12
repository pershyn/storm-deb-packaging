#!/bin/bash
# downloads and builds debian package for jzmq library
# ./tmp/ folder is used as temporary build place
# ./downloads/ is used as place to store downloaded files,
# so if needed the sources could be downloaded once.

set -u
set -x

name=jzmq # read README why jzmq name is used as package name
version=2.1.0
libzmq_name=libzmq1 # read README why name ZeroMQ library libzmq1
libzmq_version=2.0.10 # read README why 2.0.10 should be used in dependencies
description="JZMQ is the Java bindings for ZeroMQ"
url="https://github.com/nathanmarz/jzmq.git"
arch="all" # read README why all is used here
section="misc"
package_version_suffix="" # use -2 to add it to package version
origdir="$(pwd)"
prefix="/usr"
downloads="${origdir}/downloads"

# download and patch the jzmq (if needed) to downloads
mkdir -p "${downloads}/jzmq" && pushd "${downloads}/jzmq"
  git clone https://github.com/nathanmarz/jzmq.git
  cd jzmq
  mkdir -p build

  # Patch for 12.x Ubuntu releases
  # TODO: Check - if you are building for debian - this patch is not needed
  if [ $(cat /etc/lsb-release|grep -i release|grep 12\.) ]; then
    curl -L -v -s https://github.com/nathanmarz/jzmq/pull/2.patch 2>/dev/null | patch -p
  fi
popd

# Make sure JAVA_HOME is set.
if [ "${JAVA_HOME}x" == "x" ]; then
  echo Please set JAVA_HOME before running.
  exit -1
fi

#_ MAIN _#
# Cleanup old debian files
rm -rf ${name}*.deb
# If temp directory exists, remove if
if [ -d tmp ]; then
  rm -rf tmp
fi
# Make build directory, save location
mkdir -p tmp && pushd tmp

# copy downloaded repo to the tmp dir
cp ${downloads}/jzmq/* tmp

# Build package
./autogen.sh
./configure --prefix=${prefix} #TODO: what is this prefix?
# old prefix  "--with-zeromq=${origdir}/tmp/${libzmq_name}/build/usr/local"

make
if [ $? != 0 ]; then
  echo "Failed to build ${name}. Please ensure all dependencies are installed"
  exit $?
fi

make install DESTDIR='pwd'/build

#_ MAKE DEBIAN _#
fpm -t deb \
    -n ${name} \
    -v ${version}${package_version_suffix} \
    --description "${description}" \
    --url="${url}" \
    -a ${arch} \
    --category ${section} \
    --vendor "" \
    -m "${USER}@localhost" \
    --prefix=/ \
    -d "${libzmq_name} >= ${libzmq_version}" \
    -s dir \
    --after-install ${origdir}/shlib.postinst \
    --after-remove ${origdir}/shlib.postrm \
    -- .

mv ${name}*.deb ${origdir}
popd
