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
