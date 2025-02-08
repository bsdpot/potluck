#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# setup hugo pre-steps
cd /mnt

# if no hugo site directories, then create a site
# testing, not clear if mandatory
if [ ! -f "/mnt/$SITENAME/config.toml" ]; then
    /usr/local/bin/hugo new site "$SITENAME" || true
fi

# this has to happen after the force create, as this directory was getting wiped
# this is pot a mount-in now
# make some directories from input variables
mkdir -p "/mnt/$SITENAME/$CUSTOMDIR/"

# setup .gitignore, overwrite any existing
echo "$CUSTOMDIR/**" > "/mnt/$SITENAME/.gitignore"
