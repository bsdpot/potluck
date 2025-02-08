#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# copy over backuppc.conf
cp -f "$TEMPLATEPATH/backuppc.conf.in" /usr/local/etc/apache24/Includes/backuppc.conf

# perform update
echo | sh /usr/local/etc/backuppc/update.sh

# update config
# shellcheck disable=SC2016
sed -i .bak 's|^\$Conf{SCGIServerPort}.*|\$Conf{SCGIServerPort} = 10268;|g' /usr/local/etc/backuppc/config.pl
# shellcheck disable=SC2016
sed -i .bak 's|^\$Conf{CgiAdminUsers}.*|\$Conf{CgiAdminUsers}     = \"*\";|g' /usr/local/etc/backuppc/config.pl
# shellcheck disable=SC2016
sed -i .bak 's|^\$Conf{CgiImageDirURL}.*|\$Conf{CgiImageDirURL} = \"\";|g' /usr/local/etc/backuppc/config.pl

# set permissions
if [ -d /usr/local/etc/backuppc/ ]; then
	chown -R backuppc:backuppc /usr/local/etc/backuppc/
fi

if [ -d /var/db/BackupPC/ ]; then
	chown -R backuppc:backuppc /var/db/BackupPC/
fi

# Change backuppc user to home directory for ssh keys file and fix .ssh permissions for files (possibly) having been copied in
chown -R backuppc:backuppc /home/backuppc/
chmod -R 700 /home/backuppc/.ssh
chmod 644 /home/backuppc/.ssh/*.pub || true
chmod 600 /home/backuppc/.ssh/id_rsa || true

# create master password
[ -w /etc/master.passwd ] && sed -i '' "s|BackupPC pseudo-user:/nonexistent|BackupPC pseudo-user:/home/backuppc|" /etc/master.passwd
pwd_mkdb -p /etc/master.passwd

# enable backuppc
service backuppc enable
