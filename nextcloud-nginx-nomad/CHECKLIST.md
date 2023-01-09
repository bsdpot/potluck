# Checklist for updates

## Versioning
```
X.Y.Z / 1.0.1

X = Major version
Y = Minor version
Z = Build updates
```

## Major/minor revisions
Changes to major or minor versions need to be logged in:
* `CHANGELOG.md`
* `nextcloud-nginx-nomad.ini`
* Example job in `README.md`

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `nextcloud-nginx-nomad.ini`

## PHP version changes
On PHP version changes, update the socket link `/var/run/php81-fpm.sock` to the new PHP version in files
* nextcloud-nginx-nomad.d/local/share/cook/templates/nginx.conf
* nextcloud-nginx-nomad.d/local/share/cook/templates/www.conf.in

Update the php81-* package installs in 
* nextcloud-nginx-nomad.sh
* nextcloud-nginx-nomad.d/local/share/cook/bin/install-nextcloud.sh

## Shellcheck
Was `shellcheck` run on all applicable shell files?
