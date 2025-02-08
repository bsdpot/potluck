#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# this will run an imported script copied into /root/customscript.sh
# if the file exists.
#
# This is useful if you want to perform additional steps after theme
# import
if [ -f /root/customscript.sh ]; then
    /bin/sh /root/customscript.sh || true
fi
