1.0.19

* Added syslog-ng and remote logging

---

1.0.18

* Fixes to homeserver.yaml to remove well-known

---

1.0.17

* Reverting nginx.conf files missed in previous commit

---

1.0.16

* Reverting .well-known setup as manually specifying delegation not helping

---

1.0.15

* Nginx-server .well-known

---

1.0.14

* Reverting nginx location to / and removing ssl on bit

---

1.0.13

* Adding skipped nginx updates for client_max_body_size

---

1.0.12

* Nginx updates for x-forward

---

1.0.11

* Adding useful steps to README.md

---

1.0.10

* using /.acme.sh for acme.sh stuff as problems writing to /root/.acme.sh in cook

---

1.0.9

* acme.sh needs additional steps to configure

---

1.0.8

* Further adjustment to manual process for certificates

---

1.0.7

* New fix for certificate registration with renewal via script

---

1.0.6

* Still fixing the certrenew script

---

1.0.5

* Further adjustment to certrenew script to make it run on start

---

1.0.4

* Fix to certrenew run process

---

1.0.3

* Fixes to certrenew script

---

1.0.2

* Add step to register zerossl account for acme.sh

---

1.0.1

* First bash at Matrix-Synapse jail image

---

1.0.0

* Initial commit