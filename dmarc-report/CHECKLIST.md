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
* `dmarc-report.ini`

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `dmarc-report.ini`

## Python updates
Make sure to update python39 and py39-{packagename} in the following files on Python version change:
* dmarc-report.sh

## Zincsearch
Zincsearch releases are on github at https://github.com/zincsearch/zincsearch/releases
For new releases the URL, and checksum of extracted binary, must be updated in:
* dmarc-report.sh

## Shellcheck
Was `shellcheck` run on all applicable shell files?
