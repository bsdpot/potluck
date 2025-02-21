3.26

* Version bump for new base image

---

3.25

* Version bump for new base image
* Quote PATH statements
* Fix consul labels and set IP parameters
* Switch back to HCL config for consul and test
* Fix HCL config consul sysrc parameter

---

3.24

* Version bump for new base image

---

3.23

* Version bump for new base image 14.2

---

3.22

* Version bump for new base image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options

---

3.21

* Version bump for new base image 14.1
* Extra steps to trim image size

---

3.20

* Version bump for new base image

---

3.19

* Version bump for new base image

---

3.18

* Version bump for new base image

---

3.17

* Version bump for new base image

---

3.16

* Version bump for new base image

---

3.15

* Version bump for new base image
* Fix node_exporter zfs issue

---

3.14

* Version bump for new base image
* FBSD14 base image

---

3.13

* Version bump for new base image

---

3.12

* Version bump for new base image

---

3.11

* Version bump for new base image
* Add data-dir to nomad_args

---

3.10

* Version bump for new base image

---

3.9

* Version bump for new base image

---

3.8

* Version bump for new base image
* Fix syslog-ng problems for 4.2 version, remove stats_freq option
* Add local unbound for consul DNS resolution
* Minor change to consul agent config to use retry_join instead of start_join
* Add services to consul setup
* Fix addition of services
* Add consul DNS info to README
* Fix JSON consul agent config for multiple services
* fix local_unbound dns resolution with missing parameters for access control
* Disable consul DNS option with local_unbound as is only practical in VNET jails with a localhost
* Make nomad server config query consul on localhost
* Add back IP search/replace for nomad server config removed in error

---

3.7

* Version bump for new base image
* Add optional DISABLEUI parameter

---

3.6

* Version bump for new base image
* Signified
* Fix nologin shell for nodeexport user

---

3.5

* Version increment for new feature
* Pass in consul servers as a comma-deliminated list

---

3.4

* Version bump for new base image
* Update syslog-ng.conf stats_freq(0); -> stats(freq(0));
* Remove quotes from variable as adjustment for list of consul servers to join
* Add serf entry to nomad config, include TLS negatives
* Add autopilot stanza to nomad config and disable some defaults to see if leader election improves in poor latency environments
* Include parameter to set raft_multiplier value, or set to default of 1
* Fix missing pipe in configure nomad script
* Simplify nomad startup due to run errors with raft networks
* Disable nomad update check

---

3.3

* Missing version

---

3.2

* Missing version

---

3.1

* Version bump for new base image
* Fix checklist
* Shellcheck exclusions
* Add ports to consul agent config
* Fix permissions on /usr/local/libexec/nomad/plugins
* Revert to consul JSON agent config file

---

3.0

* Version bump for new base image
* New changelog format

---

2.0.21

* Version bump, missing file

---

2.0.20

* Version bump for rebuild to fix missing images on potluck site

---

2.0.19

* Version bump for p3 rebuild

---

2.0.18

* Update for new nomad version
* Added checklist

---

2.0.17

* Fixing README for nomad jobs
* Update consul hcl for new format tls settings

---

2.0.16

* Version bump for new image and cook format

---

2.0.15

* Version bump for FreeBSD-13.1 image

---

2.0.14

* Fix /var/tmp/nomad issue
* Add parameter to set regions

---

2.0.13

* Automatic job import, plan, from copied-in job files in .nomad format

---

2.0.12

* Implement working prometheus telemetry
* Update README for REMOTELOG

---

2.0.11

* Switch to syslog-ng

---

2.0.10

* Changing method for setting up remote syslog as variable wasn't expanding

---

2.0.9

* Adding missing nodeexport user

---

2.0.8

* Minor updates for telemetry and remote logs, latest version nomad

---

2.0.7

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

2.0.6

* Quoting gossip key encrypt parameter

---

2.0.5

* Adjusting parameters for service "node-exporter"

---

2.0.4

* Adding node_exporter and configuring consul to publish service at "node-exporter"

---

2.0.3

* Updated to use gossip encryption for consul and nomad (re-using key)

---

2.0.2

* Updated to use local consul agent

---

2.0.1

* Rebuild for FreeBSD 13 & new packages

---

2.0

* Updated to use latest flavour script, initial tweaks for nomad cluster in config

---

1.0.2

* Trigger build of FreeBSD 12.2 image & rebuild FreeBSD 11.4 image to update packages

---

1.0.1

* Fixed typo because of which DATACENTER was not set correctly

---

1.0

* Initial commit
