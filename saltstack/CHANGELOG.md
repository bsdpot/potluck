0.24

* Version bump for new base image

---

0.23

* Version bump for new base image
* Quote PATH statements

---

0.22

* Version bump for new base image

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
* Rebuild for reverted py39-salt package (version 3006) which still works on FreeBSD

---

0.13

* Version bump for new base image
* FBSD14 base image
* Make sure py39-tornado is installed

---

0.12

* Version bump for new base image

---

0.11

* Version bump for new base image

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

---

0.5

* Version bump for new base image
* Signified
* Fix nologin shell for nodeexport user
* Remove existing ssh key for user-configured saltuser if exists
* Adjust formatting of parameters in README
* Fix services start for sshd and node_exporter

---

0.4

* Version increment for new feature
* Pass in consul servers as a comma-deliminated list
* Remove invalid ENABLECONSUL

---

0.3

* Version bump for new base image
* Update syslog-ng.conf stats_freq(0); -> stats(freq(0));

---

0.2

* Version bump for new base image

---

0.1

* Version bump for new base image
* New changelog format

---

0.0.11

* Fix consul client hcl for new format

---

0.0.10

* Version bump for rebuild to fix missing images on potluck site

---

0.0.9

* Version bump for p3 rebuild

---

0.0.8

* Version bump for new base image, cook script

---

0.0.7

* Version bump for FreeBSD-13.1 image

---

0.0.6

* Including salt-lint installed via pip

---

0.0.5

* Adding syslog-ng and remote logging

---

0.0.4

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

0.0.3

* Adding gossip key to consul config

---

0.0.2

* Updates for primary key management and simple multi-master implementation

---

0.0.1

* First saltstack image

---

0.0

* initiate file
