# Checklist for updates

## Versioning
```
X.Y.Z / 1.0.1

X = Major version
Y = Minor version
Z = Build updates
```

## Major/minor revisions
On a version change the following files need the version number updated:
* `CHANGELOG.md`
* `backuppc-nomad.ini`
* example job in `README.md`

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `backuppc-nomad.ini`

## Shellcheck
Was `shellcheck` run on all applicable shell files?
