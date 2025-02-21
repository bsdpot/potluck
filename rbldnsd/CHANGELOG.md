0.24

* Version bump for new base image

---

0.23

* Version bump for new base image
* Add quotes to PATH to fix shellcheck complaint
* Add scripts to check certificate validity and send alerts via alertmanager
* Include note in alerts that this image automatically renews certificates

---

0.22

* Version bump for new base image
* Update to php83
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

---

0.18

* Version bump for new base image
* Adjust for php-fpm/php_fpm in RC service

---

0.17

* Version bump for new base image
* Fix sources to use new git repo at https://github.com/borestad/blocklist-abuseipdb

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
* Update certificate renewal script

---

0.13

* Version bump for new base image
* FBSD14 base image

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
* Fix syslog-ng problems for 4.2 version, remove stats_freq option
* Add local unbound and consul DNS services
* Update README with consul DNS info
* Fix error in consul agent config
* fix local_unbound dns resolution with missing parameters for access control
* Disable consul DNS option with local_unbound as is only practical in VNET jails with a localhost
* Adjust acme.sh setup and renew scripts for '$domain_ecc' suffix which is default now
* Bug-fixing acme.sh changes

---

0.7

* Version bump for new base image

---

0.6

* Version bump for new base image
* Signified
* Fix nologin shell for nodeexport user

---

0.5

* Version increment for new feature
* Pass in consul servers as a comma-deliminated list

---

0.4

* Version bump for new base image
* Update syslog-ng.conf stats_freq(0); -> stats(freq(0));

---

0.3

* Version bump for new base image
* Revert to json format consul config
* Fix missing comma in agent.json
* Update README for sample query
* Add acme.sh and finalise nginx
* Fix errors in previous update
* Adjust acme certificates copy to ssl directory
* Fix nginx.conf brackets
* Adjust nginx config to fix index.php not showing as default
* Fix default index.php page to list tools
* Set temporary solution for lookup URI to direct to main page
* Update README to include default page
* Include abuseipdb in the linked lookups
* Tweak README

---

0.2

* Version bump for new base image

---

0.1

* First bash at a pot jail for rbldnsd
