#!/bin/sh

BUILD_DIR="/opt/deploy"  

docker run --privileged=true -h apachegpdb.localdomain -t -v `pwd`:${BUILD_DIR} -w ${BUILD_DIR} centos:7.1.1503 bash -c "${BUILD_DIR}/deploy.sh"

