#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

# set permissions so jenkins user can write files from jenkins image
chmod 777 "/mnt/$SITENAME"
chmod g+s "/mnt/$SITENAME"
chmod 777 "/mnt/$SITENAME/$CUSTOMDIR"
chmod g+s "/mnt/$SITENAME/$CUSTOMDIR"
chmod 777 "/mnt/$SITENAME/content"
chmod g+s "/mnt/$SITENAME/content"
chmod 777 "/mnt/$SITENAME/content/blog"
chmod g+s "/mnt/$SITENAME/content/blog"
chmod 777 "/mnt/$SITENAME/content/micro"
chmod g+s "/mnt/$SITENAME/content/micro"
chmod 777 "/mnt/$SITENAME/static"
chmod g+s "/mnt/$SITENAME/static"

# link in /usr/local/www/SITENAME to /root/SITENAME
ln -s "/mnt/$SITENAME/public" "/usr/local/www/$SITENAME"
chown -R www:www "/mnt/$SITENAME"

# setup git
cd "/mnt/$SITENAME"
/usr/local/bin/git init
/usr/local/bin/git config user.email "$GITEMAIL"
/usr/local/bin/git config user.name "$GITUSER"
/usr/local/bin/git config --global --add safe.directory "/mnt/$SITENAME"
/usr/local/bin/git submodule add https://github.com/pavel-pi/kiss-em.git themes/kiss-em
/usr/local/bin/git add -v *

# copy across site icons and css
cp -r "/mnt/$SITENAME/themes/kiss-em/static/*" "/mnt/$SITENAME/static/"
