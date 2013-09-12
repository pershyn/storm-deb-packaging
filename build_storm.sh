#!/bin/bash
set -e
set -u

# build options and vars:
do_download=''
origdir="$(pwd)"
default_local_dir="${origdir}/../storm"
local_dir=''
dist="ubuntu" #use old debian init.d scripts or ubuntu upstart

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
# Process command line
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
    -m|--maintainer)
      maintainer=%2
      #if [[  ]]; then # TODO: add a check here for email
      shift
      ;;
    --upstart)
      dist="ubuntu" # by default builds for debian
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

storm_root_dir=/usr/lib/storm

# if maintainer parameter is not set - use default value 
if [[ -z "${maintainer}" ]]; then
  ${maintainer}="${USER}@localhost"
fi

#_ MAIN _#
# do cleanup
rm -rf ${name}*.deb
rm -rf ${fakeroot}

# prepare fakeroot - all storm files that will be packed to the package
mkdir -p ${fakeroot}
unzip -d ${fakeroot} ${src_package}
rm -rf ${fakeroot}/logs
rm -rf ${fakeroot}/log4j
rm -rf ${fakeroot}/conf

#_ MAKE DIRECTORIES _#
rm -rf ${buildroot}
mkdir -p ${buildroot}
mkdir -p ${buildroot}/${prefix}/storm
mkdir -p ${buildroot}/etc/default
mkdir -p ${buildroot}/etc/storm/conf.d
mkdir -p ${buildroot}/etc/init
mkdir -p ${buildroot}/etc/init.d
mkdir -p ${buildroot}/var/log/storm
mkdir -p ${buildroot}/var/lib/storm

#_ COPY FILES _#
cp -Rv ${fakeroot}/* ${buildroot}/${prefix}/storm
cp storm storm-nimbus storm-supervisor storm-ui storm-drpc ${buildroot}/etc/default
cp storm.yaml ${buildroot}/etc/storm
cp storm.log.properties ${buildroot}/etc/storm
cp storm-nimbus.conf storm-supervisor.conf storm-ui.conf storm-drpc.conf ${buildroot}/etc/init
#_ TODO: Symlinks for upstart init scripts 
#for f in ${buildroot}/etc/init/*; do f=$(basename $f); f=${f%.conf}; ln -s /lib/init/upstart-job ${buildroot}/etc/init.d/$f; done

if [ $dist == "debian" ]; then
  mkdir -p build/etc/init.d
else # ubuntu, etc - upstart based
  mkdir -p build/etc/init
fi
mkdir -p build/var/log/storm

packaging_version_suffix=""
if [ -n "${packaging_version}" ]; then
  packaging_version_suffix="-${packaging_version}"
fi

#_ MAKE DEBIAN _#
# versions of libzmq and jzmq are from official storm installation guide.
fpm -t deb \
    -n ${name} \
    -v "${version}${packaging_version_suffix}" \
    --description "${description}" \
    --url="{$url}" \
    -a ${arch} \
    --category ${section} \
    --vendor "" \
    --deb-user "root" \
    --deb-group "root" \
    -m ${maintainer} \
    --before-install ${origdir}/before_install.sh \
    --after-install ${origdir}/after_install.sh \
    --after-remove ${origdir}/after_remove.sh \
    --prefix=/ \
    -d "libzmq0 >= 2.1.7" -d "jzmq >= 2.1.0" -d "unzip" \
    -s dir \
    -- .

mv storm*.deb ${origdir}
popd
