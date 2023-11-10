0.11

* Version bump for new base image

---

0.10

* Version bump for new base image
* New loki and promtail versions 2.9.1

---

0.9

* Version bump for new base image
* New loki and promtail
* Start syslog-ng last
* Add SVG logo
* Link to PNG logo in README as SVG not working

---

0.8

* Version bump for new base image

---

0.7

* Version bump for new base image
* Upgrade to grafana9
* Remove old nomad dashboards, replace with hashicorp one
* Tweak titles in dashboards
* Fixup nomad dashboard
* Fix syslog-ng problems for 4.2 version, remove stats_freq option
* Add local unbound for consul DNS resolution
* Update to Loki 2.8.3 and Promtail 2.8.3
* Add services to consul setup
* Fix addition of services
* Add consul DNS info to README
* Fix JSON consul agent config for multiple services
* Adjust local_unbound resolution problems
* Another approach to local_unbound resolution problems
* Disable consul DNS option with local_unbound as is only practical in VNET jails with a localhost
* Loki config updates, set localhost options to jail IP, as failing in VNET jails
* Set prometheus consul sd config to use 127.0.0.1
* Update prometheus alerts to fix broken alerts
* Update README with info on silences
* Adjust out of memory alert to trigger if less than 5% available
* Update Loki and Promtail to 2.8.4 versions
* Addressing potential errors causing hangs during orchestration scripts, start syslog-ng later

---

0.6

* Version bump for new base image
* New versions of loki and promtail
* Update checklist

---

0.5

* Version bump for new base image
* Signified
* Fix nologin shell for nodeexport user
* Fix nologin shell for loki user

---

0.4

* Version bump for new feature
* Pass in consul servers and scrape lists in comma-deliminated format
* Update logo

---

0.3

* Version bump for new base image
* Update syslog-ng.conf stats_freq(0); -> stats(freq(0));
* Tweak consul agent json to remove quotes for consul servers list

---

0.2

* Version bump for new base image
* Update loki and promtail to 2.7.3
* Set consul options for bind address
* Revert to consul json config file until consul fixed start with hcl
* Update loki and promtail to 2.7.5
* Update loki configuration file, permissions, sysrc entries
* Update grafana for grafana.ini and copy provisions dir from /usr/local/etc/grafana now
* Fix permissions on grafana.ini
* Update logs dashboard, replace nomad dashboards with newer ones

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
