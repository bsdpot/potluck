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
* `mailhub-potluck.ini`

## Automated build processing
To force a rebuild of the pot image for the potluck site, increment Z of version="x.y.Z" in:
* `mailhub-potluck.ini`

## Quarterly Package Updates
Every new quarterly pkg release, update this line to next applicable quarter
```
git pull --depth=1 origin 2024Q2
```
in this file:
* mailhub-potluck.sh 

### mysql-client
`databases/mysql80-client` pulled from git sources may need updating to a newer version between quarterly releases, in this file:
* mailhub-potluck.sh

## Switching between mail/%d/%n and mail/%n
If switching around mail_location settings to flip between `mail/{domain}/{username}/` and `mail/{username}/`, then comment/uncomment applicable sections, or edit variables in
* templates/dovecot.conf.in
* templates/sa-training.sh

## Shellcheck
Was `shellcheck` run on all applicable shell files?
