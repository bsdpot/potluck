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

---

0.6

* Version bump for new base image

---

0.5

* Version bump for new base image
* Fix node_exporter zfs issue
* Update postgresql_exporter to 0.15.0
* Add postgresql-contrib to support useful plugins like pg_stat_statements
* Increase postgresql max_connections to 200

---

0.4

* Version bump for new base image
* FBSD14 base image

---

0.3

* Version bump for new base image

---

0.2

* Version bump for new base image
* Add item to checklist for new versions postgresql

---

0.1

* Version bump for new base image
* Update to postgresql15
* Add backup script

---

0.0

* Initial postgres-single image
* Fix postgres setup
* Remove postgres_exporter legacy fix
* Change creation postgres_exporter user in database
* Make sure we're not in /root when running sudo commands as postgres user
* Tabs and spaces fixes
* Further adjustments to postgres_exporter user setup
* Set a password for the postgres_exporter user
* Add logic to check if postgresql users exist before adding
* Adjust postgres_exporter password variable
* Bugfixing postgres_exporter, changing order of scripts
* Set path in postgres-post-init because sudo wasn't being found
