0.0.8

* Create missing directories in persistent storage

---

0.0.7

* Removed folder permissions change and users for opendkim and opendmarc as users don't exist
* Tweaked opendkim.conf template to fix restart parameter error

---


0.0.6

* acme.sh changes to register account and use zerossl
* updated renewal script

---

0.0.5

* Fixing error with missing /etc/mail/certs/dh.param
* Removing postfix option dovecot-spamass_destination_recipient_limit
* Removing postfix option policyd-spf_time_limit
* Adding ROOTMAIL parameter for /etc/aliases and root mails

---

0.0.4

* Adding gossipkey to docs and parameter check
* Fixing sendmail disable twice causing error, removed second instance

---

0.0.3

* Adding missing package consul

---

0.0.2

* Adding missing items to README such as spamassassin whitelist copy-in
* Typos fixed
* node_exporter package wasn't included, added in

---

0.0.1

* This is the start of a postfix-ldap, dovecot, spamassassin and related, pot flavour