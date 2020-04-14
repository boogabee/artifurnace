#!/bin/sh

BUILD_DIR="/opt/deploy"  

docker run --privileged=true -h ossgpdb.localdomain -t -v `pwd`:${BUILD_DIR} -w ${BUILD_DIR} centos:8.1.1911 bash -c "${BUILD_DIR}/deploy.sh"

