#
# RPM spec file for GPDB
#

%define name            apache-greenplum-db
%define gpdbname        apache-greenplum-db
%define version         %{gpdb_ver}
%define release         %{gpdb_rel}
%define arch            x86_64
%define prefix          /usr/local
%define installdir      /usr/local/%{name}-%{version}-%{release}
%define symlink         /usr/local/%{name}
%define gpdbtarball     %{gpdbname}-%{version}-%{release}-RHEL6-%{arch}.tar.gz

Requires(pre): shadow-utils

Summary:        GreenplumDB
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
Greenplum DB

%prep

%pre
if grep ^gpadmin: /etc/group >> /dev/null ; then
 : # group already exists
else
 %{_sbindir}/groupadd gpadmin
fi

if ! id gpadmin >& /dev/null; then
 %{_sbindir}/adduser gpadmin -g gpadmin -d /home/gpadmin
  echo 'source /usr/local/apache-greenplum-db/greenplum_path.sh' >> /home/gpadmin/.bashrc
fi
exit 0


%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{prefix}
tar zxf %{_sourcedir}/%{gpdbtarball} -C $RPM_BUILD_ROOT/%{prefix}
cd $RPM_BUILD_ROOT%{prefix}
ln -s %{name}-%{version}-%{release} %{name}

%clean
rm -rf $RPM_BUILD_ROOT

%files
%attr(755, gpadmin, gpadmin) %{installdir}
%attr(755, gpadmin, gpadmin) %{symlink}

%post
INSTDIR=$RPM_INSTALL_PREFIX0/%{name}-%{version}-%{release}
# Update GPHOME in greenplum_path.sh
# Have to use sed to replace it into another file, and then move it back to greenplum_path.sh
# Made sure that even after this step, rpm -e removes greenplum_path.sh as well
sed "s#GPHOME=.*#GPHOME=${INSTDIR}#g" ${INSTDIR}/greenplum_path.sh > ${INSTDIR}/greenplum_path.sh.updated
mv ${INSTDIR}/greenplum_path.sh.updated ${INSTDIR}/greenplum_path.sh

