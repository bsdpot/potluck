0.1

* Version bump for new base image

---

0.0

* Initiate remoter flavour, custom image for internal use
* Fix typos
* Fix user crontab additions
* Adjust .pgpass permissions
* Store only 3 days of postgresql backups
* Create logs directory and update mirror scripts to log here
* Fix consul labels and set IP parameters, set 127.0.0.1 only for consul client_addr
* Don't overwrite existing authorized_keys file if exists