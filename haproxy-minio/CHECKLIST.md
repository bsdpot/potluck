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
* `haproxy-minio.ini`

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `haproxy-minio.ini`

## Changes in mariadb-client version
When `mariadb-client` version increments, make sure to update the package install command in:
* `haproxy-minio.sh`

## Shellcheck
Was `shellcheck` run on all applicable shell files?
