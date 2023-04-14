3.2

* Version bump for new base image
* Update syslog-ng.conf stats_freq(0); -> stats(freq(0));

---

3.1

* Version bump for new base image

---

3.0

* Version bump for new base image
* New changelog format

---

2.0.12

* Version bump for rebuild

---

2.0.11

* Fix consul client hcl for new format

---

2.0.10

* Version bump for rebuild to fix missing images on potluck site

---

2.0.9

* Version bump for p3 rebuild

---

2.0.8

* Version bump for latest consul
* Add checklist

---

2.0.7

* Version bump for rebuild

---

2.0.6

* Version bump for new base image
* Adjustments to cook for disabling in nomad and .env.cook
* Remove ssh disable, done in base image

---

2.0.5

* Version bump for FreeBSD-13.1 image

---

2.0.4

* Need additional permissions for exporter user of mysqld_exporter to avoid errors filling up logs

---

2.0.3

* Fix access IP to passed in IP address for mysqld_exporter exporter user

---

2.0.2

* Fix error with mysqld_exporter credentials file preventing mariadb starting on pot image restart

---

2.0.1

* Rebuild for new format flavour image
* Include consul, node_exporter, mysql_exporter

---

1.0.2

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

1.0.1

* Rebuild for FreeBSD 13 & new packages

---

1.0

* Initial commit
