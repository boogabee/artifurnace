#!/bin/sh

BUILD_DIR="/opt/build"

docker run -v `pwd`:$BUILD_DIR -w $BUILD_DIR centos:7.1.1503 bash -c "${BUILD_DIR}/build.sh"
