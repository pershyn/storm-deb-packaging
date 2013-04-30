#!/bin/bash
set -e
set -u

do_download=''
version=''
default_version=0.8.1
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      echo >&2
      echo "Usage: ${0##*/} [--download] [--version <version>]" >&2
      echo >&2
      echo "Build a Storm Debian package either from a downloaded zip package (--download)" >&2
      echo "or one available locally in ../storm." >&2
      echo >&2
      echo "Version ${default_version} is downloaded by default if not specified." >&2
      echo >&2
      exit 1
      ;;
    -v|--version)
      version=$2
      shift
      ;;
    -d|--download)
      do_download=1 ;;
    *)
      echo "Unknown option $1" >&2
      exit 1
  esac
  shift
done

name=storm
description="Storm is a distributed realtime computation system. Similar to how Hadoop provides a set of general primitives
for doing batch processing, Storm provides a set of general primitives for doing realtime computation. Storm is simple, can
be used with any programming language, is used by many companies, and is a lot of fun to use!"
url="http://storm-project.net"
arch="all"
section="misc"
package_version=""

set -x

origdir="$(pwd)"
src_dir="${origdir}/../storm"
if [ ! -d "$src_dir" ]; then
  echo "Source directory $src_dir does not exist, downloading package" >&2
  do_download=1
fi

if [ ! "$do_download" ]; then
  # Build from a zip package
  src_dir=$(cd "${src_dir}" && pwd)

  if [ -z "${version}" ]; then
    if [ -f "${src_dir}/VERSION" ]; then
      version=$(cat "${src_dir}/VERSION")
    else
      version=$(cat "${src_dir}/project.clj" | head -1 | awk '{gsub(/"/, ""); print $NF}')
    fi

    if [ -z "${version}" ]; then
      echo "Could not determine version from ${src_dir}/project_clj or ${src_dir}/VERSION" >&2
      exit 1
    fi
  fi

  src_package="${src_dir}/storm-${version}.zip"
  if [ ! -f "${src_package}" ]; then
    echo "File ${src_package} not found, cannot build from local zip package" >&2
    exit 1
  fi
else
  if [ -z "${version}" ]; then
    version=${default_version}
  fi

  src_package="${origdir}/storm-${version}.zip"
  download_url="https://github.com/downloads/nathanmarz/storm/${src_package##*/}"
  origdir="$(pwd)"
  if [ ! -f "${src_package}" ]; then
    wget ${download_url}
  fi
  if [ ! -f "${src_package}" ]; then
    echo "Failed to download package ${src_package}, still does not exist" >&2
    exit 1
  fi
fi

storm_root_dir=/usr/lib/storm

#_ MAIN _#
rm -rf ${name}*.deb
mkdir -p tmp && pushd tmp
rm -rf storm
mkdir -p storm
cd storm
mkdir -p build${storm_root_dir}
mkdir -p build/etc/default
mkdir -p build/etc/storm
mkdir -p build/etc/init
mkdir -p build/var/log/storm

unzip "${src_package}"
rm -rf storm-${version}/logs
rm -rf storm-${version}/log4j
rm -rf storm-${version}/conf
cp -R storm-${version}/* build${storm_root_dir}

cd build
cp ${origdir}/storm ${origdir}/storm-nimbus ${origdir}/storm-supervisor ${origdir}/storm-ui ${origdir}/storm-drpc etc/default
cp ${origdir}/storm.yaml etc/storm
cp ${origdir}/storm.log.properties etc/storm
cp ${origdir}/storm-nimbus.conf ${origdir}/storm-supervisor.conf ${origdir}/storm-ui.conf ${origdir}/storm-drpc.conf etc/init

#_ MAKE DEBIAN _#
fpm -t deb \
    -n ${name} \
    -v ${version} \
    --description "${description}" \
    --url="{$url}" \
    -a ${arch} \
    --category ${section} \
    --vendor "" \
    -m "${USER}@localhost" \
    --prefix=/ \
    -d "libzmq0 = 2.1.7" -d "jzmq >= 2.1.0" -d "unzip" \
    -s dir \
    -- .

mv storm*.deb ${origdir}
popd
