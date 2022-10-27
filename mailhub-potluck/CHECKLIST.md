# Checklist for updates

## Version change
On a version change the following files need the version number updated:
* `CHANGELOG.md`
* `mailhub-potluck.ini`

## Quarterly Package Updates
Every new quarterly pkg release, update this line to next applicable quarter
```
git pull --depth=1 origin 2022Q4
```
in this file:
* mailhub-potluck.sh 

## Shellcheck
Was `shellcheck` run on all applicable shell files?
