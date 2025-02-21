2.14

* Version bump for new base image

---

2.13

* Version bump for new base image
* Quote PATH statements
* Add certificate expiry with alerts to alertmanager

---

2.12

* Version bump for new base image
* Update for rsync security issue

---

2.11

* Version bump for new base image 14.2

---

2.10

* Version bump for new base image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options

---

2.9

* Version bump for new base image 14.1
* Extra steps to trim image size

---

2.8

* Version bump for new base image

---

2.7

* Version bump for new base image

---

2.6

* Version bump for new base image
* Python is now py311

---

2.5

* Version bump for new base image

---

2.4

* Version bump for new base image
* Fix node_exporter zfs issue
* Set owner synapse for /usr/local/etc/matrix-synapse/DOMAIN.signing.key
* Update certificate renewal script

---

2.3

* Version bump for new base image
* FBSD14 base image

---

2.2

* Version bump for new base image

---

2.1

* Version bump for new base image

---

2.0

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
* Disable consul DNS option with local_unbound as is only practical in VNET jails with a localhost
* Adjust acme.sh setup and renew scripts for '$domain_ecc' suffix which is default now
* Bug-fixing acme.sh changes

---

1.6

* Version bump for new base image

---

1.5

* Version bump for new base image
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

---

1.2

* Version bump for new base image
* Fix README for missing parameters
* Create /mnt/matrixdata if not exist
* Complete README missing parameter info

---

1.1

* Version bump for new base image
* New changelog format
* Improved acme.sh script
* TLS false for ldap connection

---

1.0.25

* Fixing startup command to synapse

---

1.0.24

Fix consul client hcl for new format

---

1.0.23

* Version bump for rebuild to fix missing images on potluck site

---

1.0.22

* Version bump for p3 rebuild
* Add checklist

---

1.0.21

* Rebuild for new base image, cook script

---

1.0.20

* Version bump for FreeBSD-13.1 image
* python38-* to python39-*

---

1.0.19

* Added syslog-ng and remote logging

---

1.0.18

* Fixes to homeserver.yaml to remove well-known

---

1.0.17

* Reverting nginx.conf files missed in previous commit

---

1.0.16

* Reverting .well-known setup as manually specifying delegation not helping

---

1.0.15

* Nginx-server .well-known

---

1.0.14

* Reverting nginx location to / and removing ssl on bit

---

1.0.13

* Adding skipped nginx updates for client_max_body_size

---

1.0.12

* Nginx updates for x-forward

---

1.0.11

* Adding useful steps to README.md

---

1.0.10

* using /.acme.sh for acme.sh stuff as problems writing to /root/.acme.sh in cook

---

1.0.9

* acme.sh needs additional steps to configure

---

1.0.8

* Further adjustment to manual process for certificates

---

1.0.7

* New fix for certificate registration with renewal via script

---

1.0.6

* Still fixing the certrenew script

---

1.0.5

* Further adjustment to certrenew script to make it run on start

---

1.0.4

* Fix to certrenew run process

---

1.0.3

* Fixes to certrenew script

---

1.0.2

* Add step to register zerossl account for acme.sh

---

1.0.1

* First bash at Matrix-Synapse jail image

---

1.0.0

* Initial commit
