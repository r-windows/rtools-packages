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
git remote add upstream 'https://github.com/r-windows/mingw-packages'
git fetch --quiet upstream

# Remove toolchain packages (preinstalled on AppVeyor)
pacman --noconfirm -Rcsu mingw-w64-{i686,x86_64}-toolchain

# Set build repositories
cp -f pacman.conf /etc/pacman.conf
pacman --noconfirm -Scc
pacman --noconfirm -Syyuu

# Install gcc
pacman --noconfirm -S mingw32/mingw-w64-i686-{xz,gcc,libtre}
pacman --noconfirm -S mingw64/mingw-w64-x86_64-{xz,gcc,libtre}

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
export PKG_CONFIG="pkg-config --static"

for package in "${packages[@]}"; do
    execute 'Building binary' makepkg-mingw --noconfirm --noprogressbar --skippgpcheck --nocheck --syncdeps --rmdeps --cleanbuild
    execute 'Building source' makepkg --noconfirm --noprogressbar --skippgpcheck --allsource --config '/etc/makepkg_mingw64.conf'
    execute 'Installing' yes:pacman --noprogressbar --upgrade *.pkg.tar.xz
    execute 'Checking Binaries' find ./pkg -regex ".*\.\(exe\|dll\|a\|pc\)"
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
