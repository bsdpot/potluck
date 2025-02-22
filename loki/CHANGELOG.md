0.5

* Version bump for new base image

---

0.4

* Version bump for new base image 14.2

---

0.3.7

* Update syslog-ng config to use modern config options

---

0.3.6

* Enable milliseconds in syslog-ng for all log timestamps

---

0.3.5

* Remove syslog log target from promtail and syslog-ng.conf and improve parsing of the varlogs target. This allows reingesting logs after disaster. Also parse severity.

---

0.3.4

* Add Loki metrics endpoint as a service in Consul (restores the "lost" version 0.2.26)

---

0.3.3

* Change image so it builds on FreeBSD 14.x

---

0.3.2

* Return to upstream versions of loki and promtail
* This uses rc scripts taken from the port (including some strangeness), so we can switch back in the future and stay compatible

---

0.3.1

* Version bump for new base image 14.1
* Extra steps to trim image size

---

0.2.26

* Add Loki metrics endpoint as a service in Consul

---

0.2.25

* More fixes to loki and promtail
* Breaking change: In case a custom promtail-local-config.yaml.in is used, adjust `positions:` to `filename: /mnt/log/promtail/positions.yaml`

---

0.2.24

* Fixes to starting promtail

---

0.2.23

* Switch to FreeBSD package versions of loki and promtail

---

0.2.22

* Make consul-template retry more often

---

0.2.21

* Update consul configuration to new version
* Fix _app label in node-exporter

---

0.2.20

* Disable QNAME minimization in unbound (consul can't handle it)

---

0.2.19

* Move special logs into their own dirs

---

0.2.18

* Add filtering of metric logs to a separate file in loki

---

0.2.17

* Version bump to rebuild

---

0.2.16

* Version bump for rebuild to fix missing images on potluck site

---

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

