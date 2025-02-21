2.25

* Version bump for new base image

---

2.24

* Version bump for new base image
* Fix consul labels and set IP parameters

---

2.23

* Version bump for new base image

---

2.22

* Version bump for new base image 14.2

---

2.21

* Version bump for new base image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options
 
---

2.20

* Version bump for new base image 14.1
* Extra steps to trim image size

---

2.19

* Version bump for new base image

---

2.18

* Version bump for new base image

---

2.17

* Version bump for new base image

---

2.16

* Version bump for new base image

---

2.15

* Version bump for new base image

---

2.14

* Version bump for new base image
* Fix node_exporter zfs error

---

2.13

* Version bump for base image
* FBSD14 base image

---

2.12

* Version bump for new base image

---

2.11

* Version bump for new base image

---

2.10

* Version bump for new base image

---

2.9

* Version bump for new base image

---

2.8

* Version bump for new base image

---

2.7

* Version bump for new base image
* Fix syslog-ng problems for 4.2 version, remove stats_freq option
* Add local unbound for consul DNS resolution
* Add services to consul setup
* Fix addition of services
* Add consul DNS info to README
* fix local_unbound dns resolution with missing parameters for access control
* Disable consul DNS option with local_unbound as is only practical in VNET jails with a localhost

---

2.6

* Version bump for new base image
* Add optional DISABLEUI parameter to disable web ui

---

2.5

* Version bump for new base image
* Signified
* Fix nologin shell for nodeexport user

---

2.4

* Version bump for functionality change
* Pass in cluster members in comma-deliminated format
* Rename PEERS parameter to CONSULSERVERS for consistency with other pot images

---

2.3

* Version bump for new base image
* Update syslog-ng.conf stats_freq(0); -> stats(freq(0));

---

2.2

* Version bump for new base image

---

2.1

* Version bump for new base image
* New version changelog file

---

2.0.27

* Version bump for rebuild

---

2.0.26

* Version bump for rebuild to fix missing images on potluck site

---

2.0.25

* Version bump for p3 rebuild

---

2.0.24

* Version bump for new consul version
* Checklist added

---

2.0.23

* Update consul agent.hcl for new setup tls options

---

2.0.22

* Make PEERS optional

---

2.0.21

* Consul is using http not https (see consul-tls for https)

---

2.0.20

* Version bump for new image and cook script

---

2.0.19

* Version bump for FreeBSD-13.1

---

2.0.18

* Switching to syslog-ng

---

2.0.17

* Changing approach with setting up remote syslog as variable not working

---

2.0.16

* Wrong fix, consul enable mixup with legacy sysrc entry

---

2.0.15

* Fixed bad character in README

---

2.0.14

* Rebuild due to workflow error

---

2.0.13

* Typos and formatting fixes

---

2.0.12

* Minor updates and rebuild for latest consul version

---

2.0.11

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

2.0.10

* Quoting gossip key encrypt section

---

2.0.9

* Removing vault components and encryption as covered in consul-tls image

---

2.0.8

* Adjusting consul service "node-exporter"

---

2.0.7

* Adding prometheus node_exporter and setting up consul to publish as service "node-exporter"

---

2.0.6

* Setup consul to use a default gossip encryption key

---

2.0.5

* Inclusion of consul-template and vault-agentl.hcl

---

2.0.4

* Minor fix (mainly directory creation)

---

2.0.3

* Rebuild for FreeBSD 13 & new packages

---

2.0.2

* Accepts BOOTSTRAP=1 for single server; and BOOTSTRAP=3 or BOOTSTRAP=5 provided correct PEERS variable set

---

2.0.1

* Fixed wrong "BOOTSTRAP"-escaping

---

2.0

* Updated to use latest flavour scripts, cluster enable

---

1.0.1

* Trigger build of FreeBSD 12.2 image & rebuild FreeBSD 11.4 image to update packages

---

1.0

* Initial commit
