#!/bin/bash
# downloads and builds debian package for jzmq library
# ./tmp/ folder is used as temporary build place
# ./downloads/ is used as place to store downloaded files,
# so if needed the sources could be downloaded once.

set -x

name=jzmq # read README why jzmq name is used as package name
version=2.1.0
libzmq_name=libzmq1 # read README why name ZeroMQ library libzmq1
libzmq_version=2.0.10 # read README why 2.0.10 should be used in dependencies
libzmq_unpacked_root_path=zeromq-2.1.7 # this is where configure should find zmq.h
description="JZMQ is the Java bindings for ZeroMQ"
url="https://github.com/nathanmarz/jzmq.git"
arch="all" # read README why all is used here
section="misc"
origdir="$(pwd)"
downloads="${origdir}/downloads"
maintaner="${USER}@localhost"


#_ PROCESS CMD ARGUMENTS _#
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      cat >&2 <<EOT
Usage: ${0##*/} [<options>]

Build a jzmq Debian package.
If a jzmq is present - does not redownload the file.

Options:

  -p, --packaging_version <packaging_version>
    A suffix to add to the Debian package version. E.g. package version could be 2.0.1
    and this could be 2, resulting in a Debian package version of 2.0.1-2.

  -m, --maintainer <maintainer_email>
    Use maintainer email to include the data into package,
    if not provided - will be generated automatically from user name.

EOT
      exit 1
      ;;
     -p|--packaging_version)
       packaging_version=$2
       shift
       ;;
     -m|--maintainer)
       maintainer=$2
       #if [[  ]]; then # TODO: add a check here for email
       shift
       ;;
     *)
       echo "Unknown option $1" >&2
       exit 1
  esac
  shift
done

package_version_suffix="-${packaging_version}"

# download and patch the jzmq (if needed) to downloads
mkdir -p ${downloads} && pushd ${downloads}

 # do not clone if folder exists
 if [[ ! -d "${downloads}/${name}" ]]; then
  git clone https://github.com/nathanmarz/jzmq.git

  # Patch for being able to build the jzmq under Ubuntu 12.x releases
  if [ $(cat /etc/lsb-release|grep -i release|grep 12\.) ]; then
    cd jzmq
    wget -O - https://github.com/nathanmarz/jzmq/pull/2.patch | patch -p1
    #curl -L -v -s https://github.com/nathanmarz/jzmq/pull/2.patch 2>/dev/null | patch -p
  fi
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
# If temp directory exists, remove it
if [ -d tmp/jzmq ]; then
  rm -rf tmp/jzmq
fi
# Make build directory, save location
mkdir -p tmp/jzmq && pushd tmp/jzmq

# copy downloaded repo to the tmp dir
cp -r ${downloads}/${name}/* .

# Build package, link to bounded libzmq installation in tmp
./autogen.sh
./configure --with-zeromq=${origdir}/tmp/${libzmq_unpacked_root_path}/build/usr/include

make
if [ $? != 0 ]; then
  echo "Failed to build ${name}. Please ensure all dependencies are installed"
  exit $?
fi

mkdir build
make install DESTDIR=`pwd`/build

#_ MAKE DEBIAN _#
pushd build
fpm -t deb \
    -n ${name} \
    -v ${version}${package_version_suffix} \
    --description "${description}" \
    --url="${url}" \
    -a ${arch} \
    --deb-user "root" \
    --deb-group "root" \
    --category ${section} \
    --vendor "" \
    -m "${maintainer}" \
    --prefix=/ \
    -d "${libzmq_name} >= ${libzmq_version}" \
    -s dir \
    --after-install ${origdir}/shlib.postinst \
    --after-remove ${origdir}/shlib.postrm \
    -- .

mv ${name}*.deb ${origdir}
popd
popd
