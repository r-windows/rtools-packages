#!/bin/bash
cd "$(dirname "$0")"
source 'ci-library.sh'
mkdir artifacts
mkdir sourcepkg

## Remove packages
#deploy_enabled && cd artifacts
#execute 'Removing old python3 packages from index' remove_from_repository "${PACMAN_REPOSITORY:-ci-build}" "python3"
#success 'Package removal successful'
#exit 0

# Remove preinstalled libraries depending on if this is an rtools40 or msys64 install:
if [[ $(cygpath -m /) == *"rtools40"* ]]; then
  echo "Found preinstalled rtools40 compilers!"
else
  pacman --noconfirm -Rcsu $(pacman -Qqe | grep "^mingw-w64-")
fi

# Disable upstream mingw-packages
cp -f pacman.conf /etc/pacman.conf
pacman --noconfirm -Scc
pacman --noconfirm -Syyu
pacman --noconfirm --needed -S git base-devel binutils unzip
pacman --noconfirm --needed -S mingw-w64-${MINGW_TOOLCHAIN}-{gcc,libtre,pkg-config,xz}

# Remove weird upstream build flags
sed -i 's/,--default-image-base-high//g' /etc/makepkg_mingw.conf

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
rm -f /ucrt64/lib/*.dll.a
export PKG_CONFIG="/${MINGW_ARCH}/bin/pkg-config --static"
export PKGEXT='.pkg.tar.xz'

for package in "${packages[@]}"; do
    execute 'Building binary' makepkg-mingw --noconfirm --noprogressbar --skippgpcheck --syncdeps --rmdeps --cleanbuild
    MINGW_ARCH=mingw64 execute 'Building source' makepkg-mingw --noconfirm --noprogressbar --skippgpcheck --allsource
    execute 'List output contents' ls -ltr
    execute 'Installing' yes:pacman --noprogressbar --upgrade *.pkg.tar.xz
    execute 'Checking Binaries' find ./pkg -regex ".*\.\(exe\|dll\|a\|pc\)"
    execute 'Copying binary package' mv *.pkg.tar.xz ../artifacts
    execute 'Copying source package' mv *.src.tar.gz ../sourcepkg
    unset package
done

# Prepare for deploy
cd artifacts
execute 'Updating pacman repository index' create_pacman_repository "${PACMAN_REPOSITORY:-ci-build}"
execute 'Generating build references'  create_build_references  "${PACMAN_REPOSITORY:-ci-build}"
execute 'SHA-256 checksums' sha256sum *
success 'All artifacts built successfully'
