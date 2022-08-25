#!/bin/sh

ASSUME_ALWAYS_YES=yes pkg bootstrap
touch /etc/rc.conf
service sendmail onedisable
sysrc sshd_enable="YES"

echo myjailpassword | pw add user ffoxuser -h 0
mkdir /home/ffoxuser
chown ffoxuser /home/ffoxuser

pkg install -y xauth firefox
pkg clean -y
