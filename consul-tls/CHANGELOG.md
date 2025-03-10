0.9

* Make Nomad proxy setup as an optional script

---

0.8

* Add Nomad proxy

---

0.7

* Version bump for new base image

---

0.6

* Version bump for new base image 14.2

---

0.5

* Version bump for new base image 14.1
* Extra steps to trim image size
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options

---

0.4.2

* Improve robustness of consul image startup

---

0.4.1

* Version bump for new base image

---

0.3.1

* Version bump for FBSD14 base image

---

0.2.13

* Make consul-template retry more often

---

0.2.12

* Update consul configuration to new version

---

0.2.11

* Disable QNAME minimization in unbound (consul can't handle it)

---

0.2.10

* Add new parameter DNSFORWARDERS to allow controlling how unbound is configured
* Add reseason support to allow restarting grafana with fresh credentials

---

0.2.9

* Version bump for layered images

---

0.2.8

* Bugfix in consul agent policy

---

0.2.7

* Make consul node_names non-FQDN

---

0.2.6

* Major rework of templates, certificate issuing, and token/entity/group/role structure

---

0.2.5

* Add consul metrics policy

---

0.2.4

* Improve metrics collection

---

0.2.3

* Merged PR 26 required version fix in changelog

---

0.2.2

* Dummy changelog entry, skipped increment

---

0.2.1

* Dummy changelog entry, skipped increment

---

0.2.0

* Many improvements to service mesh components

---

0.1.9

* Fixing header and tags in README

---

0.1.8

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

0.1.7

* Updating version for merge

---

0.1.6

* Fixing certs directory to match other images

---

0.1.5

* Adding syslog-ng back

---

0.1.4

* Updating metrics pki certificate names

---

0.1.3

* Adding metrics PKI stuff for node_exporter

---

0.1.2

* Fixing errors with missing pipes from TTL changes

---

0.1.1

* Adding TTL parameter for certificates

---

0.1

* Setting version numbers to sync with ini for potman

---

0.0.22

* Complete image revamp

---

0.0.21

* Setting stricter permissions on key.pem

---

0.0.20

* Removing sftppass, unsetting consul sysrc parameters where needed

---

0.0.19

* Fixing some misseed security improvements

---

0.0.18

* General security improvements

---

0.0.17

* Updates for mandatory variables

---

0.0.16

* Bug-fix on gossip key

---

0.0.15

* Implementing mandatory variables

---

0.0.14

* Updating image for tls-client-validation and dual certificate process with copy in of ssh key

---

0.0.13

* Turning off flow-control in syslog-ng, setting 120s time_reopen, and reducing log-fifo parameter

---

0.0.12

* Clearing syslog-ng /dev/console entries to remove log spam

---

0.0.11

* Updates to syslog-ng and standardising cert.pem key.pem ca.pem

---

0.0.10

* Implementing syslog-ng with tls for remote logging

---

0.0.9

* Switched to quarterly package sources

---

0.0.8

* Optional remote logging capability added

---

0.0.7

* Node-exporter TLS fixes

---

0.0.6

* Telemetry improvements

---

0.0.5

* Adjusting consul reload to use RC script

---

0.0.4

* Fixing cron job for cert rotation

---

0.0.3

* Switching to pkg vault

---

0.0.2

* Consul-tls image

---

0.0.1

* Initial commit
