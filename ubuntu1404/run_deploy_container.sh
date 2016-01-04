#!/bin/bash

BUILD_DIR="/opt/deploy"  

docker run -h apachegpdb.localdomain  --privileged=true -t -v `pwd`:${BUILD_DIR} -w ${BUILD_DIR} ubuntu:14.04 bash -c "${BUILD_DIR}/deploy.sh"

