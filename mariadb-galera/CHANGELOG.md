0.17

* Version bump for new base image

---

0.16

* Version bump for new base image
* Quote PATH statements

---

0.15

* Version bump for new base image
* Update for rsync security issue

---

0.14

* Version bump for new base image 14.2

---

0.13

* Version bump for new base image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options
* Set mariadb option expire_logs_days

---

0.12

* Version bump for new base image 14.1
* Extra steps to trim image size

---

0.11

* Version bump for new base image

---

0.10

* Version bump for new base image

---

0.9

* Version bump for new base image

---

0.8

* Version bump for new base image

---

0.7

* Version bump for new base image
* Fix node_exporter zfs issue

---

0.6

* Version bump for new base image
* FBSD14 base image

---

0.5

* Version bump for new base image

---

0.4

* Version bump for new base image

---

0.3

* Version bump for new base image

---

0.2

* Version bump for new base image

---

0.1

* Version bump for new base image

---

0.0

* Copy mariadb to mariadb-galera and customise for Galera cluster
* Don't create haproxy user on replicas
* Only create mysql_exporter user on primary
* mysqld_exporter runs as user nobody but config file with password has restrictive permissions, fixed
