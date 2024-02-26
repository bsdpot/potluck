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

# if no hugo site directories, then create a site
# testing, not clear if mandatory
if [ ! -f "/mnt/$SITENAME/config.toml" ]; then
    /usr/local/bin/hugo new site "$SITENAME" || true
fi

# setup .gitignore, overwrite any existing
echo "$CUSTOMDIR/**" > "/mnt/$SITENAME/.gitignore"

# make sure directories exist
mkdir -p "/mnt/$SITENAME/content/blog"
mkdir -p "/mnt/$SITENAME/content/micro"
mkdir -p "/mnt/$SITENAME/static"

# set permissions so jenkins user can write files from jenkins image
chmod 777 "/mnt/$SITENAME"
chmod g+s "/mnt/$SITENAME"
chmod 777 "/mnt/$SITENAME/content"
chmod g+s "/mnt/$SITENAME/content"
chmod 777 "/mnt/$SITENAME/content/blog"
chmod g+s "/mnt/$SITENAME/content/blog"
chmod 777 "/mnt/$SITENAME/content/micro"
chmod g+s "/mnt/$SITENAME/content/micro"
chmod 777 "/mnt/$SITENAME/static"
chmod g+s "/mnt/$SITENAME/static"

if [ -d "/mnt/$SITENAME/$CUSTOMDIR" ]; then
	chmod 777 "/mnt/$SITENAME/$CUSTOMDIR"
	chmod g+s "/mnt/$SITENAME/$CUSTOMDIR"
fi
