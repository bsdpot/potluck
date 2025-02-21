0.13

* Version bump for new base image

---

0.12

* Version bump for new base image
* Quote PATH statements

---

0.11

* Version bump for new base image
* Update for rsync security issue

---

0.10

* Version bump for new base image 14.2

---

0.9

* Version bump for new base image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options
 
---

0.8

* Version bump for new base image 14.1
* Extra steps to trim image size

---

0.7

* Version bump for new base image

---

0.6

* Version bump for new base image

---

0.5

* Version bump for new base image

---

0.4

* Version bump for new base image

---

0.3

* Version bump for new base image
* Import SSH key to authenticate to custom git server
* Add useful customscript.sh example
* Fix typos in README
* Fix node_exporter ZFS collector
* Minor tweaks to git steps and SSH config
* Copy layouts folder from customgit too
* Make S3 host port an option
* Fix permissions, remove legacy permission setting, delete copied in key
* Add some additional default directories

---

0.2

* Version bump for new base image
* FBSD14 base image
* Add ability to run copied in customscript.sh file automatically if exists
* Add various toolsets for node, npm, ruby, toml-to-yaml conversion
* Make language a parameter, add additional settings to hugo.yaml.in
* Fix README references to config.toml as using hugo.yaml format
* Fix missing TITLE parameter
* Set a default title if not set, export variables
* Change order of copying so custom content is after theme site icons and css
* Make consistent parameter naming convention for MYTITLE and MYLANG
* Bug-fixing custom content copy by making sure directories exist
* Add logic to check if custom content has directories

---

0.1

* Adjustment to setup, don't use persistent storage as files going to S3 anyway and rebuild on every image startup
* Use /var/db/$SITENAME instead of persistent storage in /mnt
* Use a custom hugo.yaml file with variables set from parameters

---

0.0

* Alternate version Hugo with site and theme import from git sources as submodules
* No SSH access currently
* No SSL
* Update variables in README
* Adjust git submodule commands
* Adjust scripts with directory creation, fix typo
* Fix theme import error, disable ssh
* More adjustments to theme import
* Generate hugo site with yaml config
* Include passed in theme dir as theme in yaml config
