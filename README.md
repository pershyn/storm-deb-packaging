Storm Debian Packaging
==============================================================

Build scripts / sample configuration for building a storm, libzmq and jzmq .deb-packages with [FPM](https://github.com/jordansissel/fpm/).

The build scripts provided compile the dependencies listed [here](https://github.com/nathanmarz/storm/wiki/Installing-native-dependencies).

Libraries are downloaded to `./downloads/`, if files present - script will not redownload them. This also could be used to build custom versions, etc, just by putting/linking correct files to `./downloads/`
The build_storm.sh script will setup a target directory in `./tmp/` with the format required for FPM to turn a directory into a .deb package. As a bonus, if you want to change the structure of the package, just change the script to modify the target directory. Then issue the FPM build command, and you are good to go.
Afterwards package is moved to `./` folder, but the `./tmp` tree remains there untill cleanup before next build.

Usage:
----------------

Included are three scripts to build the debian packages for a storm installation with libzmq and jzmq dependencies, with optional `-p` packaging version and `-m` maintainer.

* ./build_storm.sh - Storm
   `./build_storm.sh -p 2 -m "myemail@example.com"`
* ./build_libzmq.sh - ZeroMQ libraries v 2.1.7
   `./build_libzmq.sh -p 3 -m "myemail@example.com"`
* ./build_jzmq.sh - Java bindings for ZeroMQ v 2.1.0
  `./build_jzmq.sh -p 2 -m "myemail@example.com"`

Just run the build scripts in prepared environment, and debian artifacts will be created.
Run any command with `-h` to read help.
Note, that packages will not depend on exact packaging version of other package.  Just like `libzmq1 >= 2.1.7`, without packaging version.
So you have to take care about proper package versions installed manually or (better) using puppet/chef/salt...
During the installation storm package also creates or enables existing storm user.

Compatibity:
-------------------
* Storm 0.8.1 @ Debian Squeeze - supported and tested in [storm-0.8.1-squeeze](https://github.com/pershyn/storm-deb-packaging/tree/storm-0.8.1-squeeze) tagged branch
* Storm 0.9.0.1 @ Debian Squeeze - supported
* Apache Storm 0.9.1 Incubating @ Debian Wheezy - supported
* Ubuntu 12.04 - may work, but was not tested.

Details:
-------------

### ZeroMQ and jzmq ###
Storm 0.8.1 and 0.8.2 [was tested](https://github.com/nathanmarz/storm/wiki/Installing-native-dependencies) on EXACT version of libraries (ZeroMQ 2.1.7, jzmq 2.1.0-SNAPSHOT)
For storm 0.9.1 this seems to be the same, however can be checked. Please open an issue if you find it to be different.

#### zeromq ####
Due to specific development model [that zmq uses](http://zeromq.org/area:faq),
library package for ZeroMQ ended up having several names:

* libzmq0 - for really really old versions (apparently 2.0.* is still libzmq0)
* libzmq1 - for versions > 2.1.10
* libzmq3 - for versions 3.*.

libzmq is GPLed, so the there are stable versions in [debian repos](http://packages.debian.org/search?suite=default&section=all&arch=any&searchon=names&keywords=libzmq).

So, what package should be used (on your own risk)? :)

* if latest stable libzmq1 needed -> libzmq1 from debian repos.
* if latest stable libzmq3 needed -> libzmq3 from debian repos.
* if specific libzmq1 needed (either recommended 2.1.7 or other) -> use provided scripts and fpm scripts to build it.

In Storm 0.9.1 default messaging layer was moved to Jetty instead of 0MQ, however this package is yet here for some possible compatility issues.

#### jzmq ####
There may be a confusion how to name this package ( _libjzmq_ or _jzmq_):
While this might be a matter of taste, in code the jzmq is used because in source codes of frozen version (jzmq 2.1.0-SNAPSHOT):

* Project originally is named "jzmq"
* project files are libjzmq.so, libjzmq.dylib, libjzmq.dll ( _this is where another option comes from_ )
* Project Artifact ID from [pom.xml](https://github.com/nathanmarz/jzmq/blob/master/pom.xml) is __jzmq__
* The jzmq project under LGPL, so it will probably will make it way to official debian repos with this name.
* with the project there is a suite to build a package for debian, <br> and in this suite ( _./debian/control_ ) has next information:
```
       package: jzmq
       Architecture: any
       Depends: libzmq0 (>= 2.0.10), ${shlibs:Depends}, ${misc:Depends}
```
The bad thing is that this frozen version originally depends on libzmq0,
so it makes sense to change the dependency to libzmq1 >= 2.0.10 becase this package and suite is intended to be used with storm.
In upstream of jzmq development this change has been made already and now [jzmq is using libzmq1 as dependency](https://github.com/zeromq/jzmq/commit/4e24e63c4d4b9fc2a441ce90e9581aaca0cdeafd) , so if you build a new package with newest version - it will be integrated nicely.

Also it gives the user an opportunity to update to newer version of ZeroMQ (e.g. 2.2.0) with keeping the old version of bindings (which may be not the best way to go).

So, by default version 2.1.7 of ZeroMQ library that is used. The package called libzmq1. JZMQ has version 2.1.0 and package name jzmq.

In Storm 0.9.1 default messaging layer was moved to Jetty instead of 0MQ, however this package is yet here for some possible compatility issues.

### $STORM_HOME and storm user home.

Checking the history of this project, initially `$STORM_HOME` was `/opt/storm`. then some of the forks used `/usr/lib/storm` then original maintaner used `/var/lib/storm`, and another forks moved again to use `/opt/storm`...

Storm distribution (as it is downloaded in these scripts), deviate from debian packaging conventions conventions (like separating libs, and executables), so all the stuff that has to do something with storm should go to one `$STORM_HOME` folder.

Basically there are 2 folders (except configs, logs and init scripts):

- `$STORM_HOME` - created by package, stores all the libs and storm executable.
- `storm.local.dir` - should be created by user and mentioned in storm.yaml (according to installation manual), by default `§STORM_HOME/storm-local` is used.

[This](http://serverfault.com/questions/96416/should-i-install-linux-applications-in-var-or-opt) is a good answer "where should software be installed".

Also, following [Filesystem Hierarchy Standard](http://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard)  [here](http://www.pathname.com/fhs/): `/opt` is for programs that are not packaged and don't follow the standards. You'd just put all the libraries there together with the program.

But, with these scripts storm becomes packaged!
Any way in this package _it was choosen_ to use `/opt/storm` as `$STORM_HOME` and also as home folder for storm user. Also, to save some efforts needed otherwise for sorting all the storm stuff to bin/lib/share/var/etc...

Maybe later, but first there should be a reason and answer to one of the questions: where to put storm user home folder (it should not be /usr/lib/storm).
Like an option, binaries should be in /usr/bin/storm, libs in /usr/lib/storm, home folder in /var/??? or /home? or should we create /app?. It is easier and closer to (old) convention to put all the stuff to /opt, custom package that is packaged.

`storm.preinst` creates/enables a user with home folder hardcoded to /opt/storm, but folder is not created because of --no-create-home param. The storm home is set in several files, so if changed - they are needed to be checked for consistency.

Dependencies and Requirements:
----------------------

### Compile time:

Dependencies for Debian/Ubuntu:

```bash
apt-get install -y git g++ uuid-dev ruby make wget curl libtool openjdk-6-jdk pkg-config autoconf automake unzip
export JAVA_HOME=/usr/lib/jvm/java-6-openjdk

gem install fpm
```

On some occassions path to fpm should also be specified in PATH,
for example:
```bash
export PATH=$PATH:~/.gem/ruby/2.0.0/bin
```
```bash
export PATH=$PATH:/var/lib/gems/1.8/bin/
```

The jzmq package will link to your current version of glibc on the system that you compile the package on.
So it is _highly recommended_ to compile jzmq & package on the same system where it will be running, to avoid library version compatibility issues, like below:

```
YYYY-MM-DD hh:mm:ss b.s.d.worker [ERROR] Error on initialization of server mk-worker
java.lang.UnsatisfiedLinkError: /usr/lib/libjzmq.so.0.0.0: /lib/libc.so.6: version `GLIBC_2.14' not found (required by /usr/lib/libjzmq.so.0.0.0)
        at java.lang.ClassLoader$NativeLibrary.load(Native Method) ~[na:1.6.0_27]
...
```

#### Virtual Environment

I have used [vagrant-debian-wheezy-64](https://github.com/dotzero/vagrant-debian-wheezy-64) to create a vagrant box, called `wheezy64`. It is used as a base env to build package.
Mostly I have done this because it extends script compatibility to other OS's and there are no issues with ruby gems, etc.
So I would recommend to use vagrant to atomatically provision the machine to build the script, when you install add this box to vagrant.

```bash 
vagrant up
vagrant ssh
cd /vagrant
# and then use commands from _Usage_ section.
```

I think other debian-based distribution can be used as well, if you don't have wheezy box.

### Run Time

According to [official storm guide](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster):

- ZeroMQ 2.1.7 - Note that you should not install version 2.1.10, as that version has some serious bugs that can cause strange issues for a Storm cluster. In some rare cases, users have reported an "IllegalArgumentException" bubbling up from the ZeroMQ code when using 2.1.7 – in these cases downgrading to 2.1.4 fixed the problem.
- JZMQ
- Java 6
- Python 2.6.6
- unzip

Things to do:
--------------------

- [ ] check ownership of /usr/lib/storm is storm (but for rest system parts in there is root...) if we use root here, then storm cannot write to its home folder.
- [ ] check package installation behaviour when home folder exists.
- [ ] libzmq*.so files executable permission by default (and jzmq). Should it be so.
- [ ] add a note on folder structure of build system
- [ ] add a note - all the build process is done in tmp directory
- [ ] support passing maintainer parameter
- [ ] add intended use note
- [ ] add a note on storm user home (/opt vs /usr/local/storm vs /usr/lib/storm), link to fil
- [ ] https://wiki.debian.org/MaintainerScripts
- [ ] Symlinks /etc/init.d/storm-* services to /lib/init/upstart-job. ??
- [ ] wget vs curl used - can drop one to reduce dependencies...
- [ ] check ubuntu upstart ."They assume your primary interface is ETH0, so you may want to change that if it's not the case. Since there is no way to update-rc.d an upstart script, there is an option for 'ENABLE=yes' in /etc/default/storm-process. I am currently using Monit, so chose not to have Upstart 'respawn' on process failure. If you would like Upstart to provide this feature, you can add 'respawn' to the scripts and upstart should take care of this for you. So using your favorite configuration management engine, you can change this to 'yes' to start the daemon on reboot."

Storm Package Sample Layout
------

```
.
├── etc
│   ├── default
│   │   ├── storm
│   │   ├── storm-drpc
│   │   ├── storm-nimbus
│   │   ├── storm-supervisor
│   │   └── storm-ui
│   ├── init.d
│   │   ├── storm-drpc
│   │   ├── storm-nimbus
│   │   ├── storm-supervisor
│   │   └── storm-ui
│   └── storm
│       ├── storm.log.properties
│       └── storm.yaml
├── opt
│   └── storm
│       ├── bin
│       │   ├── build_modules.sh
│       │   ├── build_release.sh
│       │   ├── install_zmq.sh
│       │   ├── javadoc.sh
│       │   ├── storm
│       │   └── to_maven.sh
│       ├── CHANGELOG.md
│       ├── lib
│       │   ├── asm-4.0.jar
│       │   ├── carbonite-1.5.0.jar
│       │   ├── clj-stacktrace-0.2.2.jar
│       │   ├── clj-time-0.4.1.jar
│       │   ├── clojure-1.4.0.jar
│       │   ├── clojure-complete-0.2.3.jar
│       │   ├── clout-1.0.1.jar
│       │   ├── commons-codec-1.4.jar
│       │   ├── commons-exec-1.1.jar
│       │   ├── commons-fileupload-1.2.1.jar
│       │   ├── commons-io-1.4.jar
│       │   ├── commons-lang-2.5.jar
│       │   ├── commons-logging-1.1.1.jar
│       │   ├── compojure-1.1.3.jar
│       │   ├── core.incubator-0.1.0.jar
│       │   ├── curator-client-1.0.1.jar
│       │   ├── curator-framework-1.0.1.jar
│       │   ├── disruptor-2.10.1.jar
│       │   ├── guava-13.0.jar
│       │   ├── hiccup-0.3.6.jar
│       │   ├── httpclient-4.1.1.jar
│       │   ├── httpcore-4.1.jar
│       │   ├── jetty-6.1.26.jar
│       │   ├── jetty-util-6.1.26.jar
│       │   ├── jgrapht-0.8.3.jar
│       │   ├── jline-0.9.94.jar
│       │   ├── joda-time-2.0.jar
│       │   ├── json-simple-1.1.jar
│       │   ├── junit-3.8.1.jar
│       │   ├── jzmq-2.1.0.jar
│       │   ├── kryo-2.17.jar
│       │   ├── libthrift7-0.7.0-2.jar
│       │   ├── log4j-over-slf4j-1.6.6.jar
│       │   ├── logback-classic-1.0.6.jar
│       │   ├── logback-core-1.0.6.jar
│       │   ├── math.numeric-tower-0.0.1.jar
│       │   ├── minlog-1.2.jar
│       │   ├── mockito-all-1.9.5.jar
│       │   ├── netty-3.6.3.Final.jar
│       │   ├── objenesis-1.2.jar
│       │   ├── reflectasm-1.07-shaded.jar
│       │   ├── ring-core-1.1.5.jar
│       │   ├── ring-devel-0.3.11.jar
│       │   ├── ring-jetty-adapter-0.3.11.jar
│       │   ├── ring-servlet-0.3.11.jar
│       │   ├── servlet-api-2.5-20081211.jar
│       │   ├── servlet-api-2.5.jar
│       │   ├── slf4j-api-1.6.5.jar
│       │   ├── snakeyaml-1.11.jar
│       │   ├── tools.cli-0.2.2.jar
│       │   ├── tools.logging-0.2.3.jar
│       │   ├── tools.macro-0.1.0.jar
│       │   ├── tools.nrepl-0.2.3.jar
│       │   └── zookeeper-3.3.3.jar
│       ├── LICENSE.html
│       ├── logback
│       │   └── cluster.xml
│       ├── public
│       │   ├── css
│       │   │   ├── bootstrap-1.1.0.css
│       │   │   └── style.css
│       │   └── js
│       │       ├── jquery-1.6.2.min.js
│       │       ├── jquery.cookies.2.2.0.min.js
│       │       ├── jquery.tablesorter.min.js
│       │       └── script.js
│       ├── README.markdown
│       ├── RELEASE
│       ├── storm-console-logging-0.9.0.1.jar
│       ├── storm-core-0.9.0.1.jar
│       └── storm-netty-0.9.0.1.jar
└── var
    └── log
        └── storm

15 directories, 85 files

```

Read Materials:
-----------------------

* according to [this discussion](http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=621833) debian package should not remove any users on removal. Recommended behaviour is disabling a user.
* Interesting tutorial how to install storm on .rpm based distibution - [Running multi-node storm cluster by Michael Noll](http://www.michael-noll.com/tutorials/running-multi-node-storm-cluster/)
