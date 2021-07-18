2.0.24

* Implementing syslog-ng with tls for remote logging

---

2.0.23

* Switched to quarterly package sources

---

2.0.22

* Optional remote syslog capability added

---

2.0.21

* Node-exporter TLS

---

2.0.20

* Telemetry improvements

---

2.0.19

* Fixing cron job for cert rotation

---

2.0.18

* Using pkg vault

---

2.0.17

* Improvements for consul

---

2.0.16

* Added missing role, fixing rotation scripts

---

2.0.15

* Fixes to vault policy permissions, fixing typos in docs, longer sleep timers to avoid occassional lockup

---

2.0.14

* New and improved git-lite build process from sparse package source

---

2.0.13

* Using /mnt for vault AND template and certificate store. Requires a mount-in dataset for persistence. Using latest vault from port sources instead of package version.

---

2.0.12

* Follower generate certificates for self, reload with TLS

---

2.0.11

* Generate certificates for self, reload with TLS

---

2.0.10

* Enabling audit.log, split to case statement for three server types unseal, leader, cluster

---

2.0.9

* More adjustments to vault policies

---

2.0.8

* Adjustments for policy and CA

---

2.0.7

* Removed autostart from vault file

---

2.0.6

* Vault login and setup raft cluster for PKI and self-signed CA

---

2.0.5

* Fixups for raft storage cluster with automatic unseal based on wrapped token

---

2.0.4

* Unseal or cluster type with raft storage, along with persistent mount-in dataset at /mnt

---

2.0.3

* Adjusting parameters for node-exporter service

---

2.0.2

* Adding prometheus node_exporter and setting up as consul service

---

2.0.1

* Updated to use pre-generated consul encryption key for gossip, planning for TLS

---

2.0

* Updated to use local consul agent and a consul cluster for data store

---

1.0.1

* Rebuild for FreeBSD 13 & new packages

---
-

1.0

* initiate file
