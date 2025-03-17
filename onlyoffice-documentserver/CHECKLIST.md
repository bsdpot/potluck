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
* `onlyoffice-documentserver.ini`

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `onlyoffice-documentserver.ini`

## Python version changes
When python versions change, make sure to update `py311-supervisor` and `py311-setuptools` in
* `onlyoffice-documentserver.sh`

## Shellcheck
Was `shellcheck` run on all applicable shell files?
