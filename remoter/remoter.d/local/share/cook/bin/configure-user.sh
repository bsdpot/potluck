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

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# setup a user
/usr/sbin/pw useradd -n "$SSHUSER" -c 'remoter ssh user' -d "/mnt/home/$SSHUSER" -m -s /bin/sh -h -

# configure ssh user ssh keys
mkdir -p "/mnt/home/$SSHUSER/.ssh"

# set authorized_keys if not exist
if [ -f "/root/authorized_keys_in" ]; then
	if [ -f "/mnt/home/$SSHUSER/.ssh/authorized_keys" ]; then
		echo "authorized_keys already exists at the destination. Skipping copy."
	else
		cat "/root/authorized_keys_in" > "/mnt/home/$SSHUSER/.ssh/authorized_keys"
		# set permissions
		chown -R "$SSHUSER:$SSHUSER" "/mnt/home/$SSHUSER/.ssh"
		chmod 600 "/mnt/home/$SSHUSER/.ssh/authorized_keys"
		chmod 700 "/mnt/home/$SSHUSER/.ssh"
	fi
else
	exit_error "No /root/authorized_keys_in file found"
fi

# create minio client directory
mkdir -p "/mnt/home/$SSHUSER/.minio-client"

# minio actually wants config.json not client.json
# setting for destination
< "$TEMPLATEPATH/client.json.in" \
  sed "s${sep}%%buckethost%%${sep}$BUCKETHOST${sep}g" | \
  sed "s${sep}%%bucketuser%%${sep}$BUCKETUSER${sep}g" | \
  sed "s${sep}%%bucketpass%%${sep}$BUCKETPASS${sep}g" \
  > "/mnt/home/$SSHUSER/.minio-client/config.json"

# set permissions
chown -R "$SSHUSER:$SSHUSER" "/mnt/home/$SSHUSER/.minio-client"

# create files/BUCKET directory
mkdir -p "/mnt/home/$SSHUSER/files/$BUCKET"
chown -R "$SSHUSER:$SSHUSER" "/mnt/home/$SSHUSER/files"

# make sure there is a bin directory
mkdir -p "/mnt/home/$SSHUSER/bin"
chown -R "$SSHUSER:$SSHUSER" "/mnt/home/$SSHUSER/bin"

# create a logs directory
mkdir -p "/mnt/home/$SSHUSER/logs"
chown -R "$SSHUSER:$SSHUSER" "/mnt/home/$SSHUSER/logs"

# configure postgresql credentials
echo "$DBHOST:$SETDBPORT:$DATABASE:$DBUSER:$DBPASS" > "/mnt/home/$SSHUSER/.pgpass"
chown "$SSHUSER:$SSHUSER" "/mnt/home/$SSHUSER/.pgpass"
# permissions should be u=rw (0600) or less
chmod 600 "/mnt/home/$SSHUSER/.pgpass"

# copy in postgresql backup script
< "$TEMPLATEPATH/pgbak.sh.in" \
  sed "s${sep}%%database%%${sep}$DATABASE${sep}g" | \
  sed "s${sep}%%dbhost%%${sep}$DBHOST${sep}g" | \
  sed "s${sep}%%setdbport%%${sep}$SETDBPORT${sep}g" | \
  sed "s${sep}%%dbuser%%${sep}$DBUSER${sep}g" | \
  sed "s${sep}%%sshuser%%${sep}$SSHUSER${sep}g" \
  > "/mnt/home/$SSHUSER/bin/pgbak.sh"

# set permissions
chown -R "$SSHUSER:$SSHUSER" "/mnt/home/$SSHUSER/bin"
chmod +x "/mnt/home/$SSHUSER/bin/pgbak.sh"

# copy in minio sync scripts

# copy in mirroraccounts.sh
< "$TEMPLATEPATH/mirroraccounts.sh.in" \
  sed "s${sep}%%bucket%%${sep}$BUCKET${sep}g" | \
  sed "s${sep}%%sshuser%%${sep}$SSHUSER${sep}g" \
  > "/mnt/home/$SSHUSER/bin/mirroraccounts.sh"

# set permissions
chown -R "$SSHUSER:$SSHUSER" "/mnt/home/$SSHUSER/bin"
chmod +x "/mnt/home/$SSHUSER/bin/mirroraccounts.sh"

# copy in mirrorattachments.sh
< "$TEMPLATEPATH/mirrorattachments.sh.in" \
  sed "s${sep}%%bucket%%${sep}$BUCKET${sep}g" | \
  sed "s${sep}%%sshuser%%${sep}$SSHUSER${sep}g" \
  > "/mnt/home/$SSHUSER/bin/mirrorattachments.sh"

# set permissions
chown -R "$SSHUSER:$SSHUSER" "/mnt/home/$SSHUSER/bin"
chmod +x "/mnt/home/$SSHUSER/bin/mirrorattachments.sh"

# copy in mirroruploads.sh
< "$TEMPLATEPATH/mirroruploads.sh.in" \
  sed "s${sep}%%bucket%%${sep}$BUCKET${sep}g" | \
  sed "s${sep}%%sshuser%%${sep}$SSHUSER${sep}g" \
  > "/mnt/home/$SSHUSER/bin/mirroruploads.sh"

# set permissions
chown -R "$SSHUSER:$SSHUSER" "/mnt/home/$SSHUSER/bin"
chmod +x "/mnt/home/$SSHUSER/bin/mirroruploads.sh"

# set crontab entries for scripts in one go, else overwrites previous entries
cat <<EOF | crontab -u "$SSHUSER" -
0 1 * * * /mnt/home/$SSHUSER/bin/pgbak.sh
0 2 * * * /mnt/home/$SSHUSER/bin/mirroraccounts.sh
0 3 * * * /mnt/home/$SSHUSER/bin/mirrorattachments.sh
0 4 * * * /mnt/home/$SSHUSER/bin/mirroruploads.sh
EOF
