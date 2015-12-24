#!/bin/sh

BUILD_DIR="/opt/deploy"  

docker run -h apachegpdb.localdomain  --privileged=true -t -v `pwd`:${BUILD_DIR} -w ${BUILD_DIR} centos:6.7 bash -c "${BUILD_DIR}/deploy.sh"

