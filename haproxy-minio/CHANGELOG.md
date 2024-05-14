0.1

* Version bump for new base image
* Add tune.disable-zero-copy-forwarding to haproxy global section to deal with CPU overusage

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