#!/bin/bash -x

BUILD_DIR="/opt/build"

docker run -v `pwd`:$BUILD_DIR -w $BUILD_DIR centos:8.1.1911 bash -c "${BUILD_DIR}/build.sh $*" | tee build.log 2>&1
