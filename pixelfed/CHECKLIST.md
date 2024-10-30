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
* `pixelfed.ini`

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `pixelfed.ini`

## PHP version changes
On PHP version changes, update the socket link `/var/run/php82-fpm.sock` to the new PHP version in files:
* `pixelfed.d/local/share/cook/templates/nginx.conf.in`
* `pixelfed.d/local/share/cook/templates/www.conf.in`

And update package versions in:
* `pixelfed.sh`

## Pixelfed version changes
On Pixelfed release changes, update to the applicable commit in:
* `pixelfed.sh`

## Shellcheck
Was `shellcheck` run on all applicable shell files?
