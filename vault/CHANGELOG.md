2.8

* Version bump for new base image

---

2.7

* Modify policy for working with patroni

---

2.6

* Version bump for new base image 14.2

---

2.5.3

* Update syslog-ng config to use modern config options

---

2.5.2

* Enable milliseconds in syslog-ng for all log timestamps

---

2.5.1

* Version bump for new base image 14.1
* Extra steps to trim image size

---

2.4.2

* Set autotidy policy when creating PKIs

---

2.4.1

* Version bump for new base image

---

2.3.1

* Version bump for FBSD14 base image

---

2.2.17

* Make consul-template retry more often

---

2.2.16

* Increase dead-server-last-contact-threshold to 24h

---

2.2.15

* Update consul configuration to new version

---

2.2.14

* Disable QNAME minimization in unbound (consul can't handle it)

---

2.2.13

* Add new parameter DNSFORWARDERS to allow controlling how unbound is configured
* Add scripts to support recovering a vault cluster
* Improve image resiliance

---

2.2.12

* Version bump for layered images

---

2.2.11

* Make consul node_names non-FQDN

---

2.2.10

* Fix nomad-client metrics retrieval

---

2.2.9

* Version bump to match ini, downgrading ini would still push version up

---

2.2.8

* Major rework of templates, certificate issuing, and token/entity/group/role structure

---

2.2.7

* Major rework of templates, certificate issuing, and token/entity/group/role structure

---

2.2.6

* Improve metrics collection

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

2.1.10

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

2.1.9

* Updating version for merge

---

2.1.8

* Fixing missing directory creation for /mnt/certs

---

2.1.7

* Enabling syslog-ng

---

2.1.6

* Updating metric certificate names

---

2.1.5

* Adding metrics pki to be used by loki, grafana, prometheus, node_exporter

---

2.1.4

* Fixing missing pipes in cook scripts from TTL changes

---

2.1.3

* Setting ATTL and BTTL variables for consul templates to pass in as TTL value where BTTL must be longer

---

2.1.2

* Setting a variable for consul templates to pass in a TTL

---

2.1.1

* Updating for postgres-patroni certificates

---

2.1

* Setting version numbers to sync with ini for potman

---

2.0.47

* Complete image revamp

---

2.0.46

* Setting stricter permissions on key.pem

---

2.0.45

* Further adjustments from diff output of improved cook script

---

2.0.44

* Fix audit.log location in unseal image. Adjust consul sysrc parameters.

---

2.0.43

* Consul fixes

---

2.0.42

* Typo escaping variable in temporary certificates script

---

2.0.41

* Fixup to generate temporary certificates script

---

2.0.40

* Security updates and improvements to strategic delay approach using Michael's new cook script

---

2.0.39

* Parameter adjustment to remove unnecessary variable checks from vault type

---

2.0.38

* Bug-fix on gossip key

---

2.0.37

* Implementing mandatory variables

---

2.0.36

* Improving temporary certificate generation to use list of IPs passed in, single-tem--cert script

---

2.0.35

* Updating consul agent to tls-client-validation

---

2.0.34

* Switch to using jo to generate json files for vault certificate payload.json. Minor fixes.

---

2.0.33

* Minor fixes to script to remove duplication. Added admin script to re-generate temp certificates.

---

2.0.32

* Implementing solution to force always-on client tls validation temporary short-lived certificates and keys via sftp

---

2.0.31

* Vault client TLS verification improvements and bug fixes, certificate validation as step

---

2.0.30

* Vault TLS verification working, with initial leader login ignoring tls-validation and leader having it as optional

---

2.0.29

* Turning off consul tls verification

---

2.0.28

* Turning off flow-control in syslog-ng, setting 120s time_reopen, and reducing log-fifo parameter

---

2.0.27

* Automation scripts and pki improvements. tls-verify doesn't work, syslog-ng with verification slows things down, raft cluster may be slow or not work

---

2.0.26

* Clearing syslog-ng /dev/console entries to remove log spam

---

2.0.25

* Updating syslog-ng and standardised cert.pem key.pem ca.pem

---

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
