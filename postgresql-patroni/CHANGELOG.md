2.9

* Version bump for new base image

---

2.8

* Pin patroni version to prevent surprises (3.3.0 for now)
* Fix missing quotes in patroni.yml.in which broke proper bootstrapping of new clusters
* Rename backup_node to backup-node for consistency

--

2.7

* Return to using postgresql13

---

2.6

* Version bump for new base image 14.2

---

2.5.4

* Update syslog-ng config to use modern config options

---

2.5.3

* Enable milliseconds in syslog-ng for all log timestamps

---

2.5.2

* Bring back postgresql-contrib to support useful plugins like pg_stat_statements (originally in v2.3.2)

---

2.5.1

* Version bump for new base image 14.1
* Extra steps to trim image size

---

2.4.1

* Version bump for new base image

---

2.3.2

* Add postgresql-contrib to support useful plugins like pg_stat_statements

---

2.3.1

* Version bump for FBSD14 base image

---

2.2.17

* Log queries that take longer than 100ms without parameters

---

2.2.16

* Make consul-template retry more often

---

2.2.15

* Update consul configuration to new version
* Fix _app label in node-exporter

---

2.2.14

* Disable QNAME minimization in unbound (consul can't handle it)

---

2.2.13

* Remove outdated consul patch

---

2.2.12

* Various fixes, support for backup node

---

2.2.11

* Add new parameter DNSFORWARDERS to allow controlling how unbound is configured
* Add reseason support to allow restarting grafana with fresh credentials
* Make patroni rc script adapt to the python version used (helps in development)

---

2.2.10

* Updating for python39

---

2.2.9

* Version bump for layered images

---

2.2.8

* Make consul node_names non-FQDN

---

2.2.7

* Major rework of templates, certificate issuing, and token/entity/group/role structure

---

2.2.6

* Improve metrics collection and image config

---

2.2.5

* Merged PR 26, incrementing version in changelog

---

2.2.4

* Dummy entry, missing version increment

---

2.2.3

* Dummy entry, missing version increment

---

2.2.2

* Dummy entry, missing version increment

---

2.2.1

* Incrementing version number after pull request 25

---

2.2.0

* Many improvements to service mesh components

---

2.1.9

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

2.1.8

* Updating version for merge

---

2.1.7

* Fixing missing certs directory

---

2.1.6

* Adding syslog-ng back

---

2.1.5

* Tweaking certificate filenames

---

2.1.4

* Adding metrics pki stuff for node_exporter

---

2.1.3

* Fixing missing pipes in cook scripts from TTL changes

---

2.1.2

* Fixing errors in cook scripts from nomad files

---

2.1.1

* Adding TTL parameter for consul template

---

2.1.0

* Big hashcluster update for new setup

---

2.0.24

* Need to use 127.0.0.1 instead of localhost in the scripts to check patroni status, else TLS fails

---

2.0.23

* TLS everywhere for postgresql requires specific permissions on key.pem

---

2.0.22

* Fixed the patroni.yml spacing

---

2.0.21

* Fixed the README file

---

2.0.20

* Encryption all round. Added scripts to check status.

---

2.0.19

* Removing sftppass, unsetting consul sysrc parameters where needed

---

2.0.18

* General security fixups and removal bad copy-paste entries

---

2.0.17

* Tweaking mandatory variables for optional parameters

---

2.0.16

* Bug-fix on gossip key

---

2.0.15

* Implementing mandatory variables

---

2.0.14

* Adding postgres_exporter for prometheus

---

2.0.13

* Setup for tls-client-validation

---

2.0.12

* README update, turning off flow-control in syslog-ng, setting 120s time_reopen, and reducing log-fifo parameter

---

2.0.11

* Clearing syslog-ng /dev/console entries to remove log spam

---

2.0.10

* Fixing typo in copy-in, future-proofing

---

2.0.9

* Updating syslog-ng and standardised cert.pem key.pem ca.pem

---

2.0.8

* Implementing syslog-ng with tls for remote logging

---

2.0.7

* Replication password, other updates to improve initdb process such as 0750 perms on /mnt/postgres

---

2.0.6

* Vault certificates intgration, pip install of psycopg2 due to conflicts with postgresql-client

---

2.0.5

* Updating for persistent postgresql storage

---

2.0.4

* Adjusting parameters for node-exporter service

---

2.0.3

* Added node_exporter and setup consul service "node-exporter"

---

2.0.2

* Consul pre-generated gossip encryption key added

---

2.0.1

* Fixing up minor type with trailing comma in consul agent.json setup

---

2.0

* Several updates including new postgresql version, better parameter variables

---

1.0

* Initial commit with PostgreSQL Patroni configuration that connects to Consul
