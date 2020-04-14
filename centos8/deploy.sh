#!/bin/sh

set -e

LAUNCH_DIR=`pwd`
export WORKSPACE=/opt/gpdbdeploy/


yum -y clean all
yum -y swap fakesystemd systemd

yum -y install openssh-server openssh-server-sysvinit openssh-clients which tar hostname initscripts net-tools
/etc/init.d/sshd start 

hostname ${HOSTNAME}

cd ${LAUNCH_DIR}/output/
rpm --install *.rpm


#Make ping process run as root so it can access network capabilities
chmod 4755 /bin/ping
chmod 4755 /bin/ping6

mkdir -p /data/master
mkdir -p /data/seg1
mkdir -p /data/seg2

echo ${HOSTNAME} >> /data/hostlist_singlenode

echo 'ARRAY_NAME="GPDB SINGLENODE"' >> /data/gpinitsystem_singlenode
echo 'MACHINE_LIST_FILE=/data/hostlist_singlenode' >> /data/gpinitsystem_singlenode
echo 'SEG_PREFIX=gpsne' >> /data/gpinitsystem_singlenode
echo 'PORT_BASE=40000' >> /data/gpinitsystem_singlenode
echo 'declare -a DATA_DIRECTORY=(/data/seg1 /data/seg2)' >> /data/gpinitsystem_singlenode
echo "MASTER_HOSTNAME=${HOSTNAME}" >> /data/gpinitsystem_singlenode
echo 'MASTER_DIRECTORY=/data/master' >> /data/gpinitsystem_singlenode
echo 'MASTER_PORT=5432' >> /data/gpinitsystem_singlenode
echo 'TRUSTED_SHELL=ssh' >> /data/gpinitsystem_singlenode
echo 'CHECK_POINT_SEGMENTS=8' >> /data/gpinitsystem_singlenode
echo 'ENCODING=UNICODE' >> /data/gpinitsystem_singlenode

echo 'kernel.shmmax = 500000000' >> /etc/sysctl.conf
echo 'kernel.shmmni = 4096' >> /etc/sysctl.conf
echo 'kernel.shmall = 4000000000' >> /etc/sysctl.conf
echo 'kernel.sem = 250 512000 100 2048' >> /etc/sysctl.conf
echo 'kernel.sysrq = 1' >> /etc/sysctl.conf
echo 'kernel.core_uses_pid = 1' >> /etc/sysctl.conf
echo 'kernel.msgmnb = 65536' >> /etc/sysctl.conf
echo 'kernel.msgmax = 65536' >> /etc/sysctl.conf
echo 'kernel.msgmni = 2048' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_syncookies = 1' >> /etc/sysctl.conf
echo 'net.ipv4.ip_forward = 0' >> /etc/sysctl.conf
echo 'net.ipv4.conf.default.accept_source_route = 0' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_tw_recycle = 1' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog = 4096' >> /etc/sysctl.conf
echo 'net.ipv4.conf.all.arp_filter = 1' >> /etc/sysctl.conf
echo 'net.ipv4.ip_local_port_range = 1025 65535' >> /etc/sysctl.conf
sysctl -p

echo '* soft nofile 65536' >> /etc/security/limits.conf
echo '* hard nofile 65536' >> /etc/security/limits.conf
echo '* soft nproc 131072' >> /etc/security/limits.conf
echo '* hard nproc 131072' >> /etc/security/limits.conf

chown -R gpadmin /data/

cat /data/hostlist_singlenode
cat /data/gpinitsystem_singlenode

su gpadmin -l -c "gpssh-exkeys -f /data/hostlist_singlenode"
#Debugging version
#su gpadmin -l -c "bash -x /usr/local/apache-greenplum-db/bin/gpinitsystem -a -D -c /data/gpinitsystem_singlenode"
su gpadmin -l -c "gpinitsystem -a -D -c /data/gpinitsystem_singlenode"
su gpadmin -l -c "echo 'export MASTER_DATA_DIRECTORY=/data/master/gpsne-1/' >> /home/gpadmin/.bashrc"
su gpadmin -l -c "gpstop -a"
