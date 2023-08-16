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
* `mariadb-galera.ini`

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `mariadb-galera.ini`

## Galera and Mariadb versions
When updating galera and mariadb versions, make sure to edit the pkg install line in:
* `mariadb-galera.sh`

## Shellcheck
Was `shellcheck` run on all applicable shell files?
