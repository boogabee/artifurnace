#!/bin/bash -x

set -e

yum -y clean all 
yum -y swap fakesystemd systemd

LAUNCH_DIR=`pwd`
WORKSPACE=/opt/gpdbbuild/
yum -y install gcc make wget tar git rpm-build ncurses-devel bzip2 bison flex openssl-devel libcurl-devel readline-devel bzip2-devel gcc-c++ libyaml-devel libevent-devel openldap-devel libxml2-devel libxslt-devel python-devel readline-devel apr-devel openssl-libs openssl-devel

rm -rf ${WORKSPACE}
mkdir -p ${WORKSPACE}
cd ${WORSPACE}

git clone --depth=1 https://github.com/greenplum-db/gpdb.git ${WORKSPACE}

re="^(.*?) (.*?) (.*?)$"
[[ `${WORKSPACE}/getversion` =~ $re ]] && GP_VERSION="${BASH_REMATCH[1]}" && GP_BUILDNUMBER="${BASH_REMATCH[3]}" 

CC=gcc
BUILD_VERSION=${GP_VERSION}
BUILD_NUMBER=${GP_BUILDNUMBER}`date +%Y%m%d%H%M%S`
GPDB_PACKAGE_NAME=apache-greenplum-db-${BUILD_VERSION}-${BUILD_NUMBER}-CENTOS7-x86_64
GPDB_VERSION_NAME=apache-greenplum-db-${BUILD_VERSION}-${BUILD_NUMBER}
GPDB_VERSION_PATH=/usr/local/${GPDB_VERSION_NAME}
GPDB_PATH=/usr/local/apache-greenplum-db
PATH=${GPDB_VERSION_PATH}/bin:$PATH
LD_LIBRARY_PATH=${GPDB_VERSION_PATH}/lib:${WORKSPACE}/lib:$LD_LIBRARY_PATH
C_INCLUDE_PATH=${GPDB_VERSION_PATH}/include:${WORKSPACE}/include:$C_INCLUDE_PATH
CPPFLAGS="-I ${GPDB_VERSION_PATH}/include:${WORKSPACE}/include"

# Move to the build directory
cd "${WORKSPACE}"

# Setup GPDB location
rm -rf ${GPDB_VERSION_PATH}
mkdir ${GPDB_VERSION_PATH}
rm -f ${GPDB_PATH}
ln -s ${GPDB_VERSION_PATH} ${GPDB_PATH}

#Build Conda
cd ${WORKSPACE}
if [ "$USE_MINICONDA" = "true" ]; then
  wget https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh
  chmod oug+x Miniconda2-latest-Linux-x86_64.sh
  ./Miniconda2-latest-Linux-x86_64.sh -b -f -p ${GPDB_VERSION_PATH}/ext/conda2
  export PYTHONHOME="${GPDB_VERSION_PATH}/ext/conda2"
  export PYTHONPATH=${GPDB_VERSION_PATH}/lib/python
  export PATH=$PYTHONHOME/bin:$PATH
else
  wget https://bootstrap.pypa.io/get-pip.py
  sudo python get-pip.py
  rm -f get-pip.py
fi
pip install psi
pip install lockfile
pip install paramiko
pip install tools
pip install epydoc
pip install psutil
pip install setuptools

echo "${GPDB_VERSION_PATH}/lib/" >> /etc/ld.so.conf.d/gpdb.conf
ldconfig

#Build GPDB base

cd ${WORKSPACE}
chmod oug+x configure
./configure --with-openssl --with-ldap --with-libcurl --enable-gpfdist --with-python --enable-mapreduce --prefix="${GPDB_VERSION_PATH}"
make
make install

cd ${GPDB_VERSION_PATH}
sed "s#GPHOME=.*#GPHOME=${GPDB_VERSION_PATH}#g" greenplum_path.sh > greenplum_path.sh.updated
mv greenplum_path.sh.updated greenplum_path.sh
if [ "$USE_MINICONDA" = "true" ]; then
  sed "s#ext/python#ext/conda2#g" greenplum_path.sh > greenplum_path.sh.updated
  mv greenplum_path.sh.updated greenplum_path.sh
fi
chmod oug+x greenplum_path.sh
source ./greenplum_path.sh

#Test binaries
${GPDB_VERSION_PATH}/bin/postgres --version
${GPDB_VERSION_PATH}/bin/initdb --version
${GPDB_VERSION_PATH}/bin/createdb --version
${GPDB_VERSION_PATH}/bin/psql --version
${GPDB_VERSION_PATH}/bin/gpmigrator --version
${GPDB_VERSION_PATH}/bin/gpmapreduce --version
${GPDB_VERSION_PATH}/bin/gpssh --version
${GPDB_VERSION_PATH}/bin/gpfdist --version

#Package results in tarball
tar -czvf /usr/local/${GPDB_PACKAGE_NAME}.tar.gz -C /usr/local ${GPDB_VERSION_NAME}

# Build additional directories we may need
cd ${WORKSPACE}
for dir in BUILD RPMS SOURCES SPECS SRPMS
do
 [[ -d $dir ]] && rm -Rf $dir
  mkdir $dir
done

#Build RPM
cd ${WORKSPACE}
cp ${LAUNCH_DIR}/gpdb.spec ${WORKSPACE}/SPECS/gpdb.spec
cp /usr/local/${GPDB_PACKAGE_NAME}.tar.gz ./SOURCES/
rpmbuild --define "gpdb_ver ${BUILD_VERSION}" --define "gpdb_rel ${BUILD_NUMBER}" --define "_topdir "`pwd` -ba SPECS/gpdb.spec

mkdir -p ${LAUNCH_DIR}/output/
cp /usr/local/${GPDB_PACKAGE_NAME}.tar.gz ${LAUNCH_DIR}/output/${GPDB_PACKAGE_NAME}.tar.gz

for rpms in `ls -1 ${WORKSPACE}/RPMS/x86_64/`
do
  cp ${WORKSPACE}/RPMS/x86_64/${rpms} ${LAUNCH_DIR}/output/${rpms}
done
