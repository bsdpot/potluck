#!/bin/sh

[ -w /etc/pkg/FreeBSD.conf ] && sed -i '' 's/quarterly/latest/' /etc/pkg/FreeBSD.conf
ASSUME_ALWAYS_YES=yes pkg bootstrap
touch /etc/rc.conf
sysrc sendmail_enable="NONE"
pkg install -y minio
mkdir /minio
sysrc minio_disks="/minio"
sysrc minio_user="root"
pkg clean -y
