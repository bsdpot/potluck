0.24

* Version bump for new base image

---

0.23

* Version bump for new base image
* Quote PATH statements

---

0.22

* Version bump for new base image
* Update for rsync security issue

---

0.21

* Version bump for new base image 14.2

---

0.20

* Version bump for new base image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options

---

0.19

* Version bump for new base image 14.1
* Extra steps to trim image size
* Fix issue with deprecated .Site.RSSLink

---

0.18

* Version bump for new base image

---

0.17

* Version bump for new base image

---

0.16

* Version bump for new base image

---

0.15

* Version bump for new base image

---

0.14

* Version bump for new base image
* Fix node_exporter zfs issue
* Add parameter to run mirrorsync script via cron

---

0.13

* Version bump for new base image
* FBSD14 base image

---

0.12

* Version bump for new base image
* Adjust minio-client client.json to config.json
* Add mirror to S3 script
* Fix typo in mkdir command
* Fix typo in local minio name myminio
* Update custom minio scripts
* Add package tmux
* Update minio scripts
* Refined minio scripts

---

0.11

* Version bump for new base image
* Add minio-client

---

0.10

* Version bump for new base image

---

0.9

* Version bump for new base image

---

0.8

* Version bump for new base image

---

0.7

* Version bump for new base image
* Fix syslog-ng problems for 4.2 version, remove stats_freq option
* Add local unbound and consul DNS services
* Update README with consul DNS info
* fix local_unbound dns resolution with missing parameters for access control
* Disable consul DNS option with local_unbound as is only practical in VNET jails with a localhost

---

0.6

* Version bump for new base image
* Rebuild to match jenkins versioning

---

0.5

* Version bump for new base image
* Signified
* Fix nologin shell for nodeexport user

---

0.4

* Version increment for new feature
* Pass in consul servers as a comma-deliminated list

---

0.3

* Version bump for new base image
* Update syslog-ng.conf stats_freq(0); -> stats(freq(0));
* Fix goaccess issues

---

0.2

* Version bump for new base image
* Fix documentation for missing parameters
* Add ports to consul config
* Adjust hugo-pre step to create new hugo site if not existing
* Fix git fatal error by moving step to add safe directory before git init step
* Adjust theme copy step
* Remove call to non-existent script configure-permissions.sh
* Bug-fixing git and hugo commands
* Fix typos in bug-fixes
* Fix goaccess config file location
* Include goaccess in pkg install
* Fix ongoing goaccess issues

---

0.1

* Version bump for new base image
* New changelog format

---

0.0.26

* Adding 'or true' where applicable for hugo steps

---

0.0.25

* Version bump for rebuild

---

0.0.24

* Add missing node_exporter installation

---

0.0.23

* Rebuild to fix consul error, fix consul.hcl for new format

---

0.0.22

* Version bump for rebuild to fix missing images on potluck site

---

0.0.21

* Version bump for p3 rebuild
* Add checklist

---

0.0.20

* Version bump for new base image, cook script

---

0.0.19

* Version bump for FreeBSD-13.1 image

---

0.0.18

* Adding customdir to gitignore and other tweaks

---

0.0.17

* Starting nginx before configuring goaccess. Setting git safedirectory

---

0.0.16

* Adjusting goaccess for custom goaccess.conf file

---

0.0.15

* Adding syslog-ng and remotelogs

---

0.0.14

* More permissions adjustment

---

0.0.13

* Permissions adjustments on mount in

---

0.0.12

* Addition of CUSTOMFILE parameter to extract customfile.tgz into SITENAME directory

---

0.0.11

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

0.0.10

* Fixing SSH access from jenkins or other

---

0.0.9

* Fixing directory permissions third time

---

0.0.8

* Fixing directory permissions second time

---

0.0.7

* Fixing directory perms on some hugo directories for remote user write access

---

0.0.6

* More adjustment to order of steps and removal unnecessary items

---

0.0.5

* Hugo site init wipes out a necessary directory creation, changing order of steps

---

0.0.4

* Including sample blog and microblog post generation

---

0.0.3

* Triggering another rebuild

---

0.0.2

* Triggering a rebuild

---

0.0.1

* First hugo-nginx pot image specific to the potluck.honeyguide.net site usage

---

0.0.0

* Initiate file

