#!/bin/sh

set -e

yum -y clean all 
yum -y swap fakesystemd systemd

LAUNCH_DIR=`pwd`
WORKSPACE=/opt/gpdbbuild/
yum -y install gcc make wget tar git rpm-build ncurses-devel bzip2 bison flex openssl-devel libcurl-devel readline-devel bzip2-devel gcc-c++ libyaml-devel libevent-devel openldap-devel libxml2-devel libxslt-devel

mkdir -p ${WORKSPACE}
cd ${WORSPACE}

git clone --depth=1 https://github.com/skahler-pivotal/gpdb.git ${WORKSPACE}


re="^(.*?) (.*?) (.*?)$"
[[ `${WORKSPACE}/getversion` =~ $re ]] && GP_VERSION="${BASH_REMATCH[1]}" && GP_BUILDNUMBER="${BASH_REMATCH[3]}" 

APR=apr-1.5.2
APR_UTIL=apr-util-1.5.4
OPENSSL=openssl-1.0.1r
READLINE=readline-6.3
NCURSES=ncurses-6.0
APR_TAR=${APR}.tar.gz
APR_UTIL_TAR=${APR_UTIL}.tar.gz
OPENSSL_TAR=${OPENSSL}.tar.gz
READLINE_TAR=${READLINE}.tar.gz
NCURSES_TAR=${NCURSES}.tar.gz

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

# Build additional directories we may need
for dir in BUILD RPMS SOURCES SPECS SRPMS
do
 [[ -d $dir ]] && rm -Rf $dir
  mkdir $dir
done

# Get external resources
wget http://ftp.jaist.ac.jp/pub/apache/apr/${APR_TAR}
tar -xf ${APR_TAR}
wget http://ftp.jaist.ac.jp/pub/apache/apr/${APR_UTIL_TAR}
tar -xf ${APR_UTIL_TAR}
wget ftp://ftp.openssl.org/source/${OPENSSL_TAR}
tar -xf ${OPENSSL_TAR}
wget http://ftp.gnu.org/gnu/ncurses/${NCURSES_TAR}
tar -xf ${NCURSES_TAR}
wget ftp://ftp.cwru.edu/pub/bash/${READLINE_TAR}
tar -xf ${READLINE_TAR}
wget https://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh

#Build APR
cd ${WORKSPACE}/${APR}
./configure --prefix=${GPDB_VERSION_PATH}
make
make install

#Build APR UTIL
cd ${WORKSPACE}/${APR_UTIL}
./configure --prefix=${GPDB_VERSION_PATH} --with-apr=${WORKSPACE}/${APR}
make
make install

#Build OpenSSL
cd ${WORKSPACE}/${OPENSSL}
./config --prefix=${GPDB_VERSION_PATH}
make
make install

#Build Ncurses
cd ${WORKSPACE}/${NCURSES}
./configure --prefix=${GPDB_VERSION_PATH} --with-shared
make
make install

#Build Readline
cd ${WORKSPACE}/${READLINE}
./configure --prefix=${GPDB_VERSION_PATH} --with-curses
make SHLIB_LIBS=-lncurses all shared
make install

#Build Conda
cd ${WORKSPACE}
chmod oug+x Miniconda-latest-Linux-x86_64.sh
./Miniconda-latest-Linux-x86_64.sh -b -f -p ${GPDB_VERSION_PATH}/ext/conda2
PYTHONHOME="${GPDB_VERSION_PATH}/ext/conda2"
PYTHONPATH=${GPDB_VERSION_PATH}/lib/python
PATH=$PYTHONHOME/bin:$PATH
pip install psi
pip install lockfile
pip install paramiko
pip install tools
pip install epydoc

echo "${GPDB_VERSION_PATH}/lib/" >> /etc/ld.so.conf.d/gpdb.conf
ldconfig

#Build GPDB base


cd ${WORKSPACE}
chmod oug+x configure
./configure --with-openssl --with-ldap --with-libcurl --prefix="${GPDB_VERSION_PATH}"
#./configure --with-openssl --with-ldap --with-libcurl --enable-orca --prefix="${GPDB_VERSION_PATH}"
make
make install

cd ${GPDB_VERSION_PATH}
sed "s#GPHOME=.*#GPHOME=${GPDB_VERSION_PATH}#g" greenplum_path.sh > greenplum_path.sh.updated
mv greenplum_path.sh.updated greenplum_path.sh
sed "s#ext/python#ext/conda2#g" greenplum_path.sh > greenplum_path.sh.updated
mv greenplum_path.sh.updated greenplum_path.sh
chmod oug+x greenplum_path.sh

source ${GPDB_VERSION_PATH}/greenplum_path.sh
cd ${WORKSPACE}/gpAux/extensions/orafce
make install USE_PGXS=1
cd ${WORKSPACE}/gpAux/extensions/gpmapreduce
make install
cd ${WORKSPACE}/gpAux/extensions/gpfdist
CFLAGS=-w ./configure --enable-transformations --prefix=${GPDB_VERSION_PATH} --with-apr-config=${GPDB_VERSION_PATH}/bin/apr-1-config
make
make install

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
