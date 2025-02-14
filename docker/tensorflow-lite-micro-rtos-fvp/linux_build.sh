#!/bin/bash

BASEDIR=$(dirname "$0")

# Usage: takes compiler as input
usage() { 
    echo "Usage: $0 [-c <gcc|armclang>]" 1>&2
    echo "   -c|--compiler  : The compiler to use to build the applications, gcc|armclang (default: armclang)" 1>&2
    exit 1 
}

COMPILER=armclang
NPROC=`grep -c ^processor /proc/cpuinfo`

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--compiler) COMPILER="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

if [ ${COMPILER} = 'armclang' ];
then
    if [ -z ${ARMLMD_LICENSE_FILE} ]; 
    then 
        echo "ARMLMD_LICENSE_FILE is unset"
        echo "Please set ARMLMD_LICENSE_FILE to a valid License Server before proceeding"
        exit;
    fi
    TOOLCHAIN_FILE=../../../ethos-u/core_platform/cmake/toolchain/armclang.cmake
elif [ ${COMPILER} = 'gcc' ]
then
    TOOLCHAIN_FILE=../../../ethos-u/core_platform/cmake/toolchain/arm-none-eabi-gcc.cmake
else
    usage;
fi

# Only clone ethos-u if it doesn't exist already
if [ ! -d ethos-u ];
then
    git clone -b 21.02 https://git.mlplatform.org/ml/ethos-u/ethos-u.git
    pushd ${BASEDIR}/ethos-u
    python3 fetch_externals.py -c 21.02.json fetch
    popd
fi

pushd ${BASEDIR}/sw/corstone-300-person-detection
    mkdir -p build
    cd build
    cmake -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE} ..
    make -j ${NPROC}
popd

pushd ${BASEDIR}/sw/corstone-300-mobilenet-v2
    mkdir -p build
    cd build
    cmake -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE} ..
    make -j ${NPROC}
popd
