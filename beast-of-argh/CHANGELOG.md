0.2

* Version bump for new base image
* Update loki and promtail to 2.7.3
* Set consul options for bind address

---

0.1

* Version bump for new base image
* New changelog format
* Grafana8 instead of Grafana7

---

0.0.29

* Fix consul client hcl for new format

---

0.0.28

* Version bump for rebuild to fix missing images on potluck site

---

0.0.27

* Version bump for p3 rebuild

---

0.0.26

* Adjusting minio dashboard in grafana to better working one
* Minio-supplied one is out of date

---

0.0.25

* Add minio.json to dashboards

---

0.0.24

* Version bump for rebuild and new version syslog-ng
* Added checklist

---

0.0.23

* Version bump for rebuild

---

0.0.22

* Updated to match cook changes and check for .env.cook
* Removed artifacts from combining several images into Beast

---

0.0.21

* Version bump for rebuild with new base image

---

0.0.20

* Version bump to build for FreeBSD-13.1
* Various formatting adjustments in earlier git PR but not version-bumped

---

0.0.19

* Add support for json logs, nginx, others
* Create /var/log/syslog-ng-disk-buffer/
* loki and promtail upgrade from 2.2.1 to 2.6.1 with adjusted config files
* Added a better all-in-one loki logs dashboard

---

0.0.18

* Added updated mysql dashboard to grafana default dashboards

---

0.0.17

* Added mysql dashboard to grafana default dashboards

---

0.0.16

* Scrape config for mysql/mariadb file-based-targets

---

0.0.15

* Minio additions for file-based-targets and documentation to enable metrics

---

0.0.14

* Avoid copying over existing files for file-based-targets

---

0.0.13

* Fixing broken indentation in prometheus.yml.in

---

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
