#!/bin/bash
name=storm
version=0.8.1
url=http://storm-project.net
package="storm-${version}.zip"
download_url="https://github.com/downloads/nathanmarz/storm/${package}"
buildroot=build
fakeroot=storm-${version}
origdir="$(pwd)"
description="Storm is a distributed realtime computation system. Similar to how Hadoop provides a set of general primitives for doing batch processing, Storm provides a set of general primitives for doing realtime computation. Storm is simple, can be used with any programming language, is used by many companies, and is a lot of fun to use!"
storm_root_dir=/usr/lib/storm

#_ MAIN _#
rm -rf ${name}*.deb
if [[ ! -f "${package}" ]]; then
  wget ${download_url}
fi
mkdir -p tmp && pushd tmp
rm -rf ${fakeroot}
unzip ${origdir}/storm-${version}.zip
rm -rf ${fakeroot}/logs
rm -rf ${fakeroot}/log4j
rm -rf ${fakeroot}/conf

#_ MAKE DIRECTORIES _#
rm -rf ${buildroot}
mkdir -p ${buildroot}${storm_root_dir}
mkdir -p ${buildroot}/etc/default
mkdir -p ${buildroot}/etc/storm/conf.d
mkdir -p ${buildroot}/etc/init
mkdir -p ${buildroot}/var/log/storm

#_ COPY FILES _#
cp -R ${fakeroot}/* ${buildroot}${storm_root_dir}
cp ${origdir}/storm ${origdir}/storm-nimbus ${origdir}/storm-supervisor ${origdir}/storm-ui ${origdir}/storm-drpc ${buildroot}/etc/default
cp ${origdir}/storm.yaml ${buildroot}/etc/storm
cp ${origdir}/storm.log.properties ${buildroot}/etc/storm
cp ${origdir}/storm-nimbus.conf ${origdir}/storm-supervisor.conf ${origdir}/storm-ui.conf ${origdir}/storm-drpc.conf ${buildroot}/etc/init

#_ MAKE DEBIAN _#
cd ${buildroot}
fpm -t deb -n $name -v $version --description "$description" --url="$url" -a all --prefix=/ -d "libzmq0 = 2.1.7" -d "jzmq >= 2.1.0" -s dir -- .
mv storm*.deb ${origdir}
popd
