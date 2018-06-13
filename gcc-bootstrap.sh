# Bootstrap some external compilers
mkdir -p /compilers
cd /compilers
curl -OL --connect-timeout 10 --max-time 60 --retry 5 "https://cloud.r-project.org/bin/windows/Rtools/i686-810-posix-dwarf-rt_v5-s.7z"
curl -OL --connect-timeout 10 --max-time 60 --retry 5 "https://cloud.r-project.org/bin/windows/Rtools/x86_64-810-posix-seh-rt_v5-s.7z"
7z x i686-810-posix-dwarf-rt_v5-s.7z
7z x x86_64-810-posix-seh-rt_v5-s.7z
cd -
export PATH="/compilers/${MINGW_INSTALLS}/bin:${PATH}"
export CC="/compilers/${MINGW_INSTALLS}/bin/gcc"
export CXX="/compilers/${MINGW_INSTALLS}/bin/g++"
echo "PATH: $PATH"
ls -ltr "/compilers/${MINGW_INSTALLS}/bin"
which gcc
gcc --version
