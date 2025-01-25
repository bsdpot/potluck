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
# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'


# create LAM config password from passed in parameter
SETLAMPASS=$(/usr/local/sbin/slappasswd -s "$LAMPASS")

## pre-configure LAM configuration
## advance planning for password complexity
## todo: mailserver
#< "$TEMPLATEPATH/lam.config.cfg.in" \
# sed "s${sep}%%configpassword%%${sep}$SETLAMPASS${sep}g" | \
# sed "s${sep}%%minpasslength%%${sep}$PASSLENGTH${sep}g" | \
# sed "s${sep}%%minpassupper%%${sep}$PASSUPPER${sep}g" | \
# sed "s${sep}%%minpasslower%%${sep}$PASSLOWER${sep}g" | \
# sed "s${sep}%%minpassnumber%%${sep}$PASSNUMBER${sep}g" | \
# sed "s${sep}%%minpasssymbol%%${sep}$PASSSYMBOL${sep}g" | \
# sed "s${sep}%%minpassclass%%${sep}$PASSCLASS${sep}g" \
#> /usr/local/www/lam/config/config.cfg
###
# pre-configure LAM configuration
< "$TEMPLATEPATH/lam.config.cfg.in" \
 sed "s${sep}%%configpassword%%${sep}$SETLAMPASS${sep}g" \
> /usr/local/www/lam/config/config.cfg

# pre-configure the addressbook template
# dc=%%mysuffix%%,dc=%%mytld%%
< "$TEMPLATEPATH/lam.addressbook.conf.in" \
 sed "s${sep}%%mysuffix%%${sep}$MYSUFFIX${sep}g" | \
 sed "s${sep}%%mytld%%${sep}$MYTLD${sep}g" | \
 sed "s${sep}%%ip%%${sep}$IP${sep}g" \
> /usr/local/www/lam/config/addressbook.conf

# preconfigure unix.conf
< "$TEMPLATEPATH/lam.unix.conf.in" \
 sed "s${sep}%%mysuffix%%${sep}$MYSUFFIX${sep}g" | \
 sed "s${sep}%%mytld%%${sep}$MYTLD${sep}g" | \
 sed "s${sep}%%ip%%${sep}$IP${sep}g" \
> /usr/local/www/lam/config/unix.conf

# preconfigure lam.conf
< "$TEMPLATEPATH/lam.lam.conf.in" \
 sed "s${sep}%%mysuffix%%${sep}$MYSUFFIX${sep}g" | \
 sed "s${sep}%%mytld%%${sep}$MYTLD${sep}g" | \
 sed "s${sep}%%ip%%${sep}$IP${sep}g" \
> /usr/local/www/lam/config/lam.conf

# preconfigure samba3.conf
< "$TEMPLATEPATH/lam.samba3.conf.in" \
 sed "s${sep}%%mysuffix%%${sep}$MYSUFFIX${sep}g" | \
 sed "s${sep}%%mytld%%${sep}$MYTLD${sep}g" | \
 sed "s${sep}%%ip%%${sep}$IP${sep}g" \
> /usr/local/www/lam/config/samba3.conf

# preconfigure windows_samba4.conf
< "$TEMPLATEPATH/lam.windows_samba4.conf.in" \
 sed "s${sep}%%mysuffix%%${sep}$MYSUFFIX${sep}g" | \
 sed "s${sep}%%mytld%%${sep}$MYTLD${sep}g" | \
 sed "s${sep}%%ip%%${sep}$IP${sep}g" \
> /usr/local/www/lam/config/windows_samba4.conf

# update permissions in web folder
chown -R www:wheel /usr/local/www/lam/config/
chown www:wheel /usr/local/www/lam/sess/
chown www:wheel /usr/local/www/lam/tmp/
