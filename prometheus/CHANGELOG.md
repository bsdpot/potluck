0.18

* Version bump for new base image

---

0.17

* Version bump for new base image 14.2

---

0.16.3

* Update syslog-ng config to use modern config options

---

0.16.2

* Enable milliseconds in syslog-ng for all log timestamps

---

0.16.2

* Add Loki metrics Consul service as a scrape target (restores the "lost" version 0.15.4)

---

0.16.1

* Version bump for new base image 14.1
* Extra steps to trim image size

---

0.15.4

* Add Loki metrics Consul service as a scrape target

---

0.15.3

* Make sure prometheus and alertmanager are started when an already provisioned image boots a second time

---

0.15.2

* Optimize reloading of services on cert rotation

---

0.15.1

* Version bump for new base image

---

0.14.0

* Workaround to fix consul-template restart

---

0.13.1

* Version bump for FBSD14 base image

---

0.12.7

* Protect admin web api endpoint in nginx proxy
* Web admin api endpoint is still disabled by default, but can be enabled temporarily for maintenance tasks

---

0.12.6

* Make consul-template retry more often

---

0.12.5

* Extend retention from 15 days to 2 years

---

0.12.4

* Update consul configuration to new version
* Fix _app label in node-exporter

---

0.12.3

* Disable QNAME minimization in unbound (consul can't handle it)

---

0.12.2

* Add support from prometheus-json-metrics-exporter (implementation to be provided by user)

---

0.12.1

* Add support from prometheus-log-exporter (implementation to be provided by user)

---

0.12.0

* Remove SCRAPEDATABASES parameter
* Discover postgres-exporters automatically

---

0.11.8

* Add new parameter DNSFORWARDERS to allow controlling how unbound is configured
* Add reseason support to allow restarting grafana with fresh credentials
* Repair config generation

---

0.11.7

* Version bump for layered images

---

0.11.6

* Correct further bug in consulmetricsproxy config

---

0.11.5

* Correct bug in consulmetricsproxy config

---

0.11.4

* Make consul node_names non-FQDN

---

0.11.3

* Fix nomad-client metrics retrieval

---

0.11.2

* Major rework of templates, certificate issuing, and token/entity/group/role structure

---

0.11.1

* Fixing alert rules to remove invalid rulesets

---

0.11.0

* Update README.md
* Connect prometheus to nomad, consul, and vault using mTLS over nginx proxies

---

0.10.9

* Improve metrics collection

---

0.10.8

* Remove alertmanager rule copy-in from /root
* Preload custom rules simply by pre-loading /mnt/prometheus/alerts

---

0.10.7

* Serve prometheus and alertmanager over mTLS

---

0.10.6

* Fixing broken alert rulesets

---

0.10.5

* Updating config, alerts and alertmanager templates

---

0.10.4

* Merged PR 26, incrementing version in changelog

---

0.10.3

* Dummy entry, missing version increment

---

0.10.2

* Dummy entry, missing version increment

---

0.10.1

* Dummy entry, missing version increment

---

0.10.0

* Many improvements to service mesh components

---

0.9.29

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

0.9.28

* Updating version for merge

---

0.9.27

* Fixing missing certs directory

---

0.9.26

* Adding syslog-ng back

---

0.9.25

* Implementing metric pki and new cook setup

---

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

