0.19

* Version bump for new base image

---

0.18

* Version bump for new base image
* Add certificate expiry scripts for alertmanager notices

---

0.17

* Version bump for new base image
* Update to 2025Q1 for pkg sources
* Update for rsync security issue
* Fix switch to latest over quarterly

---

0.16

* Version bump for new base image 14.2

---

0.15

* Version bump for new base image

---

0.14

* Version bump for new base image 14.1
* Extra steps to trim image size

---

0.13

* Version bump for new base image

---

0.12

* Version bump for new base image

---

0.11

* Version bump for new base image
* Install lang/go instead of specific go121

---

0.10

* Version bump for new base image

---

0.9

* Version bump for new base image
* Update go package to go121
* Fix perl version 5.36
* Update certificate renewal script

---

0.8

* Version bump for new base image
* FBSD14 base image

---

0.7

* Version bump for new base image
* Remove authentication, proceed with image using anonymous download only

---

0.6

* Version bump for new base image

---

0.5

* Version bump for new base image
* use acme.sh for certificate registration, remove autossl from caddy
* Update README and example job
* Include package acme.sh

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
