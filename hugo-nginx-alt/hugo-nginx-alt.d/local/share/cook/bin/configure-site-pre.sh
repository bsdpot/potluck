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

# setup hugo pre-steps
cd /var/db || exit 1

# if no hugo site directories, then create a site
# testing, not clear if mandatory
if [ ! -f "/var/db/$SITENAME/hugo.yaml" ]; then
    /usr/local/bin/hugo new site "$SITENAME" --format yaml || true
fi

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# replace the hugo.yaml with our own
< "$TEMPLATEPATH/hugo.yaml.in" \
  sed "s${sep}%%domainname%%${sep}$DOMAINNAME${sep}g" | \
  sed "s${sep}%%title%%${sep}$TITLE${sep}g" | \
  sed "s${sep}%%language%%${sep}$LANGUAGE${sep}g" | \
  sed "s${sep}%%themename%%${sep}$THEMENAME${sep}g" \
  > /var/db/"$SITENAME"/hugo.yaml

# setup .gitignore, overwrite any existing
echo "$CUSTOMDIR/**" > "/var/db/$SITENAME/.gitignore"
echo ".customcontent/**" >> "/var/db/$SITENAME/.gitignore"

# make sure directories exist
mkdir -p "/var/db/$SITENAME/assets/css"
mkdir -p "/var/db/$SITENAME/assets/img"
mkdir -p "/var/db/$SITENAME/config/_default"
mkdir -p "/var/db/$SITENAME/content/blog"
mkdir -p "/var/db/$SITENAME/content/micro"
mkdir -p "/var/db/$SITENAME/layouts/partials/head"
mkdir -p "/var/db/$SITENAME/layouts/partials/header"
mkdir -p "/var/db/$SITENAME/static/fonts"

# set permissions, this needs some work
chmod 777 "/var/db/$SITENAME"
chmod g+s "/var/db/$SITENAME"
chmod 777 "/var/db/$SITENAME/assets"
chmod g+s "/var/db/$SITENAME/assets"
chmod 777 "/var/db/$SITENAME/assets/css"
chmod g+s "/var/db/$SITENAME/assets/css"
chmod 777 "/var/db/$SITENAME/assets/img"
chmod g+s "/var/db/$SITENAME/assets/img"
chmod 777 "/var/db/$SITENAME/config"
chmod g+s "/var/db/$SITENAME/config"
chmod 777 "/var/db/$SITENAME/config/_default"
chmod g+s "/var/db/$SITENAME/config/_default"
chmod 777 "/var/db/$SITENAME/content"
chmod g+s "/var/db/$SITENAME/content"
chmod 777 "/var/db/$SITENAME/content/blog"
chmod g+s "/var/db/$SITENAME/content/blog"
chmod 777 "/var/db/$SITENAME/content/micro"
chmod g+s "/var/db/$SITENAME/content/micro"
chmod 777 "/var/db/$SITENAME/layouts"
chmod g+s "/var/db/$SITENAME/layouts"
chmod 777 "/var/db/$SITENAME/layouts/partials"
chmod g+s "/var/db/$SITENAME/layouts/partials"
chmod 777 "/var/db/$SITENAME/layouts/partials/head"
chmod g+s "/var/db/$SITENAME/layouts/partials/head"
chmod 777 "/var/db/$SITENAME/layouts/partials/header"
chmod g+s "/var/db/$SITENAME/layouts/partials/header"
chmod 777 "/var/db/$SITENAME/static"
chmod g+s "/var/db/$SITENAME/static"
chmod 777 "/var/db/$SITENAME/static/fonts"
chmod g+s "/var/db/$SITENAME/static/fonts"

if [ -d "/var/db/$SITENAME/$CUSTOMDIR" ]; then
	chmod 777 "/var/db/$SITENAME/$CUSTOMDIR"
	chmod g+s "/var/db/$SITENAME/$CUSTOMDIR"
fi
