0.5

* Version bump for new base image
* use acme.sh for certificate registration, remove autossl from caddy
* Update README and example job

---

0.4

* Version bump for new base image
* Adjustments to caddyfile

---

0.3

* Change s3 addon to caddy-s3-proxy
* Use credentials file
* Update Caddyfile

---

0.2

* Version bump for new base image
* Adjustments to caddyfile because "unrecognized directive: storage"
* Remove domain name from Caddyfile, then caddy starts
* Add port for S3 to Caddyfile, add back domain after S3 config
* More adjustments to Caddyfile
* Fix readme for invalid two server info

---

0.1

* Version bump for new base image

---

0.0

* Initial commit
* Starting a caddy-s3-nomad image to use authentication to access a repo
