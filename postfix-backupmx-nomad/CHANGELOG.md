1.22

* Version bump for new base image

---

1.21

* Version bump for new base image
* Quote PATH statements

---

1.20

* Version bump for new base image

---

1.19

* Version bump for new base image 14.2

---

1.18

* Version bump for new base image

---

1.17

* Version bump for new base image 14.1
* Extra steps to trim image size

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

* Version bump for new base image

---

1.12

* Version bump for new base image

---

1.11

* Version bump for new base image
* FBSD14 base image

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

---

1.6

* Version bump for new base image

---

1.5

* Version bump for new base image

---

1.4

* Version bump for new base image
* Signified

---

1.3

* Version bump for new base image

---

1.2

* Version bump for new base image

---

1.1

* Version bump for new base image
* New changelog format

---

1.0.31

* Version bump for rebuild (no export last time)

---

1.0.30

* Version bump for rebuild

---

1.0.29

* Version bump for rebuild

---

1.0.28

* Version bump for rebuild

---

1.0.27

* Version bump for rebuild to fix missing images on potluck site

---

1.0.26

* Version bump for p3 rebuild

---

1.0.25

* Fix smtpdbanner variable expansion

---

1.0.24

* Exporting getopts vars, not working otherwise, nor passing in ENV values in nomad job

---

1.0.23

* Removing syslog-ng entirely, not working with nomad pots
* syslog-ng[12345]: Destination reliable queue full, dropping message; filename='/var/log/syslog-ng-disk-buffer/syslog-ng-00000.rqf', queue_len='0', mem_buf_size='134217728', disk_buf_size='2147483648', persist_name='afsocket_dd_qfile(stream,1.2.3.4:514)'

---

1.0.22

* Postfix wants aliases setup
* Using postalias as test

---

1.0.21

* Syslog-ng needs to be installed

---

1.0.20

* Fixing if statement from previous commit changes

---

1.0.19

* Version bump for rebuild
* Minor changes to avoid errors, like check for /root/.env.cook before sourcing it

---

1.0.18

* Add OPTIND around getopts
* Temp remove some recommended actions to disable sendmail actions (bug-chasing)

---

1.0.17

* Version bump for rebuild. Non-nomad image works.

---

1.0.16

* fixing copy-in to reflect postfix-backupmx-nomad flavour not freebsd-potluck

---

1.0.15

* Version bump for rebuild
* Minor changes, onedisbale for cook service

---

1.0.14

* Version bump for rebuild

---

1.0.13

* Version bump for rebuild

---

1.0.12

* Version bump for rebuild, new simple base image

---

1.0.11

* Version bump for rebuild, fixing workflow processes for layered image updates

---

1.0.10

* Version bump for rebuild
* Update nomad job image versions and freebsd version
* Tweaks to sendmail disable

---

1.0.9

* Fixing documentation for remotelog flag

---

1.0.8

* New format cook formula
* Syslog-ng instead of syslogd
* Mandatory paramaters

---

1.0.7

* Version bump for non-layered image round 2

---

1.0.6

* Version bump for non-layered image

---

1.0.5

* Version bump for FreeBSD-13.1 image

---

1.0.4

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

1.0.3

* Rebuild for FreeBSD 13 & new packages

---

1.0.2

* Apply epair0b patch from https://raw.githubusercontent.com/grembo/potman/master/flavours/example/example.sh

---

1.0.1

* Trigger build of FreeBSD 12.2 image & rebuild FreeBSD 11.4 image to update packages

---

1.0

* Tested version

---
0.9

* Initial commit, beta
