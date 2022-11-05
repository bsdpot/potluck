#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

# setup hugo pre-steps
cd /mnt
/usr/local/bin/hugo new site "$SITENAME" || true

# this has to happen after the force create of site as was wiping this
# make some directories from input variables
mkdir -p "/mnt/$SITENAME/$CUSTOMDIR/"

# setup .gitignore, overwrite any existing
echo "$CUSTOMDIR/**" > "/mnt/$SITENAME/.gitignore"
