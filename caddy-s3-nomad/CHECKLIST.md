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
* `caddy-s3-nomad.ini`
* Example job in `README.md`

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `caddy-s3-nomad.ini`

## Go Version
When `go` version changes updated the package install line and git sparse checkout lines in:
* `caddy-s3-nomad.sh`

## Quarterly Package Updates
Every new quarterly pkg release, update this line to next applicable quarter
```
git pull --depth=1 origin 2024Q3
```
in:
* `caddy-s3-nomad.sh`

## Shellcheck
Was `shellcheck` run on all applicable shell files?
