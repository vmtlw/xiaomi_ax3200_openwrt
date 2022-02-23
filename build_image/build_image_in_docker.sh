#!/usr/bin/env bash

RUN_PATH=$PWD
SCRIPT_PATH=${SCRIPT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

cd $SCRIPT_PATH
source helpers/functions.sh

inf "RUN_PATH=$RUN_PATH"
inf "SCRIPT_PATH=$SCRIPT_PATH"

[ -x "$(command -v apt-get)" ] || err "Run on Debian!"

pwd
echo "CPU threads: $(nproc --all)"
grep 'model name' /proc/cpuinfo | uniq


USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-1000}
ARTIFACTS_PATH=${ARTIFACTS_PATH:-/tmp/artifacts}

inf "USER_ID=$USER_ID"
inf "GROUP_ID=$GROUP_ID"
inf "ARTIFACTS_PATH=$ARTIFACTS_PATH"

chown -R $USER_ID:$GROUP_ID $SCRIPT_PATH

apt-get update && \
apt-get install -y sudo curl vim gnupg

echo "
deb http://apt.llvm.org/buster/ llvm-toolchain-buster-12 main
deb-src http://apt.llvm.org/buster/ llvm-toolchain-buster-12 main" >> /etc/apt/sources.list

curl -Ls https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

export CMAKE_C_COMPILER=clang-12
export CMAKE_CXX_COMPILER=clang++-12

apt-get update && \
apt-get install -y time git-core subversion build-essential ccache ecj fastjar file screen quilt libncursesw5-dev libssl-dev \
  g++ java-propose-classpath libelf-dev bash make patch libncurses5 libncurses5-dev zlib1g-dev gawk \
  flex gettext wget unzip xz-utils python python-distutils-extra python3 python3-distutils-extra rsync \
  python3-setuptools python3-dev swig xsltproc zlib1g-dev llvm clang-12 && \
apt-get clean && \
groupadd --gid $GROUP_ID buser && \
useradd --uid $USER_ID --gid $GROUP_ID -m -s /bin/bash buser

if [[ ${IMAGE_BUILD_ONLY:-false} == false ]]; then
  inf "Run ./build_image.sh"
  # IN_DOCKER=true ./build_image.sh
  su -c "IN_DOCKER=true ./build_image.sh" buser

  mkdir -p $ARTIFACTS_PATH

  cp -rfv bin/targets/mediatek/mt7622/*.bin $ARTIFACTS_PATH/
  cp -rfv bin/targets/mediatek/mt7622/*.img $ARTIFACTS_PATH/
  cp -rfv bin/targets/mediatek/mt7622/profiles.json $ARTIFACTS_PATH/
  cp -rfv bin/targets/mediatek/mt7622/sha256sums $ARTIFACTS_PATH/
  cp -rfv /tmp/openwrt/patchfile $ARTIFACTS_PATH/
fi
