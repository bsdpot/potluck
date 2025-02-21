1.27

* Version bump for new base image

---

1.26

* Version bump for new base image

---

1.25

* Version bump for new base image
* Add parameters to fix issue with slapd failing to restart on reboot, because potnet overwrites changes /etc/hosts even when set not to
* Fix some shellcheck complaints on PATH
* Update to php83 version of packages, because dependency conflict with php82. Was dependent on php82 previously.
* Fix missed occurance of remoteldap with use remote pot name

---

1.24

* Version bump for new base image 14.2

---

1.23

* Version bump for new base image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options

---

1.22

* Version bump for new base image 14.1
* Extra steps to trim image size

---

1.21

* Version bump for new base image
* Adjust for php-fpm/php_fpm in RC service

---

1.20

* Version bump for new base image
* Add PHPLDAPAdmin tool
* Fix apache index page to LDAP tools

---

1.19

* Version bump for new base image

---

1.18

* Version bump for new base image

---

1.17

* Version bump for new base image

---

1.16

* Version bump for new base image
* FBSD14 base image
* Fix broken php packages
* Switch to using php-fpm
* Adjust apache24 config for php-fpm
* Increase php-fpm memory to 128MB to clear error and make LAM work again
* Include files to change for php socket on php version change
* Fix node_exporter ZFS error
* Adjust apache logging and send logs out with syslog-ng
* Improve openldap and LAM logging
* Improve ldap clustering setup with correct server-id parameters
* Fixing clustering setup and add entries to /etc/hosts
* Adjust openldap to use hostnames localldap and remoteldap set in /etc/hosts
* No trailing slash in ldap url for sysrc entry
* Openldap mirrormode parameter is now called multiprovider
* Adjust credentials setup because passwords are hashed or not hashed depending on config option
* Allow invalid certificates for ldap client programs
* Add script to test credentials added via LAM

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
* Fix syslog-ng problems for 4.2 version, remove stats_freq option
* Add local unbound for consul DNS resolution
* Minor change to consul agent config to use retry_join instead of start_join
* Add services to consul setup
* Fix addition of services
* Add consul DNS info to README
* fix local_unbound dns resolution with missing parameters for access control
* Disable consul DNS option with local_unbound as is only practical in VNET jails with a localhost
* Set www permissions on additional LAM subdirectories
* Adjustments to specify IP for LAM config files instead of localhost

---

1.10

* Version bump for new base image

---

1.9

* Version bump for new base image
* Signified
* Fix nologin shell for nodeexport user

---

1.8

* Version increment for new feature
* Pass consul servers in as comma-deliminated list

---

1.7

* Version bump for new base image
* Update syslog-ng.conf stats_freq(0); -> stats(freq(0));
* Remove quotes from variable as adjustment for list of consul servers to join

---

1.6

* Version bump for new base image
* add new parameters DEFAULTGROUPS USERNAME PASSWORD
* add default groups if no custom import
* add genericuser options and setup a generic user if set
* add missing php modules which need inclusion now
* Switch to php81 
* Fix sync password
* Access control for sync consumer read
* Re-do sync access control
* Fix access control, no olcAccess in slapd.conf
* New access control setup, to be tested
* Experimental: attempt sync config with replicator user automatically setup
* set ldap owner for self-signed certificates
* Missing dc= in slapd.conf ACLs
* Fix replicator user, avoid double-encrypting password, remove tmp files
* Correct sync dn to use uid not cn
* Adjust ACLs again
* Simplify ACLs, tested working sync
* Adjust ACLs to allow users access
* Remove double to in ACL

---

1.5

* Version bump for new base image
* New changelog format
* Fix rootdn access issues
* Add missing step to mkdir openldap-data in persistent storage
* Set apache servername to IP to avoid problems with unresolvable hostnames
* Optional parameter SERVERID, was under required
* Set ACL for root access via socket connection

---

1.4.6

* Adjust setup for persistent storage

---

1.4.5

* Update README to remove openldap24 reference

---

1.4.4

* Include rhash as crc32 application to calculate checksums on ldif files
* Update docs for changing password

---

1.4.3

* Update LAM unix.conf for list login

---

1.4.2

* Configure LAM automatically

---

1.4.1

* Add cron backups

---

1.4.0

* Version bump for rebuild

---

1.3.9

* Version bump for rebuild to fix missing images on potluck site

---

1.3.8

* Version bump for p3 rebuild

---

1.3.7

* Fix apache config file, missing close tag

---

1.3.6

* Update consul config for new format

---

1.3.5

* Update for openldap26 and general rebuild
* Add checklist

---

1.3.4

* Add optional parameter to import custom ldap data at end of cook script
* This is a repeat, yet seems necessary to avoid doing it manually on login

---

1.3.3

* Bug-fixing slapd config script

---

1.3.2

* Fixing up formatting issues with multisite slapd.conf

---

1.3.1

* Adding 'or true' to removing old files for slapd to avoid error out

---

1.3.0

* Fixing up openssl script with full paths

---

1.2.9

* Remove go install
* Add note about failure of openldap_exporter to build on freebsd

---

1.2.8

* Fix missing node_exporter install
* Add todo for openldap_exporter

---

1.2.7

* Version bump for new base image, cook script

---

1.2.6

* Version bump for FreeBSD-13.1 image

---

1.2.5

* Added syslog-ng and remote logging

---

1.2.4

* Capitilising header section in README for consistency

---

1.2.3

* Adding header and tags to README

---

1.2.2

* Fixing markdown in README

---

1.2.1

* Version bump

---

1.2

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

1.1

* Updated OpenLDAP image with mount-in persistent storage, multi-master server option

---

1.0.1

* First bash at OpenLDAP image

---

1.0.0

* Initial commit
