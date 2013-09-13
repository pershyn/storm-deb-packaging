Storm Debian Packaging
==============================================================

Build scripts / sample configuration for building a Storm .deb with FPM

Interesting tutorial how to install storm on .rpm based distibution: [Running multi-node storm cluster by Michael Noll](http://www.michael-noll.com/tutorials/running-multi-node-storm-cluster/)

Compatibity:
-------------------

* Storm 0.8.1 - supported
* Storm 0.8.2 - planned to be supported
* Debian Squeeze - supported
* Debian Wheezy - planned to be supported
* Ubuntu 12.04 - planned to be supported

storm.local.dir is set to be /usr/lib/storm
(also possible /app/storm, /usr/local/storm)
 
Things to look up, fix:
--------------------------------

Dependencies:

* uuid-dev
* unzip for build-time, but for run time?

Other things:

* ownership of /usr/lib/storm is storm (but for rest system parts in there is root...) if we use root here, then storm cannot write to its home folder.
* package behaviour when home folder exists.
* libzmq*.so files executable permission by default (and jzmq)
* add a note on folder structure of build system
* add a note - all the build process is done in tmp directory
* support passing maintainer parameter
* add intended use note
* add a note on storm user home (/opt vs /usr/local/storm vs /usr/lib/storm), link to fil
* https://wiki.debian.org/MaintainerScripts

General:
-------------
Storm 0.8.1 and 0.8.2 [was tested](https://github.com/nathanmarz/storm/wiki/Installing-native-dependencies) on EXACT version of libraries (ZeroMQ 2.1.7, jzmq 2.1.0-SNAPSHOT)

### zeromq ###
Due to specific development model [that zmq uses](http://zeromq.org/area:faq), 
library package for ZeroMQ ended up having several names:

* libzmq0 - for really really old versions (apparently 2.0.* is still libzmq0)
* libzmq1 - for versions > 2.1.10 
* libzmq3 - for versions 3.*.

libzmq is GPLed, so the package is in [debian repos](http://packages.debian.org/search?suite=default&section=all&arch=any&searchon=names&keywords=libzmq).
So, what package to use on your own risk? :)

* if latest stable libzmq1 needed -> libzmq1 from debian repos.
* if latest stable libzmq3 needed -> libzmq3 from debian repos.
* if specific libzmq1 needed (either recommended 2.1.7 or other) -> use provided scripts and fpm scripts to build it.

### jzmq ###
There may be a confusion how to name this package ( _libjzmq_ or _jzmq_):
While this might be a matter of taste, in code the jzmq is used because in source codes of frozen version (jzmq 2.1.0-SNAPSHOT):

* Project originally is named "jzmq"
* project files are libjzmq.so, libjzmq.dylib, libjzmq.dll ( _this is where another option comes from_ )
* Project Artifact ID from [pom.xml](https://github.com/nathanmarz/jzmq/blob/master/pom.xml) is __jzmq__
* The jzmq project under LGPL, so it will probably will make it way to official debian repos with this name.
* with the project there is a suite to build a package for debian, <br> and in this suite ( _./debian/control_ ) is next information:
    * package: jzmq
    * Architecture: any
    * Depends: libzmq0 (>= 2.0.10), ${shlibs:Depends}, ${misc:Depends}

The bad thing is that this frozen version originally depends on libzmq0,
so it makes sence to change the dependency to libzmq1 >= 2.0.10 becase this package and suite is intended to be used with storm.
In upstream of jzmq development this change has been made already and now [using libzmq1 as dependency](https://github.com/zeromq/jzmq/commit/4e24e63c4d4b9fc2a441ce90e9581aaca0cdeafd) , so if you build a new package with newest version - it will be integrated nicely.

Also it gives the user an opportunity to update to newer version of ZeroMQ (e.g. 2.2.0) without updating to the new version of bindings, 

So, by default the 2.1.7 version of ZeroMQ library that is build using these scripts is named libzmq1.

Build-time requirements:
------------
To make it as pain free as possible, FPM is used to build the debian package. You can install it by via rubygems (gem install -r fpm). The build_storm.sh script will setup a target directory with the format required for FPM to turn a directory into a .deb package. As a bonus, if you want to change the structure of the package, just change the script to modify the target directory. Then issue the FPM build command, and you are good to go.

* FPM (<https://github.com/jordansissel/fpm/>)
* WGet
* build-essentials + any dependencies for ZeroMQ + JZMQ bindings

I have supplied some default Upstart scripts for use with the packaging. They assume your primary interface is ETH0, so you may want to change that if it's not the case. Since there is no way to update-rc.d an upstart script, there is an option for 'ENABLE=yes' in /etc/default/storm-process. I am currently using Monit, so chose not to have Upstart 'respawn' on process failure. If you would like Upstart to provide this feature, you can add 'respawn' to the scripts and upstart should take care of this for you. So using your favorite configuration management engine, you can change this to 'yes' to start the daemon on reboot. The build scripts provided compile the dependencies listed in <https://github.com/nathanmarz/storm/wiki/Installing-native-dependencies>.

Usage
-----
Included are three scripts to build the debian packages for a storm installation.

* ./build_storm.sh - Storm
* ./build_libzmq.sh - ZeroMQ libraries
* ./build_jzmq.sh - Java bindings for ZeroMQ

Just run the build scripts, and debian artifacts will be created.

Storm Package
------

Here is a sample of the layout of the package structures.

TODO: Add final view

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

-------------------------

7/11/2013 - Updated Packaging paths / guidelines based on forks. Tested on 0.8.1 on 11.04 + 12.04

-------------------------

- according to [this discussion](http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=621833) debian package should not remove any users on removal. Recommended behaviour is disabling a user.
