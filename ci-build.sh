#!/bin/bash

# AppVeyor and Drone Continuous Integration for MSYS2
# Authors: Renato Silva, Qian Hong, Jeroen Ooms

# Setup git and CI
cd "$(dirname "$0")"
source 'ci-library.sh'
deploy_enabled && mkdir artifacts
deploy_enabled && mkdir sourcepkg
git_config user.email 'ci@msys2.org'
git_config user.name  'MSYS2 Continuous Integration'
git remote add upstream 'https://github.com/r-windows/rtools-packages'
git fetch --quiet upstream

# Remove toolchain packages (preinstalled on AppVeyor)
pacman --noconfirm -Rcsu mingw-w64-{i686,x86_64}-toolchain gcc pkg-config

# Set build repositories
cp -f pacman.conf /etc/pacman.conf
pacman --noconfirm -Scc
pacman --noconfirm -Syyuu

# Install core build stuff
pacman --noconfirm -S mingw-w64-{i686,x86_64}-{crt,winpthreads,gcc,libtre,pkg-config,xz}

# Detect changed packages
list_commits  || failure 'Could not detect added commits'
list_packages || failure 'Could not detect changed files'
message 'Processing changes' "${commits[@]}"
test -z "${packages}" && success 'No changes in package recipes'
define_build_order || failure 'Could not determine build order'

# Build
message 'Building packages' "${packages[@]}"
execute 'Approving recipe quality' check_recipe_quality

# Force static linking
rm -f /mingw32/lib/*.dll.a
rm -f /mingw64/lib/*.dll.a
export PKG_CONFIG="/${MINGW_INSTALLS}/bin/pkg-config --static"

case ${MINGW_INSTALLS} in
mingw32)
  dl_arch=i686
;;
mingw64)
  dl_arch=x86_64
;;
esac

for package in "${packages[@]}"; do
    execute 'Downloading binary' curl -OL "https://ftp.opencpu.org/gcc830/mingw-w64-${dl_arch}-gcc-8.3.0-9300-any.pkg.tar.xz"
    execute 'Downloading binary' curl -OL "https://ftp.opencpu.org/gcc830/mingw-w64-${dl_arch}-gcc-fortran-8.3.0-9300-any.pkg.tar.xz"
    execute 'Downloading binary' curl -OL "https://ftp.opencpu.org/gcc830/mingw-w64-gcc-8.3.0-9300.src.tar.gz"
    #execute 'Building binary' makepkg-mingw --noconfirm --noprogressbar --skippgpcheck --nocheck --syncdeps --rmdeps --cleanbuild
    #execute 'Building source' makepkg --noconfirm --noprogressbar --skippgpcheck --allsource --config '/etc/makepkg_mingw64.conf'
    execute 'Installing' yes:pacman --noprogressbar --upgrade *.pkg.tar.xz
    #execute 'Checking Binaries' find ./pkg -regex ".*\.\(exe\|dll\|a\|pc\)"
    deploy_enabled && mv "${package}"/*.pkg.tar.xz artifacts
    deploy_enabled && mv "${package}"/*.src.tar.gz sourcepkg
    unset package
done

# Deploy
deploy_enabled && cd artifacts || success 'All packages built successfully'
execute 'Generating pacman repository' create_pacman_repository "${PACMAN_REPOSITORY:-ci-build}"
execute 'Generating build references'  create_build_references  "${PACMAN_REPOSITORY:-ci-build}"
execute 'SHA-256 checksums' sha256sum *
success 'All artifacts built successfully'
