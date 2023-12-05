0.7

* Version bump for new base image
* Update checkout for changed gemfile

---

0.6

* Version bump for source switch
* Switch to Wogan May mastodon fork with 5000 character limit
* Testing hacks to allow yarn 4.0.2
* Revert hack, yarn <4 and yarn >4 are too different
* Test if downgrading yarn works
* Test downgrading yarn earlier
* Ruby doesn't like symlink CA certs, update env.production with direct link for freebsd CA cert

---

0.5

* Version bump for new base image
* Changes to fix broken dependancies
* Yarn flag change from `yarn install --pure-lockfile` to `yarn install --immutable`
* Manually add yarn packages `babel-plugin-lodash@3.3.4` and `compression-webpack-plugin@10.0.0` to fix a compile error
* Set yarn to stable version instead of classic
* Remove yarn -W flag for stable version
* Remove non-interactive flag as deprecated
* Set `compression-webpack-plugin@6.1.1` to avoid api error
* Minor additions to .env.production

---

0.4

* Version bump for new base image
* Formatting in nginx.conf, adjustments
* Add 'MAX_THREADS=10 WEB_CONCURRENCY=5' to env
* Update to mastodon 4.2.1
* Adjustments for missing rake package failing rake secret step
* Remove rake package install, use rails for secret key generation
* Add parameters for secret key, otp key, vapid keys
* Fix README for new parameters

---

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
* Fix nginx problems with invalid variable tls1_3_early_data
* Fix database check with better solution
* Experiment with using bash to perform db creation and assets compile due to variables
* Fine-tuning db creation, works manually, not in script
* Add redis check
* Remove redundant git pull
* Add first bash at upgrade script to be run inside jail before upgrade pot jail

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