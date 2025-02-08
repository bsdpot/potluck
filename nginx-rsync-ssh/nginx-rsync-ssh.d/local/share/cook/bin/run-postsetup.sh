#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# if post setup script copied in, make executable and run
if [ -f /root/postsetup.sh ]; then
    chmod +x /root/postsetup.sh
    /root/postsetup.sh
else
    echo "There is no /root/postsetup.sh file"
fi
