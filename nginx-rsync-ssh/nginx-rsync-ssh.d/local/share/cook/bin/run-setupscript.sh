#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# if setup script has been copied in, run it
if [ -f /root/setup.sh ]; then
    chmod +x /root/setup.sh
    /root/setup.sh
else
    echo "There is no /root/setup.sh file"
fi
