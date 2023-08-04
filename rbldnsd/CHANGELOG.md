0.8

* Version bump for new base image
* Fix syslog-ng problems for 4.2 version, remove stats_freq option
* Add local unbound and consul DNS services
* Update README with consul DNS info
* Fix error in consul agent config
* fix local_unbound dns resolution with missing parameters for access control
* Disable consul DNS option with local_unbound as is only practical in VNET jails with a localhost
* Adjust acme.sh setup and renew scripts for '$domain_ecc' suffix which is default now
* Bug-fixing acme.sh changes

---

0.7

* Version bump for new base image

---

0.6

* Version bump for new base image
* Signified
* Fix nologin shell for nodeexport user

---

0.5

* Version increment for new feature
* Pass in consul servers as a comma-deliminated list

---

0.4

* Version bump for new base image
* Update syslog-ng.conf stats_freq(0); -> stats(freq(0));

---

0.3

* Version bump for new base image
* Revert to json format consul config
* Fix missing comma in agent.json
* Update README for sample query
* Add acme.sh and finalise nginx
* Fix errors in previous update
* Adjust acme certificates copy to ssl directory
* Fix nginx.conf brackets
* Adjust nginx config to fix index.php not showing as default
* Fix default index.php page to list tools
* Set temporary solution for lookup URI to direct to main page
* Update README to include default page
* Include abuseipdb in the linked lookups
* Tweak README

---

0.2

* Version bump for new base image

---

0.1

* First bash at a pot jail for rbldnsd
