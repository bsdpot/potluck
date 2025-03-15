0.8

* Switch to latest packages
* New version spreed 2.0.2 in latest pkg stream

---

0.7

* Version bump for new base image
* Adjust various services to run on pot IP instead of 127.0.0.1/localhost
* Update README with steps to configure Nextcloud Talk app
* Adjust generation of hashkey and blockkey to hex format
* Add trailing slashes to nginx proxy statements
* Note that this won't work with current nextcloud because package in ports is too old
* "Error: Running version: 1.1.3; Server needs to be updated to be compatible with this version of Talk"
* https://repology.org/project/nextcloud-spreed-signaling/versions

---

0.6

* Version bump for new base image
* Quote PATH statements
* Add certificate expiry check with alerts to alertmanager

---

0.5

* Version bump for new base image
* Update for rsync security issue

---

0.4

* Version bump for new base image 14.2

---

0.3

* Version bump for new base image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options

---

0.2

* Version bump for new base image 14.1
* Extra steps to trim image size

---

0.1

* Version bump for new base image
* Add turnserver
* Fix ncs to open 127.0.0.1:8080
* Add self-signed certificates option

---

0.0

* Initial commit
* Update certificate renewal script
* Version bump for new base image, irregular minor bump as still WIP
* Version bump for new base image, minor increment as still WIP
* Implement block key encryption
* Fix consul naming
