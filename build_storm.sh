#!/bin/bash
set -e
set -u

origdir="$(pwd)"
src_dir=$origdir/storm
[ -d "$src_dir" ] || exit 1

src_version=$(cat $src_dir/project.clj | head -1 | awk '{print $NF}')
if [ -z "$src_version" ]; then
  echo "Could not determine version from $src_dir/project_clj" >&2
  exit 1
fi
new_jar=$src_dir/target/storm-${src_version}.jar
if [ ! -f "$new_jar" ]; then
  echo "$new_jar not found" >&2
  exit 1
fi

name=storm
version=0.8.1
description="Storm is a distributed realtime computation system. Similar to how Hadoop provides a set of general primitives
for doing batch processing, Storm provides a set of general primitives for doing realtime computation. Storm is simple, can
be used with any programming language, is used by many companies, and is a lot of fun to use!"
url="http://storm-project.net"
arch="all"
section="misc"
package_version=""
src_package="storm-${version}.zip"
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

package_checkout_dir=$origdir/../storm-${version}
[ -d "$package_checkout_dir" ] || exit 1

rm -rf $package_checkout_dir/logs
rm -rf $package_checkout_dir/log4j
rm -rf $package_checkout_dir/conf
rm -f $package_checkout_dir/storm-*.jar
cp -R $package_checkout_dir/ build${storm_root_dir}
cp $src_jar build${storm_root_dir}

cd build
cp ${origdir}/storm ${origdir}/storm-nimbus ${origdir}/storm-supervisor ${origdir}/storm-ui ${origdir}/storm-drpc etc/default
cp ${origdir}/storm.yaml etc/storm
cp ${origdir}/storm.log.properties etc/storm
cp ${origdir}/storm-nimbus.conf ${origdir}/storm-supervisor.conf ${origdir}/storm-ui.conf ${origdir}/storm-drpc.conf etc/init

#_ MAKE DEBIAN _#
fpm -t deb \
    -n ${name} \
    -v ${src_version} \
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
