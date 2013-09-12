#!/bin/bash
set -u
set -x

# build options and vars:
do_download=''
origdir="$(pwd)"
default_local_dir="${origdir}/../storm"
local_dir=''
dist="ubuntu" #use old debian init.d scripts or ubuntu upstart
src_package="storm-${version}.zip"
download_url="https://github.com/downloads/nathanmarz/storm/${src_package}"
storm_home=/usr/lib/storm
libzmq_name=libzmq1 # read README why name ZeroMQ library libzmq1
libzmq_version=2.0.10 # read README why 2.0.10 should be used in dependencies
jzmq_name=jzmq # read README why jzmq name is used as package name
jzmq_version=2.1.0

# package info:
version=""
packaging_version=""
default_version=0.8.1
maintainer=""
name=storm
description="Storm is a distributed realtime computation system. Similar to how Hadoop provides a set of general primitives
for doing batch processing, Storm provides a set of general primitives for doing realtime computation. Storm is simple, can
be used with any programming language, is used by many companies, and is a lot of fun to use!"
url="http://storm-project.net"
arch="all"
section="mics"
prefix="/usr/lib"

#_ PROCESS CMD ARGUMENTS _#
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

  -m, --maintainer <maintainer_email>
    Use maintainer email to include the data into package, 
    if not provided - will be generated automatically from user name.
  
  --upstart 
    builds package for ubuntu upstart, by default builds for debian init.d

EOT # TODO: Change defaults to ubuntu...?
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
    -m|--maintainer)
      maintainer=%2
      #if [[  ]]; then # TODO: add a check here for email
      shift
      ;;
    --upstart)
      dist="ubuntu" # by default builds for debian TODO: Change?
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

# if maintainer parameter is not set - use default value 
if [[ -z "${maintainer}" ]]; then
  ${maintainer}="${USER}@localhost"
fi

# set packaging version suffix if provided
packaging_version_suffix=""
if [ -n "${packaging_version}" ]; then
  packaging_version_suffix="-${packaging_version}"
fi

#_ MAIN _#
# Cleanup old debian files
rm -rf ${name}*.deb
# If temp directory exists, remove it
if [ -d tmp ]; then
  rm -rf tmp
fi

# Make build directory, save location
mkdir -p tmp && pushd tmp
# Create build structure for package
mkdir -p storm
cd storm
mkdir -p build${storm_home}
mkdir -p build/etc/default
mkdir -p build/etc/storm
#mkdir -p build/etc/init # see below
#mkdir -p build/etc/init.d
mkdir -p build/var/log/storm

## Optionally instaed of creating 2 folders, create only desired
if [ $dist == "debian" ]; then
  mkdir -p build/etc/init.d
else # ubuntu, etc - upstart based
  mkdir -p build/etc/init
fi

# Explode downloaded archive & cleanup files
unzip ${downloads}/storm-${version}.zip
rm -rf storm-${version}/logs
rm -rf storm-${version}/log4j
rm -rf storm-${version}/conf
cp -R storm-${version}/* build${storm_home}

# Substitue default files provided with storm sources
cd build
cp ${origdir}/storm ${origdir}/storm-nimbus ${origdir}/storm-supervisor ${origdir}/storm-ui ${origdir}/storm-drpc etc/default
cp ${origdir}/storm.yaml etc/storm
cp ${origdir}/storm.log.properties etc/storm

# TODO: this copies files for ubuntu... Copy init scripts for Debian?
cp ${origdir}/storm-nimbus.conf ${origdir}/storm-supervisor.conf ${origdir}/storm-ui.conf ${origdir}/storm-drpc.conf etc/init
#_ TODO: Check symlinks for upstart init scripts 
#for f in ${buildroot}/etc/init/*; do f=$(basename $f); f=${f%.conf}; ln -s /lib/init/upstart-job ${buildroot}/etc/init.d/$f; done

#_ MAKE DEBIAN _#
# versions of libzmq and jzmq are from official storm installation guide.
# TODO: Check def-user, deb-roup
fpm -t deb \
    -n ${name} \
    -v "${version}${packaging_version_suffix}" \
    --description "${description}" \
    --category ${section} \
    --url="{$url}" \
    --vendor "" \
    --deb-user "root" \
    --deb-group "root" \
    -m ${maintainer} \
    --before-install ${origdir}/storm.preinst \
    --after-install ${origdir}/storm.postinst \
    --after-remove ${origdir}/storm.postrm \
    -a ${arch} \
    --prefix=/ \
    -d "${libzmq_name} >= ${libzmq_version}" -d "${jzmq_name} >= ${jzmq_version}" -d "unzip" \
    -s dir \
    -- .

mv ${name}*.deb ${origdir}
popd
