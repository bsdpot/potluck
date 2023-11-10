0.2

* Version bump for new base image

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
