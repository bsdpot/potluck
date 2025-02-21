1.28

* Version bump for new base image

---

1.27

* Version bump for new base image
* Quote PATH statements
* Fix consul labels and set IP parameters, set 127.0.0.1 only for consul client_addr

---

1.26

* Version bump for new base image

---

1.25

* Version bump for new base image 14.2

---

1.24

* Version bump for new base image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options

---

1.23

* Version bump for new base image 14.1
* Extra steps to trim image size

---

1.22

* Version bump for new base image

---

1.21

* Version bump for new base image

---

1.20

* Version bump for new base image

---

1.19

* Version bump for new base image

---

1.18

* Version bump for new base image

---

1.17

* Version bump for new base image
* Fix node_exporter zfs issue

---

1.16

* Version bump for new base image
* FBSD14 base image

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

---

1.10

* Version bump for new base image
* Fix syslog-ng problems for 4.2 version, remove stats_freq option
* Add DISABLEGUI option, defaults to unset
* Add local unbound for consul DNS resolution
* Minor change to consul agent config to use retry_join instead of start_join
* Add services to consul setup
* Fix addition of services
* Add consul DNS info to README
* fix local_unbound dns resolution with missing parameters for access control
* Disable consul DNS option with local_unbound as is only practical in VNET jails with a localhost

---

1.9

* Version bump for new base image

---

1.8

* Version bump for new base image
* Signified
* Fix nologin shell for nodeexport user

---

1.7

* Version increment for new feature
* Pass consul servers in as comma-deliminated list

---

1.6

* Version bump for new base image
* Update syslog-ng.conf stats_freq(0); -> stats(freq(0));

---

1.5

* Version bump for new base image

---

1.4

* Version bump for new base image
* New changelog format

---

1.3.5

* Fix consul client hcl for new format

---

1.3.4

* Version bump for rebuild to fix missing images on potluck site

---

1.3.3

* Version bump for p3 rebuild

---

1.3.2

* Version bump for rebuild
* Added checklist

---

1.3.1

* Version bump for new base image and new cook script format

---

1.3.0

* Version bump for FreeBSD-13.1 image

---

1.2.9

* Switch to syslog-ng. Include traefik logs in syslog-ng. Update to modern base script.

---

1.2.8

* Changing method for remote syslog as variable wasn't expanding

---

1.2.7

* Implementing prometheus metrics and other minor tweaks. Updating README.

---

1.2.6

* traefik service not enabled, reverting earlier change

---

1.2.5

* Rebuild for latest version and adding remotelogs

---

1.2.4

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

1.2.3

* Rebuild for FreeBSD 13 & new packages

---

1.2.2

* Install traefik instead of traefik2 since the traefik pkg is now v2

---

1.2.1

* Trigger build of FreeBSD 12.2 image & rebuild FreeBSD 11.4 image to update packages

---

1.2

* Moved from traefik to traefik2 port
* Support mounting of traefik log directory to persist access logs

---

1.1

* Added HTTPS with self signed certificate (port 8443)

---

1.0

* Initial commit
