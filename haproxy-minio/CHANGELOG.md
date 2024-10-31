0.9.2

* Enable milliseconds in syslog-ng for all log timestamps

---

0.9

* Version bump for new base image

---

0.8

* Version bump for inclusion of varnish7
* Fix varnish default.vcl to have a validating file (check with "varnishd -C -f default.vcl")

---

0.7

* Version bump for new base image 14.1
* Extra steps to trim image size

---

0.6

* Version bump for new base image

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
* Add tune.disable-zero-copy-forwarding to haproxy global section to deal with CPU overusage
* Allow for 1-4 minio servers

---

0.0

* Initial commit
* First bash at loadbalancer for minio
* Fix self-signed certificate for haproxy
* Adjust self-signed certificate generation to use pot image IP
* Adjust haproxy config, SSL verify off for backend
* Fix node_exporter zfs error
* Allow port 80 requests without redirect to port 443

---