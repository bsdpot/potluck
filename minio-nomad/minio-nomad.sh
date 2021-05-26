#!/bin/sh

ASSUME_ALWAYS_YES=yes pkg bootstrap
touch /etc/rc.conf
service sendmail onedisable
pkg install -y minio
mkdir /minio
sysrc minio_disks="/minio"
sysrc minio_user="root"
pkg clean -y
