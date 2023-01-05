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
