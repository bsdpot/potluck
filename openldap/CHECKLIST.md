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
* `openldap.ini`

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `openldap.ini`

## PHP version changes
Update the pkg install commands in the following file. Current version is php83-*
* `openldap.sh`

Make sure to change the php socket filename in
* `openldap.d/local/share/cook/templates/httpd.conf.in`
* `openldap.d/local/share/cook/templates/www.conf.in`

## Shellcheck
Was `shellcheck` run on all applicable shell files?
