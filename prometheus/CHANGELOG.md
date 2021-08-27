0.9.24

* Setting stricter permissions on key.pem

---

0.9.23

* Removing sftppass, unsetting consul sysrc parameters where needed

---

0.9.22

* General security updates, and updating changelog this time

---

0.9.21

* Tweaking mandatory variables for optional parameters

---

0.9.20

* Bug-fix on gossip key

---

0.9.19

* Implementing mandatory variables

---

0.9.18

* Prometheus alertmanager added

---

0.9.17

* Adding in postgres_exporter config to scrape
---

0.9.16

* Updates needed to support Nomad and Vault dashboards in Grafana image

---

0.9.15

* Setup for tls-client-validation

---

0.9.14

* Turning off flow-control in syslog-ng, setting 120s time_reopen, and reducing log-fifo parameter

---

0.9.13

* Clearing syslog-ng /dev/console entries to remove log spam

---

0.9.12

* Updates to syslog-ng and standardising cert.pem key.pem ca.pem

---

0.9.11

* Implementing syslog-ng with tls for remote logging

---

0.9.10

* Switched to quarterly package sources

---

0.9.9

* Removing Grafana to own flavour

---

0.9.8

* Optional remote logging capability added

---

0.9.7

* Node-exporter TLS

---

0.9.6

* Vault integration

---

0.9.5

* Persistent storage added at /mnt

---

0.9.4

* Changed method of Grafana startup to fix non-starting instance

---

0.9.3

* Updates for grafana default datasource and dashboard, removing specific targets adjustment in favour of consul

---

0.9.2

* Correcting consul published service name to use "node-exporter"

---

0.9.1

* Updating to use consul for announcing node_exporter as a service

---

0.9

* First test build of Prometheus with node_exporter and Grafana7

