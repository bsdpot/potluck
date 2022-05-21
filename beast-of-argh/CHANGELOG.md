0.0.12

* Adding scrape job for file-based targets in persistent storage to enable dynamic configuration
* Moved postgres scrape job to file-based target in persistent storage, and removed dbserver parameter
* Removed influxdb datasource from grafana for now

---

0.0.11

* Full path required for alert rules directory in prometheus.yml
* Using hard-coded mount-in persistant storage at /mnt

---

0.0.10

* Using different approach to disable syslogd

---

0.0.9

* Cleanup lingering artifacts from proxy services for TLS versions of images

---

0.0.8

* Removing syslogd central.log from loki, syslog-ng changes to promtail config weren't updated
* Adding note that syslog-ng version must be 3.36 not 3.36.1

---

0.0.7

* Missing dashboards for grafana fail in running image, fixed by adding back

---


0.0.6

* Version increment for potbuilder build failure, retry

---

0.0.5

* Fixing grafana missing IP changes, failed to start

---

0.0.4

* Fixing formatting typo in README

---

0.0.3

* Switch to syslog-ng

---

0.0.2

* Updated to scrape traefik source

---

0.0.1

* First bash at the 'Beast of Argh', a single pot image with prometheus, alertmanager, loki, grafana, syslog server and more
