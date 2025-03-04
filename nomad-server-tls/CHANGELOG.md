0.16

* Add nomad.service.consul alt name to Nomad certs

---

0.15

* Version bump for new base image

---

0.14

* Version bump for new base image 14.2

---

0.13.3

* Update syslog-ng config to use modern config options

---

0.13.2

* Enable milliseconds in syslog-ng for all log timestamps

---

0.13.1

* Version bump for new base image 14.1
* Extra steps to trim image size

---

0.12.1

* Version bump for new base image

---

0.11.2

* Add explicit -data-dir parameter

---

0.11.1

* Version bump for FBSD14 base image

---

0.10.17

* Make consul-template retry more often

---

0.10.16

* Update consul configuration to new version
* Fix _app label in node-exporter

---

0.10.15

* Disable QNAME minimization in unbound (consul can't handle it)

---

0.10.14

* Add new parameter DNSFORWARDERS to allow controlling how unbound is configured
* Add reseason support to allow restarting grafana with fresh credentials

---

0.10.13

* Moving /var/tmp/nomad out the way early in cook script

---

0.10.12

* Moving /var/tmp/nomad out the way, if it exists, so it will be re-created on nomad start

---

0.10.11

* Set 700 permissions on /var/tmp/nomad else nomad won't start

---

0.10.10

* Version bump for layered images

---

0.10.9

* Make consul node_names non-FQDN

---

0.10.8

* Fix nomad-client metrics retrieval

---

0.10.7

* Major rework of templates, certificate issuing, and token/entity/group/role structure

---

0.10.6

* Improve metrics collection

---

0.10.5

* Merged PR 26, incrementing version in changelog

---

0.10.4

* Dummy entry, missing version increment

---

0.10.3

* Dummy entry, missing version increment

---

0.10.2

* Dummy entry, missing version increment

---

0.10.1

* Incrementing version number after pull request 25

---

0.10.0

* Many improvements to service mesh components

---

0.9.38

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

0.9.37

* Updating version for merge

---

0.9.36

* Fixing missing certs directory

---

0.9.35

* Adding syslog-ng back

---

0.9.34

* Updating metrics certificate names

---

0.9.33

* Adding metrics pki stuff for node_exporter

---

0.9.32

* Fixing missing pipes in cook scripts from TTL changes

---

0.9.31

* Adding TTL parameter for consul templates

---

0.9.30

* Setting version numbers to sync with ini for potman

---

0.9.23

* Complete image revamp

---

0.9.22

* Setting stricter permissions on key.pem

---

0.9.21

* Removing sftppass, unsetting consul sysrc parameters where needed

---

0.9.20

* Fixing missing security improvements

---

0.9.19

* Updates for security improvements

---

0.9.18

* Tweaking mandatory variables for optional parameters

---

0.9.17

* Bug-fix on gossip key

---

0.9.16

* Implementing mandatory variables

---

0.9.15

* Updating for tls-client-validation

---

0.9.14

* Turning off flow-control in syslog-ng, setting 120s time_reopen, and reducing log-fifo parameter

---

0.9.13

* Clearing syslog-ng /dev/console entries to remove log spam

---

0.9.12

* Updates to syslog-ng and standardised cert.pem key.pem ca.pem

---

0.9.11

* Implementing syslog-ng with tls for remote logging

---

0.9.10

* Switched to quarterly package sources

---

0.9.9

* Adding optional logging to remote syslog server

---

0.9.8

* Node-exporter TLS

---

0.9.7

* Telemetry improvements

---

0.9.6

* Reload consul on cert update

---

0.9.5

* Fixing cron job for cert rotation

---

0.9.4

* Updating for pkg vault

---

0.9.3

* Third bash nomad-server with certificates and TLS, using vault for certificate rotation

---

0.9.2

* Second bash nomad-server with certificates and TLS

---

0.9.1

* First bash nomad-server with certificates and TLS

---

0.9

* Initial commit
