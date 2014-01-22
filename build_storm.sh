#!/bin/bash
# downloads and builds debian package for storm
# ./tmp/ folder is used as temporary build place
# ./downloads/ is used as place to store downloaded files,
# so if needed the sources could be downloaded once.

# TODO: Change defaults to ubuntu...?

set -x

# package info:
name=storm
packaging_version=""

# made version hardcoded because there is no more sense to keep it flexible
# download urls could not be generated easyly 
# anymore for http://storm-project.net/downloads.html
# so waiting till the project is migrated to apache

version=0.9.0.1
src_package="${name}-${version}.zip"
download_url="https://dl.dropboxusercontent.com/s/dj86w8ojecgsam7/storm-0.9.0.1.zip"

maintainer="${USER}@localhost" # default value
description="Storm is a distributed realtime computation system. Similar to how Hadoop provides a set of general primitives
for doing batch processing, Storm provides a set of general primitives for doing realtime computation. Storm is simple, can
be used with any programming language, is used by many companies, and is a lot of fun to use!"
url="http://storm-project.net"
arch="all"
section="mics"
prefix="/usr/lib"

# build options and vars:
origdir="$(pwd)"
dist="debian" #use old debian init.d scripts or ubuntu upstart
downloads="${origdir}/downloads"

storm_home=/opt/storm
libzmq_name=libzmq1 # read README why name ZeroMQ library libzmq1
libzmq_version=2.1.7 # read README why libzmq 2.1.7 should be used as storm dep. 
jzmq_name=jzmq # read README why jzmq name is used as package name
jzmq_version=2.0.10 # read README why jzmq 2.0.10 should be used

#_ PROCESS CMD ARGUMENTS _#
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      cat >&2 <<EOT
Usage: ${0##*/} [<options>]

Build a Storm Debian package.
If downloads/storm-${version}.zip is present, that does not redownload the file

Options:

  -p, --packaging_version <packaging_version>
    A suffix to add to the Debian package version. E.g. Storm version could be 0.8.1
    and this could be 2, resulting in a Debian package version of 0.8.1-2.

  -m, --maintainer <maintainer_email>
    Use maintainer email to include the data into package, 
    if not provided - will be generated automatically from user name.
  
  --upstart 
    builds package for ubuntu upstart, by default builds for debian init.d.

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
     --upstart)
       dist="ubuntu" # by default builds for debian... TODO: Change?
       ;;
     *)
       echo "Unknown option $1" >&2
       exit 1
  esac
  shift
done

# set packaging version suffix if provided
packaging_version_suffix=""
if [ -n "${packaging_version}" ]; then
  packaging_version_suffix="-${packaging_version}"
fi

# download and unpack sources only if folder does not exist
if [[ ! -d "${downloads}/${name}-${version}" ]]; then
  mkdir -p ${downloads} && pushd ${downloads}
    wget ${download_url}
    unzip $src_package
  popd
else
  echo "Folder ${downloads}/${name}-${version} is present. NOT downloading."
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
mkdir -p build/var/log/storm

## Create folder for init scripts/upstart
if [ $dist == "debian" ]; then
  mkdir -p build/etc/init.d
else # ubuntu, etc - upstart based
  mkdir -p build/etc/init
fi

# Explode downloaded archive & cleanup files
# TODO: check that storm home folder is written with right data
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

# copy inistall scripts for debian
if [ $dist == "debian" ]; then
  cp ${origdir}/init.d/* etc/init.d/
#else # ubuntu, etc - upstart based
  # TODO: this copies files for ubuntu... Copy init scripts for Debian?
  # cp ${origdir}/storm-nimbus.conf ${origdir}/storm-supervisor.conf ${origdir}/storm-ui.conf ${origdir}/storm-drpc.conf etc/init
  #_ TODO: Check symlinks for upstart init scripts 
  #for f in ${buildroot}/etc/init/*; do f=$(basename $f); f=${f%.conf}; ln -s /lib/init/upstart-job ${buildroot}/etc/init.d/$f; done
fi

cp ${origdir}/init.d/* etc/init.d/

#_ MAKE DEBIAN _#
# TODO: Check def-user, deb-group
    
fpm -t deb \
    -n ${name} \
    -v "${version}${packaging_version_suffix}" \
    --description "${description}" \
    --category "${section}" \
    --url="{$url}" \
    -a ${arch} \
    --vendor "" \
    --deb-user "root" \
    --deb-group "root" \
    -m ${maintainer} \
    --before-install ${origdir}/storm.preinst \
    --after-install ${origdir}/storm.postinst \
    --after-remove ${origdir}/storm.postrm \
    --prefix=/ \
    -d "${libzmq_name} >= ${libzmq_version}" -d "${jzmq_name} >= ${jzmq_version}" -d "unzip" \
    -s dir \
    -- .

mv ${name}*.deb ${origdir}
popd
