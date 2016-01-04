#!/bin/bash

BUILD_DIR="/opt/build"

docker run -h apachegpdb.localdomain -v `pwd`:$BUILD_DIR -w $BUILD_DIR ubuntu:15.10 bash -c "${BUILD_DIR}/build.sh"
