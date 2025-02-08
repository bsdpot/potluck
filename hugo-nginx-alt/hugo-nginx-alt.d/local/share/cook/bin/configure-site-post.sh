#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# link in /usr/local/www/SITENAME to /var/db/SITENAME
ln -s "/var/db/$SITENAME/public" "/usr/local/www/$SITENAME"
chown -R www:www "/var/db/$SITENAME"

# setup git
cd "/var/db/$SITENAME" || exit 1
# git init complains about dubious ownership and gives an error. whitelist the directory
/usr/local/bin/git config --global --add safe.directory "/var/db/$SITENAME" || true
/usr/local/bin/git init || true
/usr/local/bin/git config --replace-all user.email "$GITEMAIL" || true
/usr/local/bin/git config --replace-all user.name "$GITUSER" || true

# add content as submodule
if [ -n "$CONTENTSRC" ]; then
	/usr/local/bin/git submodule add "$CONTENTSRC" .customcontent || true
	#/usr/local/bin/git submodule update --init --recursive || true
	/usr/local/bin/git config -f .gitmodules submodule.customcontent.update merge || true
fi

# add theme as submodule
/usr/local/bin/git submodule add --depth=1 "$THEMESRC" themes/"$THEMENAME" || true
# from papermod theme install guide
/usr/local/bin/git submodule update --init --recursive || true
# set git config settings
# removing for now
# /bin/sh -c "cd /var/db/$SITENAME/themes; /usr/local/bin/git config -f .gitmodules submodule.$THEMENAME.update merge"

# shellcheck disable=SC2035
/usr/local/bin/git add -v *

# copy across site icons and css
# shellcheck disable=SC2035
if [ -d "/var/db/$SITENAME/themes/$THEMENAME/static/" ] && [ -d "/var/db/$SITENAME/static/" ]; then
    cp -Rf "/var/db/$SITENAME/themes/$THEMENAME/static/" "/var/db/$SITENAME/static/"
fi

# copy custom content if exists, move after theme site icons and css copied
if [ -n "$CONTENTSRC" ]; then
	if [ -d "/var/db/$SITENAME/.customcontent/assets" ]; then
		cp -Rf "/var/db/$SITENAME/.customcontent/assets/" "/var/db/$SITENAME/assets/"
	fi
	if [ -d "/var/db/$SITENAME/.customcontent/config" ]; then
		cp -Rf "/var/db/$SITENAME/.customcontent/config/" "/var/db/$SITENAME/config/"
	fi
	if [ -d "/var/db/$SITENAME/.customcontent/content" ]; then
		cp -Rf "/var/db/$SITENAME/.customcontent/content/" "/var/db/$SITENAME/content/"
	fi
	if [ -d "/var/db/$SITENAME/.customcontent/layouts" ]; then
		cp -Rf "/var/db/$SITENAME/.customcontent/layouts/" "/var/db/$SITENAME/layouts/"
	fi
	if [ -d "/var/db/$SITENAME/.customcontent/static" ]; then
		cp -Rf "/var/db/$SITENAME/.customcontent/static/" "/var/db/$SITENAME/static/"
	fi
fi

# set permissions again
chown -R www:www "/var/db/$SITENAME"
