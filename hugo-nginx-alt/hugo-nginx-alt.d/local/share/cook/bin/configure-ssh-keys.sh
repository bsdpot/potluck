#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# create directories and set permissions
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys

if [ -f /root/sshkey ] && [ ! -f /root/.ssh/id_rsa ]; then
    cp /root/sshkey /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
    /usr/bin/ssh-keygen -f /root/.ssh/id_rsa -y > /root/.ssh/id_rsa.pub
fi

# enable quick access to git host
if [ -f /root/.ssh/known_hosts ]; then
	/usr/bin/ssh-keygen -R "$GITHOST" || true
fi
/usr/bin/ssh-keyscan -H "$GITHOST" >> /root/.ssh/known_hosts

# setup ssh/config file with username
cat >>/root/.ssh/config<<EOF
Host githost
  HostName "$GITHOST"
  Port "$SETGITPORT"
  User git
  IdentityFile /root/.ssh/id_rsa
  StrictHostKeyChecking=accept-new
EOF

# remove the copied in key if it exists
if [ -f /root/sshkey ]; then
	rm -r /root/sshkey
fi

# end
