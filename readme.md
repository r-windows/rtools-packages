# Rtools Packages

[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/r-windows/rtools-packages?branch=master)](https://ci.appveyor.com/project/jeroen/rtools-packages)
[![Azure Build Status](https://dev.azure.com/r-windows/rtools-packages/_apis/build/status/r-windows.rtools-packages?branchName=master)](https://dev.azure.com/r-windows/rtools-packages/_build/latest?definitionId=1&branchName=master)

A repository of pacman packages for use with the new [rtools 4.0](https://cran.r-project.org/bin/windows/Rtools/) build system. Successful builds from the master branch of this repository are automatically deployed on [bintray](https://dl.bintray.com/rtools/) and become directly available in the `pacman` tool in Rtools 4.0.


## Building an rtools package

To build a mingw-w64 package, open an rtools40 shell, `cd` into the package directory and run `makepkg-mingw` like this:

```
cd rtools-packages/mingw-w64-sqlite3
makepkg-mingw --syncdeps
```

The `--syncdeps` flag will automatically ask to install missing dependencies (see the next section if you need extra build dependencies).

Upcon successful completion it generates binary packages for 32 and 64 bit mingw-w64, for example: `mingw-w64-i686-sqlite3-3.27.1-any.pkg.tar.xz` and `mingw-w64-x86_64-sqlite3-3.27.1-any.pkg.tar.xz`. You can install these with `pacman -U` (U for upgrade):

```
pacman -U mingw-w64-i686-sqlite3-3.27.1-any.pkg.tar.xz
pacman -U mingw-w64-x86_64-sqlite3-3.27.1-any.pkg.tar.xz
```

Once the system library has been installed with pacman, you can link to it in your R package in the usual way. The rtools40 compiler will automatically find the headers and libraries for installed system libraries, just like on Linux.


## Extra build dependenies from msys

In order to build C/C++ system libs, you may need additional build utilities (such as autoconf) from the upstream [msys2 pacman repository](https://packages.msys2.org/). Build utilities are the pacman packages that are not prefixed with `mingw-w64`. There many of them, and they change frequently.

By default, the rtools40 environment is frozen in a stable state and only allows you to install extra rtools packages. Enabling the upstream msys2 repository is easy, but note that installing extra utilities may alter the rtools40 behavior, so avoid this on important R package build servers.

To enable the upstream msys repo, open the file `c:\rtools40\etc\pacman.conf` in a text editor and uncomment the following 2 lines at the very end of the file:

```
## 3rd party msys2 packages (rtools hackers only!)
[msys]
Include = /etc/pacman.d/mirrorlist.msys
```

Now update the runtime system: open the rtools40 shell and run `pacman -Syu`. In some cases, this may first upgrade `msys-runtime` or `bash` which you are currently using, which causes the terminal window to freeze after the upgrade. Don't worry, this is expected and happens only once. Close the window and restart the rtools40 shell, and run `pacman -Syu` again.

Once the msys repo is enabled, you can install extra tools needed to build libraries and other software. For example you can install autoconf or vim and so on:

```
pacman -S autoconf automake libtool
pacman -S vim
```

Note that rtools40 will never install anything outside of your rtools40 installation directory. So if you somehow messed up the installation beyond repair, simply reinstall rtools40 to start over.


## Submitting an rtools package

To add or update a package to this repository, send a pull request. Please try to test the build locally before sending the pull request. 

If you want to add a new library, you can often adapt them from the upstream [msys2/MINGW-packages](https://github.com/msys2/MINGW-packages) repo. Please adapt the `PKGBUILD` to __only build static libraries__ (`libfoo.a` files): R packages need to be standalone, so __libs in the `rtools-packages` repo may not contain dll files__. This is important.
