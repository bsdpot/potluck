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
* `netbox.ini`

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `netbox.ini`

## Changes in Python version
Changes in python version need updating of `/usr/local/bin/python3.11` in the following files:
* `netbox.d/local/share/cook/bin/configure-netbox.sh`
* `netbox.d/local/share/cook/templates/netbox.rc.in`
* `netbox.d/local/share/cook/templates/netbox_rq.rc.in`
* `netbox.d/local/share/cook/bin/check-upgrade.sh`
* `netbox.d/local/share/cook/templates/850.netbox-housekeeping.in`

## Postgresql upgrades
This image has postgresql v16 installed and configured to store data in `/mnt/postgres/data/16/`.

For postgresql v17 and automatic upgrades, update pkg names, paths and values in
* `netbox.sh`
* `netbox.d/local/share/cook/bin/configure-postgres.sh`

There is no way to automatically upgrade old versions of the database without having binaries for old and new versions installed, so it's better to dump a backup and import to new setup.

## Shellcheck
Was `shellcheck` run on all applicable shell files?
