Storm Debian Packaging
==============================================================

Build scripts for building a storm .deb-packages with [FPM](https://github.com/jordansissel/fpm/).

The build scripts provided compile the dependencies listed [here](https://github.com/nathanmarz/storm/wiki/Installing-native-dependencies).

Libraries are downloaded to `./downloads/`, if files present - script will not redownload them. This also could be used to build custom versions, etc, just by putting/linking correct files to `./downloads/`

The build_storm.sh script will setup a target directory in `./tmp/` with the format required for FPM to turn a directory into a .deb package. As a bonus, if you want to change the structure of the package, just change the script to modify the target directory. Then issue the FPM build command, and you are good to go.

Afterwards package is moved to `./` folder, but the `./tmp` tree remains there untill cleanup before next build.

Usage:
----------------

Run the script with optional `-p` packaging version and `-m` maintainer.

* ./build_storm.sh - Storm
   `./build_storm.sh -p 2 -m "myemail@example.com"`

Run with `-h` to read help.

Just run the build scripts in prepared environment, and debian artifacts will be created.



During the installation storm package also creates or enables existing storm user.

Compatibity:
-------------------
* Different versions, tested on Squeeze/Wheezy, please see tags in repository.

Details:
-------------

### $STORM_HOME and storm user home.

Checking the history of this project, initially `$STORM_HOME` was `/opt/storm`.
Then some of the forks used `/usr/lib/storm`,
then original maintaner used `/var/lib/storm`,
and another forks moved again to use `/opt/storm`...

Storm distribution (as it is downloaded in these scripts),
deviate from debian packaging conventions conventions, (like separating libs, and executables), so all the stuff that has to do something with storm should go to one `$STORM_HOME` folder.

Basically there are 2 folders (except configs, logs and init scripts):

- `$STORM_HOME` - created by package, stores all the libs and storm executables in `lib` and `bin` subfolders
- `storm.local.dir` - should be created by user and mentioned in storm.yaml (according to installation manual), by default `§STORM_HOME/storm-local` is used.

[This](http://serverfault.com/questions/96416/should-i-install-linux-applications-in-var-or-opt) is a good answer "where should software be installed".

Also, following [Filesystem Hierarchy Standard](http://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard)  [here](http://www.pathname.com/fhs/): `/opt` is for programs that are not packaged and don't follow the standards. You'd just put all the libraries there together with the program.

The dilemma is how to organize a package, due to different perception by admins and storm developers:

```
  |                        | ADMINS                | DEVELOPERS
  ------------------------------------------------------------------
  | Binary files           | /usr/bin/             | $STORM_HOME/bin
  | Librariers             | /usr/lib/storm        | $STORM_HOME/lib
  | Configs                | /etc/storm/           | $STORM_HOME/conf (and $STORM_HOME/logback)
  | Logback config         | /etc/storm/logback.cfg| $STORM_HOME/logback #(rly?) or there is something else?  
  | Logs                   | /var/log/storm        | $STORM_HOME/logs
  | Supervisors (daemons)  | /etc/init.d/ (debian) | N/A
  | storm.local.dir        | /var/lib/storm        | ? (e.g. /mnt/storm by miguno, link below)

```

```

/usr/bin/storm -> $STORM_HOME/bin/storm
/usr/lib/storm -> $STORM_HOME
# so when storm is called it will refer to ./lib
# other way around for etc/storm to save configs on storm uninstall
# and also save logs on uninstall
$STORM_HOME/conf -> /etc/storm/
$STORM_HOME/logback -> /etc/storm/
$STORM_HOME/logs -> /var/log/storm/

links

```

```
drwxr-xr-x 2 root root  4096 Jul 24 15:00 bin
-rw-r--r-- 1 root root 34239 Jun 12 22:46 CHANGELOG.md
lrwxrwxrwx 1 root root    10 Jul 24 14:39 conf -> /etc/storm
-rw-r--r-- 1 root root   538 Mar 13 00:17 DISCLAIMER
drwxr-xr-x 2 root root  4096 Jul 24 15:00 lib
-rw-r--r-- 1 root root 22822 Jun 11 18:07 LICENSE
lrwxrwxrwx 1 root root    10 Jul 24 14:39 logback -> /etc/storm
lrwxrwxrwx 1 root root    14 Jul 24 14:39 logs -> /var/log/storm
-rw-r--r-- 1 root root   981 Jun 10 15:10 NOTICE
drwxr-xr-x 5 root root  4096 Jul 24 15:00 public
-rw-r--r-- 1 root root  7445 Jun  9 16:24 README.markdown
-rw-r--r-- 1 root root    17 Jun 16 14:22 RELEASE
-rw-r--r-- 1 root root  3581 May 29 14:20 SECURITY.md
lrwxrwxrwx 1 root root    14 Jul 24 15:37 storm-local -> /var/lib/storm


```

So, in this package _it was choosen_ to use `/opt/storm` as `$STORM_HOME`
and also as home folder for storm user.

Also, to save some efforts needed otherwise for sorting all the storm stuff to
bin/lib/share/var/etc...

Maybe later, but first there should be a reason and answer to one of the questions: where to put storm user home folder (it should not be /usr/lib/storm).
Like an option, binaries should be in /usr/bin/storm, libs in /usr/lib/storm, home folder in /var/??? or /home? or should we create /app?. It is easier and closer to (old) convention to put all the stuff to /opt, custom package that is packaged.

`storm.preinst` creates/enables a user with home folder hardcoded to /opt/storm, but folder is not created because of --no-create-home param. The storm home is set in several files, so if changed - they are needed to be checked for consistency.

### Logging

By default storm shipped pre-configured to log into ${storm.home}/logs/
This configuration is done in `logback.xml`.

This behaviour is kept untouched so far.

Dependencies and Requirements:
----------------------

### Vagrant (Optional)

I have used [vagrant-debian-wheezy-64](https://github.com/dotzero/vagrant-debian-wheezy-64) to create a vagrant box, called `wheezy64`. It is used as a base env to build package.

Mostly I have done this because it extends script compatibility to other OS's and there are no issues with ruby gems, etc.

So I would recommend to use vagrant to automatically provision the machine to build the script. (relies on `wheezy64`)

```bash
vagrant up
vagrant ssh
cd /vagrant
# and then use commands from _Usage_ section.
```

I think other debian-based distribution can be used as well, if you don't have wheezy box.

### Compile time:

Provisioning script installs next dependencies for Debian/Ubuntu:

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

### Run Time

According to [official storm guide](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster):

- Java 6
- Python 2.6.6

Things to do:
--------------------

- [ ] move all the env variable from defaults to storm_env.ini
- [ ] updated to hardcoded STORM_CONF in ./conf
- [ ] separate project to 4 packages (common, nimbus, ui, supervisor)
- [ ] wright access only to log folder and storm.local.dir (/var/lib/storm)
- [ ] patch for default distribution to use /var/lib/storm as storm.local.dir

apt-get install fakeroot
apt-get install dpkg-dev

dpkf-buildpackage -rfakeroot

- [ ] define how to use logging (new logback config.)
- [ ] clean-up storm-local on package removal, so it doesn't collide with further installations
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
