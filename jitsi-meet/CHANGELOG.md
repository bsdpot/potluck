0.1

* Creating regular pot jail for jitsi-meet as alternative to jitsi-meet-nomad
* This version includes consul, node_exporter, syslog-ng
* Fix cert renew script name
* Fix jitsi config and typo in service start
* Fix jicofo service start
* Generate keypassword differently as jicofo doesn't like some characters
* Fix nginx certificate copy
* Adjust jicofo rc script
* Fix logic for certs if already registered domain
* Re-order service config and start
* fix prosody cert location
* fix jicofo rc script with inclusion password
* adjust startup timing
* Adjust startup order
* fix jitsi-videobridge rc script to match earlier blog post
* fix jitsi-videobridge rc script to use org.jitsi.videobridge.MainKt
* create /var/db/prosody/custom_plugins
* fix jicofo start
* revert to simple start of some services
* custom image option added
* adjust prosodyctl legacy command to register for domain not auth.domain
* revert prosodyctl to register with auth.domain, 3rd party docs incorrect
* fix password allocations between first and second
* fix prosodyctl password for auth.domain to second password

---

0.0.1

* Initiate file
