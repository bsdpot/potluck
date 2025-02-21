1.26

* Version bump for new base image

---

1.25

* Version bump for new base image
* Quote PATH statements

---

1.24

* Version bump for new base image
* Update to php83
* Update for rsync security issue
* Switch to latest repo as stress-ng missing from quarterlies

---

1.23

* Version bump for new base image 14.2

---

1.22

* Version bump for new base image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options

---

1.21

* Version bump for new base image
* Extra steps to trim image size
* Rebuild to test post 14.1 infrastructure upgrades

---

1.20

* Version bump for new base image
* FBSD 14.1

---

1.19

* Version bump for new base image
* Manually setup php-fpm rc file if not exist
* Adjust for php-fpm/php_fpm in RC service

---

1.18

* Version bump for new base image

---

1.17

* Version bump for new base image

---

1.16

* Version bump for new base image

---

1.15

* Version bump for new base image

---

1.14

* Version bump for new base image

---

1.13

* Version bump for new base image FBSD14
* Separate package installs to independent commands

---

1.12

* Version bump for new base image

---

1.11

* Version bump for new base image

---

1.10

* Version bump for new base image

---

1.9

* Version bump for new base image

---

1.8

* Version bump for new base image

---

1.7

* Version bump for new base image
* Fix syslog-ng problems for 4.2 version, remove stats_freq option
* Add local unbound and consul DNS services
* Update README with consul DNS info
* fix local_unbound dns resolution with missing parameters for access control
* Disable consul DNS option with local_unbound as only practical in VNET jails

---

1.6

* Version bump for new base image

---

1.5

* Verson bump for new base image
* Signified
* Fix nologin shell for nodeexport user

---

1.4

* Version increment for new feature
* Pass in consul servers as a comma-deliminated list

---

1.3

* Version bump for new base image
* Update syslog-ng.conf stats_freq(0); -> stats(freq(0));
* Version bump for rebuild after fixing build system problems

---

1.2

* Version bump for new base image

---

1.1

* Version bump for new base image

---

1.0

* New major release version 1.0.1
* Update CHANGELOG.md for major and minor version changes: X.Y.z
* Update potname.ini to x.y.Z for automated build processing
* Next version 1.0.2 will be a test of this functionality

---

0.0.21

* Fix consul client hcl for new format

---

0.0.20

* Version bump for rebuild to fix missing images on potluck site

---

0.0.19

* Version bump for p3 rebuild
* Add checklist

---

0.0.18

* Version bump for rebuild
* Trimming unnecessary items commented out
* INFO log level for consul

---

0.0.17

* Version bump for new base image
* Adjustments to cook for disabling in nomad and .env.cook

---

0.0.16

* Version bump to rebuild

---

0.0.15

* Version bump to rebuild, bugfixing base image issues

---

0.0.14

* Version bump to rebuild for latest base image

---


0.0.13

* php-json is now part of core php so removing broken pkg

---

0.0.12

* Version bump to test 13.1 layered images
* php74(-*) becomes php82(-*)

---

0.0.11

* Version bump

---

0.0.10

* Version bump

---

0.0.9

* Fix nginx paths

---

0.0.8

* Fix typo in README
* Fix typo in configure-nginx.sh script

---

0.0.7

* Web frontend to trigger 5m tests run as shell in background
* Removed sysbench for now, not going to use it
* This could be a stress-ng image but sticking with Traumadrill label for now

---

0.0.6

* Consul log directory fix

---

0.0.5

* Fixing copy in to use correct image name

---

0.0.4

* Yet another version bump to trigger a rebuild, last one

---

0.0.3

* Another version bump to trigger a rebuild

---

0.0.2

* Version bump to trigger a rebuild

---

0.0.1

* First bash at a pot jail with multiple tools for simulating system load
