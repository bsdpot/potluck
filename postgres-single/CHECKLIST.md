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
* `postgres-single.ini`

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `postgres-single.ini`

## New versions of postgresql
On new versions of postgresql, the postgres.conf.in file needs to be updated
* `postgres-single.d/local/share/cook/templates/postgres.conf.in`

## postgres_exporter
On new versions of `postgres_exporter` make sure to update the download link, version and checksum in:
* `postgres-single.sh`

## Shellcheck
Was `shellcheck` run on all applicable shell files?
