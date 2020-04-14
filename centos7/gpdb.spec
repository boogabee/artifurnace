#
# RPM spec file for GPDB
#

%define name            oss-greenplum-db
%define gpdbname        oss-greenplum-db
%define version         %{gpdb_ver}
%define release         %{gpdb_rel}%{?dist}
%define arch            x86_64
%define prefix          /opt/greenplum
%define installdir      /opt/greenplum/%{name}-%{version}
%define symlink         /opt/greenplum/%{name}
%define gpdbtarball     %{gpdbname}-%{version}-%{release}.%{arch}.tar.gz
%define __os_install_post %{___build_post}

Requires: shadow-utils
Requires: apr
Requires: apr-util
Requires: bash
Requires: bzip2
Requires: curl
Requires: krb5-devel
Requires: libcurl
Requires: libevent
Requires: libxml2
Requires: libyaml
Requires: zlib
Requires: openldap
Requires: openssh
Requires: openssl
Requires: perl
Requires: readline
Requires: rsync
Requires: sed
Requires: tar
Requires: zip
Requires: net-tools
Requires: less
Requires: openssh-clients
Requires: which
Requires: iproute
Requires: openssh-server
Requires: openssl-libs
Requires: python2-psutil
Requires: python-lockfile
Requires: libzstd

Summary:        OSS Greenplum DB
Name:           %{name}
Version:        %{version}
Release:        %{release}
License:        ASL 2.0
Group:          Applications/Databases
URL:            https://github.com/greenplum-db
BuildArch:      %{arch}
AutoReqProv:    no
BuildRoot:      %{_topdir}/temp
Prefix:         %{prefix}

%description
OSS Greenplum DB

%prep

%pre
if grep ^gpadmin: /etc/group >> /dev/null ; then
 : # group already exists
else
 %{_sbindir}/groupadd gpadmin
fi

if ! id gpadmin >& /dev/null; then
 %{_sbindir}/adduser gpadmin -g gpadmin -d /home/gpadmin
  echo 'source /opt/greenplum/oss-greenplum-db/greenplum_path.sh' >> /home/gpadmin/.bashrc
fi
exit 0


%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{prefix}
tar zxf %{_sourcedir}/%{gpdbtarball} -C $RPM_BUILD_ROOT/%{prefix}
cd $RPM_BUILD_ROOT%{prefix}
ln -s %{name}-%{version} %{name}

%clean
rm -rf $RPM_BUILD_ROOT

%files
%attr(755, gpadmin, gpadmin) %{installdir}
%attr(755, gpadmin, gpadmin) %{symlink}

%post
INSTDIR=$RPM_INSTALL_PREFIX0/%{name}-%{version}
# Update GPHOME in greenplum_path.sh
# Have to use sed to replace it into another file, and then move it back to greenplum_path.sh
# Made sure that even after this step, rpm -e removes greenplum_path.sh as well
sed "s#GPHOME=.*#GPHOME=${INSTDIR}#g" ${INSTDIR}/greenplum_path.sh > ${INSTDIR}/greenplum_path.sh.updated
mv ${INSTDIR}/greenplum_path.sh.updated ${INSTDIR}/greenplum_path.sh

