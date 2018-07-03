#!/bin/sh
set -e
export BUILD_MAJOR=0
export BUILD_MINOR=0
export BUILD_REVISION=1

num=`echo $TRAVIS_BRANCH | cut -d. -f1`
if [ $num = *[[:digit:]]* ]; then export BUILD_MAJOR=$num ; fi
num=`echo $TRAVIS_BRANCH | cut -d. -f2`
if [ $num = *[[:digit:]]* ]; then export BUILD_MINOR=$num ; fi
num=`echo $TRAVIS_BRANCH | cut -d. -f3`
if [ $num = *[[:digit:]]* ]; then export BUILD_REVISION=$num ; fi

export BUILD_OS_RELEASE=$(uname -r)
export BUILD_OS_NAME=$(uname -s)
export BUILD_OS_ARCH=$(uname -m)

export VERSION="$BUILD_MAJOR"
export PATCHLEVEL="$BUILD_MINOR"
export SUBLEVEL="$BUILD_REVISION"

shell_session_update() { :; }                                                      
wget http://ftp.gnu.org/pub/gnu/gperf/gperf-3.1.tar.gz                             
export NEWPWD=$PWD                                                                 
mkdir $NEWPWD/local                                                                
tar -xvzf gperf-3.1.tar.gz -C $NEWPWD/local                                        
echo "enter1: $NEWPWD/local/gperf-3.1"                                             
sh -c 'cd $NEWPWD/local/gperf-3.1 && ./configure --prefix=$NEWPWD/local && make && make install'

if [ "$BUILD_TARGET" == "win32" ]; then 
  unset CC 
  export CROSS_COMPILE="i686-w64-mingw32-"
  export MINGW=/opt/mingw64 
  export PATH=$PATH:$MINGW/bin
  export BUILD_OS_NAME="win"
  export BUILD_OS_ARCH="x86_32"
  export BUILD_OS_RELEASE="generic"
  export WINEDEBUG=err-all,fixme-all
  export OS_EXEC="wine"
  unset  JDK_HOME
  unset  JAVA_HOME
fi 
if [ "$BUILD_TARGET" == "win64" ]; then 
  unset CC 
  export CROSS_COMPILE="x86_64-w64-mingw32-"
  export MINGW=/opt/mingw64 
  export PATH=$PATH:$MINGW/bin
  export BUILD_OS_NAME="win"
  export BUILD_OS_ARCH="x86_64"
  export BUILD_OS_RELEASE="generic"
  export WINEDEBUG=err-all,fixme-all
  export OS_EXEC="wine"
  export JAVA_NAME=java-1.8.0-openjdk-1.8.0.131-1.b11.ojdkbuild.windows.x86_64
  mkdir /tmp/x86_64-w64-mingw32/
  wget https://github.com/ojdkbuild/ojdkbuild/releases/download/1.8.0.131-1/java-1.8.0-openjdk-1.8.0.131-1.b11.ojdkbuild.windows.x86_64.zip
  unzip java-1.8.0-openjdk-1.8.0.131-1.b11.ojdkbuild.windows.x86_64.zip -d /tmp/x86_64-w64-mingw32/
  chmod +x /tmp/x86_64-w64-mingw32/java-1.8.0-openjdk-1.8.0.131-1.b11.ojdkbuild.windows.x86_64/bin/java.exe
  chmod +x /tmp/x86_64-w64-mingw32/java-1.8.0-openjdk-1.8.0.131-1.b11.ojdkbuild.windows.x86_64/bin/javac.exe
  chmod +x /tmp/x86_64-w64-mingw32/java-1.8.0-openjdk-1.8.0.131-1.b11.ojdkbuild.windows.x86_64/bin/jar.exe
  export JAVA_HOME=/tmp/x86_64-w64-mingw32/java-1.8.0-openjdk-1.8.0.131-1.b11.ojdkbuild.windows.x86_64
  export JDK_HOME=/tmp/x86_64-w64-mingw32/java-1.8.0-openjdk-1.8.0.131-1.b11.ojdkbuild.windows.x86_64
  export PATH=$JAVA_HOME/bin:$PATH
fi
if [ "$BUILD_ARCH" == "s390x" ]; then
  echo "deb http://ftp.de.debian.org/debian sid main contrib non-free" | sudo tee -a /etc/apt/sources.list
  sudo apt-get update -qq
  sudo -E apt-get -yq --no-install-suggests --no-install-recommends --force-yes -o Dpkg::Options::="--force-overwrite" install flex bison gperf pkg-config gcc-s390x-linux-gnu binutils-s390x-linux-gnu linux-libc-dev-s390x-cross libc6-s390x-cross libc6-dev-s390x-cross qemu-user-static binfmt-support
  unset CC
  export CROSS_COMPILE=s390x-linux-gnu-
  export OS_EXEC="echo"
  export BUILD_OS_ARCH="x86_64"
  export OS_EXEC=$(/bin/sh scripts/travis/s390x-ld.sh)
  echo "OS_EXEC=$OS_EXEC"
fi
if [ "$BUILD_ARCH" == "powerpc64" ]; then
  echo "deb http://ftp.de.debian.org/debian sid main contrib non-free" | sudo tee -a /etc/apt/sources.list
  sudo apt-get update -qq
  sudo -E apt-get -yq --no-install-suggests --no-install-recommends --force-yes -o Dpkg::Options::="--force-overwrite" install flex bison gperf pkg-config gcc-multilib-powerpc64-linux-gnu binutils-powerpc64-linux-gnu qemu-user-static binfmt-support 
  unset CC
  export CROSS_COMPILE=powerpc64-linux-gnu-
  export OS_EXEC="echo"
  export BUILD_OS_ARCH="powerpc64"
  export OS_EXEC=$(/bin/sh scripts/travis/ppc64-ld.sh)
  echo "OS_EXEC=$OS_EXEC"
fi
if [ "$BUILD_ARCH" == "arm32" ]; then
  unset CC
  export CROSS_COMPILE=arm-linux-gnueabihf-
  export OS_EXEC="echo"
  export BUILD_OS_ARCH="arm32"
  # evil workarround sysroot
  export OS_EXEC=$(/bin/sh scripts/travis/arm-ld.sh)
  echo "OS_EXEC=$OS_EXEC"
fi
if [ "$BUILD_ARCH" == "arm64" ]; then
  unset CC
  export CROSS_COMPILE=aarch64-linux-gnu-
  export OS_EXEC="echo"
  export BUILD_OS_ARCH="arm64"
  # evil workarround sysroot
  export OS_EXEC=$(/bin/sh scripts/travis/arm64-ld.sh)
  echo "OS_EXEC=$OS_EXEC"
fi
if [ "$TRAVIS_OS_NAME" == "osx" ]; then
  unset CROSS_COMPILE 
  export BUILD_OS_NAME="osx"
  brew update 
  brew install flex bison gperftools swig 
fi

if [ "$BUILD_TARGET" == "linux" ]; then
  export BUILD_OS_NAME="linux"
fi

export VERSION="$BUILD_MAJOR"
export PATCHLEVEL="$BUILD_MINOR"
export SUBLEVEL="$BUILD_REVISION"

echo "build-id: $BUILD_ID"
echo "build-version: $VERSION"
echo "build-patchlevel: $PATCHLEVEL"
echo "build-sublevel: $SUBLEVEL"
echo "build-target: $BUILD_TARGET"
echo "build-branch: $TRAVIS_BRANCH"
echo "build-release: $BUILD_OS_RELEASE"
echo "build-name: $BUILD_OS_NAME"
