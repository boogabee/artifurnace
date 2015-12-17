#!/bin/sh

BUILD_DIR="/opt/build"  

docker run -v `pwd`:$BUILD_DIR -w $BUILD_DIR centos6 bash -c './build.sh' 
