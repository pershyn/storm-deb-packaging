# Storm Debian Packaging

After several updates to newer storm versions I have realized that using native debian tools to build debian packages is more fast, clean, and maintainable. Also storm became better, so I have developed new scripts, that are using `dpkg-buildpackage`, and I am very happy with it.

Since I have removed practially all the code that was initially in this repository and limited the supported platforms to debian-only, I decided to create a new repository for this.

You are welcome to visit it [here](https://github.com/pershyn/storm-debian-packaging)

If you anyway want to proceed with fpm, or build some old versions, you can check the history and also forks.
