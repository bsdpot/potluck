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
