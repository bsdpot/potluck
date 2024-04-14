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
* `opensearch.ini`

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `opensearch.ini`

Take note this image is not a layered image. 

Do not build this image with other images. Do it independently. Takes a long time.

## Java updates
Make sure to update openjdk version in the following files on version change:
* opensearch.sh

## Shellcheck
Was `shellcheck` run on all applicable shell files?
