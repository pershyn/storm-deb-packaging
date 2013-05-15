#!/bin/bash
set -e
set -u

do_download=''
version=''
origdir="$(pwd)"
default_local_dir="${origdir}/../storm"
local_dir=''
default_version=0.8.1
packaging_version=""

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      cat >&2 <<EOT
Usage: ${0##*/} [<options>]

Build a Storm Debian package either from a downloaded zip package (--download)
or one available locally in ../storm.

Options:

  -d, --download
    Download a Storm zip package from github. This is false by default.

  -l, --local-dir <dir>
    Use the specified Storm source directory to get the Storm zip package,
    ${default_local_dir} by default

  -v, --version <version>
    Use the given version of Storm (default: ${default_version} for a download or
    the version autodetected from project.clj or a VERSION file for local build).

  -p, --packaging_version <packaging_version>
    A suffix to add to the Debian package version. E.g. Storm version could be 0.8.1
    and this could be 2, resulting in a Debian package version of 0.8.1-2.

EOT
      exit 1
      ;;
    -d|--download)
      do_download=1
      ;;
    -v|--version)
      version=$2
      if [ -z "${version}" ]; then
        echo "Invalid download version specified" >&2
        exit 1
      fi
      shift
      ;;
    -l|--local-dir)
      local_dir=$2
      if [ ! -d "${local_dir}" ]; then
        echo "Directory ${local_dir} does not exist" >&2
        exit 1
      fi
      shift
      ;;
    -p|--packaging_version)
      packaging_version=$2
      if [[ ! "${packaging_version}" =~ ^[0-9]+$ ]]; then
        echo "packaging_version must be a number" >&2
        exit 1
      fi
      shift
      ;;
    *)
      echo "Unknown option $1" >&2
      exit 1
  esac
  shift
done

if [[ -n "${local_dir}" && "${do_download}" ]]; then
  echo "--download and --local-dir are incompatible" >&2
  exit 1
fi

if [ -z "${local_dir}" ]; then
  local_dir=${default_local_dir}
fi

name=storm
description="Storm is a distributed realtime computation system. Similar to how Hadoop provides a set of general primitives
for doing batch processing, Storm provides a set of general primitives for doing realtime computation. Storm is simple, can
be used with any programming language, is used by many companies, and is a lot of fun to use!"
url="http://storm-project.net"
arch="all"
section="misc"

set -x

if [ ! "${do_download}" ]; then
  # Build from a zip package in the specified directory.
  if [ ! -d "${local_dir}" ]; then
    # Re-check directory existence. This may be either a command line option or the default.
    set +x
    echo "Directory ${local_dir} does not exist" >&2
    exit 1
  fi
  local_dir=$(cd "${local_dir}" && pwd)

  if [ -z "${version}" ]; then
    if [ -f "${local_dir}/VERSION" ]; then
      version=$(cat "${local_dir}/VERSION")
    else
      version=$(cat "${local_dir}/project.clj" | grep defproject | awk '{gsub(/"/, ""); print $NF}')
    fi

    if [ -z "${version}" ]; then
      set +x
      echo "Could not determine version from ${local_dir}/project_clj or ${local_dir}/VERSION" >&2
      exit 1
    fi
  fi

  src_package="${local_dir}/storm-${version}.zip"
  if [ ! -f "${src_package}" ]; then
    set +x
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
    set +x
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

packaging_version_suffix=""
if [ -n "${packaging_version}" ]; then
  packaging_version_suffix="-${packaging_version}"
fi

#_ MAKE DEBIAN _#
fpm -t deb \
    -n ${name} \
    -v "${version}${packaging_version_suffix}" \
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

