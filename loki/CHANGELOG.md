0.2.15

* Version bump for p3 rebuild

---

0.2.14

* Allow placing alternative copies of loki and promtail config files on mount-in

---

0.2.13

* Add new parameter DNSFORWARDERS to allow controlling how unbound is configured
* Add reseason support to allow restarting grafana with fresh credentials

---

0.2.12

* Update to Loki version 2.6.1, updates to loki-local-config.yaml
* Update to Promtail version 2.6.1

---

0.2.11

* Add support for json logs with pipeline_stages in promtail conf

---

0.2.10

* Version bump for layered images

---

0.2.9

* Move loki and promtail download to image build phase

---

0.2.8

* Make consul node_names non-FQDN

---

0.2.7

* Major rework of templates, certificate issuing, and token/entity/group/role structure

---

0.2.6

* Improve metrics collection

---

0.2.5

* Serve loki over mTLS
* Move loki data to persistent storage

---

0.2.4

* Merged PR 26, incrementing changelog version

---

0.2.3

* Dummy changelog entry, missing increments to version

---

0.2.2

* Dummy changelog entry, missing increments to version

---

0.2.1

* Dummy changelog entry, missing increments to version

---

0.2.0

* Many improvements to service mesh components

---

0.1.3

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

0.1.2

* Updating version for merge

---

0.1.1

* Fixing missing certs directory

---

0.1.0

* Big update for hashcluster changes

---

0.0.15

* Removing sftppass, unsetting consul sysrc parameters where needed

---

0.0.14

* General security updates

---

0.0.13

* Tweaking mandatory variables for optional parameters

---

0.0.12

* Bug-fix on gossip key

---

0.0.11

* Implementing mandatory variables

---

0.0.10

* Documentation updates

---

0.0.9

* Updates for tls-client-validation to be working with temp certificates via sftp at first

---

0.0.8

* Turning off flow-control in syslog-ng, setting 120s time_reopen, and reducing log-fifo parameter

---

0.0.7

* Clearing syslog-ng /dev/console entries to remove log spam

---

0.0.6

* Added max connections option for syslog-ng, standardised cert.pem key.pem ca.pem for certificate filenames

---

0.0.5

* Switched to rsyslog with tls

---

0.0.4

* Switched to quarterly package sources

---

0.0.3

* Removed Grafana to separate flavour

---

0.0.2

* Addition of Grafana Loki

---

0.0.1

* First bash at loki syslogd centralised logging system

---

0.0.0

* Initiate file

