Storm Debian Packaging
==============================================================

Build scripts / sample configuration for building a Storm .deb with FPM

Requirements
------------
To make it as pain free as possible, I have used FPM to build the debian packaging. You can install it by via rubygems (gem install -r fpm). The build_storm.sh script will setup a target directory with the format required for FPM to turn a directory into a .deb package. As a bonus, if you want to change the structure of the package, just change the script to modify the target directory. Then issue the FPM build command, and you are good to go.

* FPM (<https://github.com/jordansissel/fpm/>)
* WGet
* build-essentials + any dependencies for ZeroMQ + JZMQ bindings

I have supplied some default Upstart scripts for use with the packaging. They assume your primary interface is ETH0, so you may want to change that if it's not the case. Since there is no way to update-rc.d an upstart script, there is an option for 'ENABLE=yes' in /etc/default/storm-process. I am currently using Monit, so chose not to have Upstart 'respawn' on process failure. If you would like Upstart to provide this feature, you can add 'respawn' to the scripts and upstart should take care of this for you. So using your favorite configuration management engine, you can change this to 'yes' to start the daemon on reboot. The build scripts provided compile the dependencies listed in <https://github.com/nathanmarz/storm/wiki/Installing-native-dependencies>.

Usage
-----
Included are three scripts to build the debian packages for a storm installation.

* build_storm.sh - Storm
* build_libzmq0.sh - ZeroMQ libraries
* build_jzmq0.sh - Java bindings for ZeroMQ

Just run the build scripts, and debian artifacts will be created.

Here is a sample of the layout of the package structures.

Storm Package
------
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./opt/
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./opt/storm/
    -rw-r--r-- root/root     12653 2012-08-02 18:10 ./opt/storm/CHANGELOG.md
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./opt/storm/lib/
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./opt/storm/public/
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./opt/storm/public/css/
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./opt/storm/public/js/
    -rw-r--r-- root/root      2794 2012-08-02 18:10 ./opt/storm/README.markdown
    -rw-r--r-- root/root     12710 2012-08-02 18:10 ./opt/storm/LICENSE.html
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./opt/storm/bin/
    -rw-r--r-- root/root   3896683 2012-08-02 18:10 ./opt/storm/storm-0.7.4.jar
    -rw-r--r-- root/root         6 2012-08-02 18:10 ./opt/storm/RELEASE
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./etc/
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./etc/default/
    -rw-r--r-- root/root       387 2012-08-02 18:10 ./etc/default/storm
    -rw-r--r-- root/root       166 2012-08-02 18:10 ./etc/default/storm-nimbus
    -rw-r--r-- root/root       184 2012-08-02 18:10 ./etc/default/storm-supervisor
    -rw-r--r-- root/root       160 2012-08-02 18:10 ./etc/default/storm-drpc
    -rw-r--r-- root/root       150 2012-08-02 18:10 ./etc/default/storm-ui
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./etc/storm/
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./etc/storm/conf.d/
    -rw-r--r-- root/root       364 2012-08-02 18:10 ./etc/storm/storm.log.properties
    -rw-r--r-- root/root       445 2012-08-02 18:10 ./etc/storm/storm.yaml
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./etc/init/
    -rw-r--r-- root/root       774 2012-08-02 18:10 ./etc/init/storm-drpc.conf
    -rw-r--r-- root/root       757 2012-08-02 18:10 ./etc/init/storm-ui.conf
    -rw-r--r-- root/root       816 2012-08-02 18:10 ./etc/init/storm-supervisor.conf
    -rw-r--r-- root/root       788 2012-08-02 18:10 ./etc/init/storm-nimbus.conf
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./var/
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./var/lib/
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./var/lib/storm/
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./var/log/
    drwxr-xr-x root/root         0 2012-08-02 18:10 ./var/log/storm/

Changes
------
Building jzmq can be a bit tricky, so I've forked the repo from phobos182 to add
some trick fixers.

1. After building zeromq, I couldn't get `--with-zeromq` to work when building
   `jzmq`, so I ended up running `sudo make install` in `libzmq0` to install the
   files in a well-known place in the system. This seems to be an issue with the
   include path but I didn't have the patience to figure it out.
1. I modified `build_jzmq.sh` to do a little dancing to touch a timestamp file
   and build some java classes.
1. I bumped the `storm` version to `0.8.1` because that's what I needed to use.

Building on Ubuntu
-----
I run servers on Ubuntu, so here are the packages and gem I needed to install to
see a clean build of ZeroMQ, jzmq and Storm.

* **libzmq0**

```bash
apt-get install -y git g++ uuid-dev ruby1.9.3 make
gem install fpm --no-ri --no-rdoc
```

* **jzmq**

```bash
apt-get install -y openjdk-6-jdk pkg-config autoconf automake unzip
```

Additions by wikimedia-incubator:
---------------------------------

- Now creates and runs as a storm user.
- Symlinks /etc/init.d/storm-* services to /lib/init/upstart-job.
- Fixes /etc/default and /etc/init shell variable naming bug.
- Renames package name of libzmq0 to libzmq1 to match Ubuntu's.
- Updated build scripts to work with newer versions of upstream packages.
