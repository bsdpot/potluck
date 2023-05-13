#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

mkdir -p /root/dmarc-report

git clone https://github.com/hitalos/dmarc-report /root/dmarc-report

cd /root/dmarc-report || exit 1

npm i --only=production || true

npm audit fix --force || true

# we'll use this process manager to start the app and background it
npm install pm2 -g || true

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy in custom .env file
< "$TEMPLATEPATH/env.in" \
  sed "s${sep}%%imapserver%%${sep}$IMAPSERVER${sep}g" | \
  sed "s${sep}%%imapuser%%${sep}$IMAPUSER${sep}g" | \
  sed "s${sep}%%imappass%%${sep}$IMAPPASS${sep}g" | \
  sed "s${sep}%%imapfolder%%${sep}$IMAPFOLDER${sep}g" | \
  sed "s${sep}%%serverport%%${sep}$SERVERPORT${sep}g" \
  > /root/dmarc-report/.env

# start with process manager
#npm start || true
pm2 --name dmarc-report start npm -- start || true

echo "To stop a backgrounded node app, please run:"
echo ""
echo "  pm2 delete 0"
echo ""
