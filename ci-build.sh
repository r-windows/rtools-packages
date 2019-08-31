#!/bin/bash

# AppVeyor and Drone Continuous Integration for MSYS2
# Authors: Renato Silva, Qian Hong, Jeroen Ooms

# Setup git and CI
cd "$(dirname "$0")"
source 'ci-library.sh'
deploy_enabled && mkdir artifacts
deploy_enabled && mkdir sourcepkg

# Remove packages
deploy_enabled && cd artifacts
execute 'Removing JAGS from repository' remove_from_repository "${PACMAN_REPOSITORY:-ci-build}" "jags"
success 'Package removal successful'
exit 0

# Depending on if this is an rtools40 or msys64 installation:
if [[ $(cygpath -m /) == *"rtools40"* ]]; then
	# rtools40: enable upstream msys2 (but keep rtools-base as primary)
	curl -L https://raw.githubusercontent.com/r-windows/rtools-installer/master/disable-msys.patch | patch -d/ -R -p0
else
	# msys64: remove preinstalled toolchains and swith to rtools40 repositories
    pacman --noconfirm -Rcsu $(pacman -Qqe | grep "^mingw-w64-")
    pacman --noconfirm -Rcsu gcc pkg-config
    cp -f pacman.conf /etc/pacman.conf
fi

pacman --noconfirm -Scc
pacman --noconfirm -Syyu
pacman --noconfirm --needed -S git base-devel binutils

# Install core build stuff
pacman --noconfirm --needed -S mingw-w64-{i686,x86_64}-{crt,winpthreads,gcc,libtre,pkg-config,xz}

# Initiate git
git_config user.email 'ci@msys2.org'
git_config user.name  'MSYS2 Continuous Integration'
git remote add upstream 'https://github.com/r-windows/rtools-packages'
git fetch --quiet upstream

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
