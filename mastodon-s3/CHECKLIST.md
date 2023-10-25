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
* `mastodon-s3.ini`

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `mastodon-s3.ini`

## New versions of Mastodon
When updating to new versions of Mastodon, be sure to update the version (4.2.1) in the git checkout statement in:
* mastodon-s3.d/local/share/cook/bin/configure-mastodon.sh

## Shellcheck
Was `shellcheck` run on all applicable shell files?
