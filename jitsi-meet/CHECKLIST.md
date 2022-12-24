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
* `jitsi-meet.ini`
* `README.md` for example clone statement

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `jitsi-meet.ini`

## Shellcheck
Was `shellcheck` run on all applicable shell files?
