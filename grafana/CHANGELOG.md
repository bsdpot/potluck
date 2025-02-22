0.9

* Version bump for new base image

---

0.8

* Version bump for new base image 14.2
* Replace deprecated AngularJS panels with supported ones in dashboards
* Revert dashboard UIDs
* Add missing datasource var to dashboards

---

0.7.3

* Update syslog-ng config to use modern config options

---

0.7.2

* Enable milliseconds in syslog-ng for all log timestamps

---

0.7.1

* Version bump for new base image 14.1
* Extra steps to trim image size

---

0.6.0

* Switch to grafana 10

---

0.5.1

* Version bump for new base image
* Implement rejected PR45 to unset timezone value in grafana dashboards

---

0.4.1

* Version bump for FBSD14 base image

---

0.3.5

* Make consul-template retry a lot more

---

0.3.4

* Stop using custom rc scripts

---

0.3.3

* Update consul configuration to new version
* Fix _app label in node-exporter

---

0.3.2

* Disable QNAME minimization in unbound (consul can't handle it)

---

0.3.1

* Bugfix for grafana9 provisioning

---

0.3.0

* Update to grafana9

---

0.2.8

* Add new parameter DNSFORWARDERS to allow controlling how unbound is configured
* Add reseason support to allow restarting grafana with fresh credentials

---

0.2.7

* Adding customised version of all-in-one loki dashboard for syslogs job

---

0.2.6

* Version bump for layered images

---

0.2.5

* Make consul node_names non-FQDN

---

0.2.4

* Major rework of templates, certificate issuing, and token/entity/group/role structure

---

0.2.3

* Fix bug in node exporter FreeBSD dashboard and add tag `#freebsd`

---

0.2.2

* Fixed the home dashboard to use a FreeBSD specific dashboard from
  https://github.com/rfrail3/grafana-dashboards/blob/master/prometheus/node-exporter-freebsd.json
* Old full node exporter dashboard set as home.json.old

---

0.2.1

* Improve metrics collection

---

0.2.0

* Use TLS to access prometheus and loki
* Add new mandatory parameters PROMTLSNAME and LOKITLSNAME
* Rename INFLUXDATABASE to INFLUXDBNAME
* LOKISOURCE, PROMSOURCE, INFLUXDBSOURCE allow specifying `host:port` now
* Overhaul README.md
* Serve grafana over mTLS

---

0.1.7

* Merged PR 26 and incremented version in changelog

---

0.1.6

* Dummy changelog entry, missing version increment

---

0.1.5

* Dummy changelog entry, missing version increment

---

0.1.4

* Dummy changelog entry, missing version increment

---

0.1.3

* Dummy changelog entry, missing version increment

---

0.1.2

* Dummy changelog entry, missing version increment

---

0.1.1

* Dummy changelog entry, missing version increment

---

0.1.0

* Many improvements to service mesh components

---

0.0.24

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

0.0.23

* Updating version for merge

---

0.0.22

* Fixing missing certs directory

---

0.0.21

* Adding syslog-ng back

---

0.0.20

* Updating for metrics pki and new cook setup

---

0.0.19

* Setting stricter permissions on key.pem

---

0.0.18

* Removing sftppass, unsetting consul sysrc parameters where needed

---

0.0.17

* General security improvements

---

0.0.16

* Tweaking mandatory variables for optional parameters

---

0.0.15

* Bug-fix on gossip key

---

0.0.14

* Implementing mandatory variables

---

0.0.13

* Added new dashboard for postgres, from postgres_exporter sources

---

0.0.12

* Adding new dashboards for consul, nomad and vault

---

0.0.11

* Setup for tls-client-validation

---

0.0.10

* Turning off flow-control in syslog-ng, setting 120s time_reopen, and reducing log-fifo parameter

---

0.0.9

* Fourth attempt at fixing grafana crashing a few minutes after startip. Bug report says to chmod 755 /root.

---

0.0.8

* Third attempt at fixing grafana crashing a few minutes after startip. Bug report says to fix the rc file.

---

0.0.7

* Second attempt at fixing grafana crashing a few minutes after startip

---

0.0.6

* Fixing error with grafana crashing. Standardising cert.pem key.pem ca.pem

---

0.0.5

* Implementing syslog-ng with tls for remote logging

---

0.0.4

* Adding influxdb data source and parameters

---

0.0.3

* Switched to quarterly package sources

---

0.0.2

* Updated early Grafana image

---

0.0.1

* Grafana image initialised

