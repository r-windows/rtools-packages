# Rtools Packages

[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/r-windows/rtools-packages?branch=master)](https://ci.appveyor.com/project/jeroen/rtools-packages)
[![Azure Build Status](https://dev.azure.com/r-windows/rtools-packages/_apis/build/status/r-windows.rtools-packages?branchName=master)](https://dev.azure.com/r-windows/rtools-packages/_build/latest?definitionId=1&branchName=master)

A repository of pacman packages for use with the new [rtools 4.0](https://cran.r-project.org/bin/windows/Rtools/) build system. Successful builds from the master branch of this repository are automatically deployed on a staging server and become eventually available via `pacman` in Rtools 4.0.


## Building an rtools package

First, make sure your repository index is up to date:

```
pacman -Sy
```

To build a mingw-w64 package, open an rtools40 shell, `cd` into the package directory and run `makepkg-mingw` like this:

```
cd rtools-packages/mingw-w64-arrow
makepkg-mingw --syncdeps
```

The `--syncdeps` flag will automatically install package dependencies (see the next section if you need additional non-rtools build tools). Add `--noconfirm` to the command to skip the interactive confirmation prompt.

![](https://user-images.githubusercontent.com/216319/81677699-74bc9800-9451-11ea-8abc-d980cf5afeaa.png)

This will first build the 64-bit package `mingw-w64-x86_64-arrow`, and after that start the entire process from scratch to build the 32-bit package `mingw-w64-i686-arrow`. If you only want to build for a single architecture you can control this with the `MINGW_ARCH` environment variable.

Upcon successful completion it generates binary packages for 32 and 64 bit mingw-w64, for example: `mingw-w64-i686-arrow-4.0.0-1-any.pkg.tar.xz` and `mingw-w64-x86_64-arrow-4.0.0-1-any.pkg.tar.xz`. You can install these with `pacman -U` (U for upgrade):

```
pacman -U mingw-w64-i686-arrow-4.0.0-1-any.pkg.tar.xz
pacman -U mingw-w64-x86_64-arrow-4.0.0-1-any.pkg.tar.xz
```

Once the system library has been installed with pacman, you can link to it in your R package in the usual way. The rtools40 compiler will automatically find the headers and libraries for installed system libraries, just like on Linux.

## Contributing to rtools-packages

To add or update a pacman package in rtools40, please send a pull request to the [rtools-packages](https://github.com/r-windows/rtools-packages) repository. The CI will automatically build it for you, but please test locally before sending the pull request. 

If you want to add a new rtools40 package that is already available in [msys2](https://packages.msys2.org/updates), you can simply adapt the PKGUILD from the their [msys2/MINGW-packages](https://github.com/msys2/MINGW-packages) repositories. However there is one important thing that needs to be changed for use with R:

You need to adapt the build scripts in the `PKGBUILD` to __only build static libraries__ (`libfoo.a` files). For example with autotools you may need to add `--enable-static --disable-shared` and for cmake you may need something like `-DBUILD_SHARED_LIBS=OFF` and for meson you need `--default-library=static`. Some C/C++ libraries use custom build scripts, in which case you need to figure out how to make it produce static libraries.

This is important because Windows R binary packages need to be standalone and redistributable, so __packages in the `rtools-packages` repo may not contain dll files__. 


## Extra build utilities (i.e. autotools)

Some older C/C++ system libs need additional build utilities which we do not provide in rtools, such as autoconf. Build utilities are the pacman packages that are not prefixed with `mingw-w64`. You can get these from the upstream [msys2 pacman repository](https://packages.msys2.org/). There many of them, and they change frequently. Build utilities should be declared in the `makedepends` of the `PKGBUILD` file. You should not use these utilities from within R packages, only for building pacman packages.

By default, the rtools40 environment is frozen in a stable state and only allows you to install extra rtools packages. Enabling the upstream msys2 repository and installing extra utilities may alter the rtools40 behavior, so avoid this on important R package build servers.

To enable the upstream msys repo, open the file `c:\rtools40\etc\pacman.conf` in a text editor and uncomment the following 2 lines at the very end of the file:

```
## 3rd party msys2 packages (rtools hackers only!)
[msys]
Include = /etc/pacman.d/rtools.msys
```

Once the msys repo is enabled, you can install extra tools needed to build libraries and other software. For example you can install autoconf or vim and so on:

```sh
pacman -Sy
pacman -S autoconf automake libtool
pacman -S vim
```

Rtools40 will never install anything outside of your rtools40 installation directory. So if you somehow messed up the installation beyond repair, simply reinstall rtools40 to start over.

## Using ccache

To speed up repetitive builds during packaging, install and enable `ccache`:

  - Install it in the mingw64 shell with `pacman -S mingw-w64-x86_64-ccache`
  - Edit `/etc/makepkg_mingw.conf` add a line containing `PATH="${MINGW_PREFIX}/lib/ccache/bin:${PATH}"`
