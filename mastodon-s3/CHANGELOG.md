0.2

* Remove internal postgresql and redis as now external pot jails
* Add parameters for external DB and redis
* Update README
* Update requirements to include a jail with S3 frontend
* Fix ruby environment variables in scripts
* Change postgresql settings in ENV file
* Make note in readme about slow image boot
* Check if database exists before creating it
* Make note of long running commands in output
* Improve database checks

---

0.1

* Version bump for new base image
* Fix otp.key in README
* Fix postgresql-exporter by building inside directory

---

0.0

* Initiate all-in-one mastodon with S3 storage pot image
* Add missing steps to create database and assets