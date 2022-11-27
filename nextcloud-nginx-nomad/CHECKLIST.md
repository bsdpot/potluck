# Checklist for updates

## Version change
On a version change the following files need the version number updated:
* `CHANGELOG.md`
* `nextcloud-nginx-nomad.ini`
* Example job in `README.md`

## PHP version changes
On PHP version changes, update the socket link `/var/run/php82-fpm.sock` to the new PHP version in files
* nextcloud-nginx-nomad.d/local/share/cook/templates/nginx.conf
* nextcloud-nginx-nomad.d/local/share/cook/templates/www.conf.in

Update the php82-* package installs in 
* nextcloud-nginx-nomad.sh
* nextcloud-nginx-nomad.d/local/share/cook/bin/install-nextcloud.sh

## Shellcheck
Was `shellcheck` run on all applicable shell files?
