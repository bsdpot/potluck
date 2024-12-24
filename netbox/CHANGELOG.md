---

0.0

* First bash at a pot jail with netbox with integrated posgresql and redis, things may be broken
* Fix formatting typos in README breaking hugo
* Update docs for missing parameters
* Use postgresql v16 because postgresql contrib is uninstalling v15 after installing
* Update postgresql.conf file for new format with log_timezone and timezone
* Change to using remote postgresql and redis images instead of integrated
* Downgrade to use postgresql-15 client only
* Documentation update to fix errors
* Remove database check for now
* Fix parameters in cook file
