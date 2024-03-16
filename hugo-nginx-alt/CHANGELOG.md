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
