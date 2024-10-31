0.20.2

* Enable milliseconds in syslog-ng for all log timestamps

---

0.20

* Version bump for new base image

---

0.19

* Version bump for new base image

---

0.18

* Version bump for new base image
* Test prosody setting of interfaces = { 'x.x.x.x' }

---

0.17

* Version bump for new base image
* Fix node_exporter zfs issue
* Adjust cert renew script to hardcode domain
* Update certificate renewal script

---

0.16

* Version bump for new base image
* FBSD14 base image

---

0.15

* Version bump for new base image

---

0.14

* Version bump for new base image

---

0.13

* Version bump for new base image

---

0.12

* Version bump for new base image

---

0.11

* Version bump for new base image
* Fix error in ini file
* Fix README

---

0.10

* Version bump for new base image
* Fix syslog-ng problems for 4.2 version, remove stats_freq option
* Add local unbound and consul DNS services
* Update README with consul DNS info
* fix local_unbound dns resolution with missing parameters for access control
* Disable consul DNS option with local_unbound as is only practical in VNET jails with a localhost
* Adjust acme.sh setup and renew scripts for '$domain_ecc' suffix which is default now
* Bug-fixing acme.sh change
* Fix error with prosody setup
* Change password generation for turnserver
* Trim turnadmin output for final line only
* Fix jitsi-videobridge rc script to remove -XX:+UseConcMarkSweepGC
* Make backups of rc scripts if exist
* Use default RC files with user perms instead of custom running services as root
* Prevent jitsi-videobridge from advertising private ranges, set xmpp-domain

---

0.9

* Version bump for new base image

---

0.8

* Version bump for new base image
* Signified
* Fix nologin shell for nodeexport user

---

0.7

* Version increment for new feature
* Pass in consul servers as a comma-deliminated list
* Update nginx for acme challenges
* Fix certificate renewals

---

0.6

* Version bump for new base image
* Update syslog-ng.conf stats_freq(0); -> stats(freq(0));

---

0.5

* Major rewrite for testing
* Set ketstore type to jks
* Remove user flag for rc scripts on jicofo and jitsi-videobridge
* Remove prosody localhost virtualhost and cert generation
* Set user jvb instead of user focus
* Simplify many config files
* Add local IP to /etc/hosts
* Fix duplicate ssl_ciphers error
* Add back prosody localhost virtualhost for testing, add nginx-full
* Revert to normal nginx because nginx-full has conflicts which result in removal of nginx

---

0.4

* Version bump for new base image

---

0.3

* Version bump for new base image
* Implement websockets and turnserver
* Script error fixes with introduction turnserver
* Adjust config.js and videobridge settings
* Remove no-loopback-peers from turnserver config, bad config option
* Allow setting default resolution as parameter
* Specify turnservers in sip-communicator.properties
* Adjust to use full certificate chain in fullchain.cer so mobile devices work
* Re-enable P2P in config.js
* Set this server as STUN server in config.js
* Add local IP to turnserver allowed-peer-ip
* Include password for prosodyctl mod_roster_command

---

0.2

* Update prosody and related based on sample prosody config from jitsi-prosody-plugins
* Fix logging to /var/log/prosody
* Update jicofo config
* Update nginx config to match example from jitsi-prosody-plugins
* Bug-fixing and permissions changes
* Working release 0.2.4 with wasm duplication removed from nginx
* Update branding options
* Update README
* Fix branding link
* Add back global modules_enabled to prosody to clear config check
* Update syslog-ng to capture prosody, jicofo, jitsi-videobridge logs
* Comment out focusUserJid from config.js
* Turn off BWE mechanism in sip-communicator.properties
* Fix path for external_api.js in nginx.conf
* Set options in config.js to force video and audio on when joining
* Turn off P2P mode in config.js
* Enable pre-join page
* Prosody needs a localhost virtualhost
* Updates to jicofo, jitsi-videobridge and sip-communicator.properties after bugfixing

---

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
* include package jitsi-srtp-native for improved performance
* remove custom settings from rc files (from blog post) to test without
* add back custom parameters to rc files, jicofo doesn't start otherwise
* tweak startup for jitsi-videobridge
* add jicofostatus script
* fix error with prosody config to update secpassword
* fix source file name for jicofostatus script
* switch to jitsi-full meta package
* redo config files for new format
* Switch to latest package sources, non-layered image
* remove the rc env setting for jicofo and jitsi-videobridge
* Revert to quarterlies and layered image, problem was rc env setting
* Add back rc fix for 'the trustAnchors parameter must be non-empty' by adding -Djavax.net.ssl.trustStorePassword
* remove internal from bridge stanza
* Synchronise removal internal from jitsi-videobridge, swap password
* Tweak config file for prosody
* Single generated pass for debugging, add back customisations to videobridge rc file
* Cleanup install list
* Revert prosody config to older setup, plug jicofo and videobridge rc files
* Fix config.js for conference muc domain
* Revert to newer prosody setup for focus.auth, this authenticates fine
* Bunch of updates after watching helpful video
* Video link https://youtu.be/LJOpSDcwWIA
* Add extra bits to prosody config
* Tweaks to sip-communicator.properties
* Set jitsi-plugins directory correctly

---

0.0.1

* Initiate file
