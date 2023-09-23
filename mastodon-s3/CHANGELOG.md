0.3

* Rewrite for non-layered image using latest packages
* Test image before pulling Mastodon from github instead of packages
* Remove artifacts from original flavour
* Add RC files for manual service setup
* Add process to pull mastodon from github if not already installed
* Need two ZFS mount in datasets now
* Add mastodon group
* Remove group add, create user before chown to user
* Don't add skel files to mastodon user homedir

---

0.2

* Remove internal postgresql and redis as now external pot jails
* Add parameters for external DB and redis
* Update README
* Update requirements to include a jail with S3 frontend
* Fix ruby environment variables in scripts
* Change postgresql settings in ENV file
* Make note in readme about slow image boot
* Check if database exists before creating it
* Make note of long running commands in output
* Improve database checks
* Attempted fix by locking rubygem Psyche to < 4, due to breaking changes with Psyche4 and Ruby3.1
* Note that /usr/local/www/mastodon install is not persistent storage, will rebuild on new image
* Attempt with manual install rubygem-psych3 because other approaches not working

---

0.1

* Version bump for new base image
* Fix otp.key in README
* Fix postgresql-exporter by building inside directory

---

0.0

* Initiate all-in-one mastodon with S3 storage pot image
* Add missing steps to create database and assets