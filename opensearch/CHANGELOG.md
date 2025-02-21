0.11

* Version bump for new base image

---

0.10

* Version bump for new base image
* Quote PATH statements
* Fix consul service labels, set IP specific options
* set 127.0.0.1 only for consul client_addr

---

0.9

* Version bump for new base image
* Update for rsync security issue

---

0.8

* Version bump for new base image 14.2

---

0.7

* Version bump for new base image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options

---

0.6

* Version bump for FBSD 14.1
* Extra steps to trim image size

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
* Disable plugins and set network parameters
* Install from packages and disable security plugins. No need to build from source to work without TLS

---

0.0

* First attempt at opensearch pot image, an elasticsearch clone, compiled from ports without plugins so no TLS dependency
* Unset various opensearch-specific jail attributes as intefering with build. Set on pot image start.
