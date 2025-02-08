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
Changes in python version need updating of package name, or `/usr/local/bin/python3.11`, in the following files:
* `netbox.sh`
* `netbox.d/local/share/cook/bin/configure-netbox.sh`
* `netbox.d/local/share/cook/templates/netbox.rc.in`
* `netbox.d/local/share/cook/templates/netbox_rq.rc.in`
* `netbox.d/local/share/cook/bin/check-upgrade.sh`
* `netbox.d/local/share/cook/templates/850.netbox-housekeeping.in`

## Changes in netbox version and python pip installs
Netbox is currently version 4.1.10.

When netbox version changes in packages, then update `netbox.sh` to correct version after checking compatibility chart at each link
* `pkg install -y netbox-4.1.11`
* `netbox-inventory==2.2.1` see Compatibility at https://github.com/ArnesSI/netbox-inventory
* `netbox-bgp==0.14.0` see Compatibility at https://github.com/netbox-community/netbox-bgp
* `netbox-topology-views==4.1.0` see Versions at https://github.com/netbox-community/netbox-topology-views

## Shellcheck
Was `shellcheck` run on all applicable shell files?
