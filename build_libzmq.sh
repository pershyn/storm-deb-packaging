#!/bin/bash
# downloads and builds debian package for libzmq library
# ./tmp/ folder is used as temporary build place
# ./downloads/ is used as place to store downloaded files,
# so if needed the sources could be downloaded once.

set -x

# package info
name=libzmq1 # read README why name ZeroMQ library libzmq1
version=2.1.7 # read README why at least 2.1.7 should be used in dependencies
url="http://www.zeromq.org/"
arch=$(dpkg --print-architecture)
section="misc"
description="The 0MQ lightweight messaging kernel is a library which extends the
    standard socket interfaces with features traditionally provided by
    specialised messaging middleware products. 0MQ sockets provide an
    abstraction of asynchronous message queues, multiple messaging
    patterns, message filtering (subscriptions), seamless access to
    multiple transport protocols and more.
    .
    This package contains the ZeroMQ shared library."

# build options
origdir=$(pwd)
downloads="${origdir}/downloads"
prefix="/usr"
src_package="zeromq-${version}.tar.gz"
download_url="http://download.zeromq.org/${src_package}"


#_ PROCESS CMD ARGUMENTS _#
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      cat >&2 <<EOT
Usage: ${0##*/} [<options>]

Build a libzmq Debian package.
If a libzmq folder is present - does not redownload the file.

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


mkdir -p ${downloads} && pushd ${downloads}
  # download package (if not exists in folder)
  if [[ ! -f "${downloads}/${src_package}" ]]; then
    curl -L -s -o ${downloads}/${src_package} ${download_url}
  fi
popd

#_ MAIN _#
rm -rf ${name}*.deb
# If temp directory exists, remove if
if [ -d tmp ]; then
  rm -rf tmp
fi
# Make build directory, save location
mkdir -p tmp && pushd tmp
#_ Unpack and compile _#
tar -zxf ${downloads}/${src_package}
cd zeromq-${version}/
./configure --prefix=${prefix}

make
if [ $? != 0 ]; then
  echo "Failed to build ${name}. Please ensure all dependencies are installed."
  exit $?
fi
make install DESTDIR=`pwd`/build

#_ MAKE DEBIAN _#
cd build
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
    -d 'libc6 >= 2.7'  -d 'libgcc1 >= 1:4.1.1'  -d 'libstdc++6 >= 4.1.1'  -d 'libuuid1 >= 2.16' \
    --after-install ${origdir}/shlib.postinst \
    --after-remove ${origdir}/shlib.postrm \
    -s dir \
    -- .

mv ${name}*.deb ${origdir}
popd
