0.20

* Version bump for new image

---

0.19

* Version bump for new image with pkg 2
* Add certificate expiry checks to alertmanager
* Quote PATH statements
* Fix consul labels and set IP parameters

---

0.18

* Version bump for new image
* Update for rsync security issue
* Fix switch to latest over quarterlies

---

0.17

* Version bump for 14.2
* New version mastodon 4.3.2

---

0.16

* Version bump for new image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options

---

0.15

* Update to mastodon 4.3.1
* Disable pipefail option on step to create Active Record Encryption keys
* Change template file for Active Record Encryption keys because manual output differs from automatic
* Update nginx.conf to validating state

---

0.14

* Version bump for new base image
* Update to Mastodon 4.2.13
* Trim image size
* Add S3PORT parameter

---

0.13

* Version bump for new image

---

0.12

* Version bump for new image

---

0.11

* Version bump for rebuild
* Update to latest mastodon release
* Configure longer S3 timeouts and add a retry

---

0.10

* Version bump for new base image
* Adjust certificate renewal script
* Reduce MAX_THREADS and WEB_CONCURRENCY slightly to reduce overhead
* Update mastodon to 4.2.9
* Setting yarn to classic as mastodon user no longer works, do this as root
* Update README to correct upgrades, add details on elasticsearch scripts
* Fix script to setup elasticsearch indexes
* Adjust create-admin-user script to also approve user
* Add additional maintenance scripts
* Add blackbox_exporter
* Update certificate renewal script

---

0.9

* Version bump for new base image
* FBSD14 base image
* Add rbenv and upgrade ruby
* Add cflags to bundle config for cbor and posix-spawn
* Change BUCKETHOST to BUCKETNAME
* Update node_exporter to ignore ZFS
* Fix typo in README
* Enable legacy ssl in node with NODE_OPTIONS=--openssl-legacy-provider [testing]
* Set read permissions on /etc/resolv.conf for Ruby as user to allow DNS resolution
* Remove legacy ssl settings as not working, simply can't connect to old SSL hosts for mail servers
* Add maintenance scripts for common tasks
* Add script to automate creating owner user without requiring email confirmation
* Fix typo
* Add adjustments for custom S3 provider, use S3_ENDPOINT with url/bucket
* Add S3UPNOSSL parameter to set HTTP for S3 uploads, such as local minio where self-signed certificates fail to work
* Fix processing logic for S3UPNOSSL parameter
* Adjustments to endpoints to remove bucket name, use S3_ENDPOINT with url only
* Add script to create elasticsearch indexes

---

0.8

* Version bump for new setup with git pull and bundle build process happening in pot build
* Add PVTCERT parameter to generate self-signed certificates for testing
* Change to newer cert generation method
* Cleanup image, add database migration step if database exists
* Add elasticsearch parameters
* Remove upgrade script as image build will upgrade, adjust database upgrade to two-step process
* adjust logic for elasticsearch parameters
* Add bundle config adjustments from https://wiki.freebsd.org/Ports/net-im/mastodon but commented out because not working
* Add DeepL translation API parameters
* Update to mastodon releases/v4.2.5 for security patch
* Update to mastodon releases/v4.2.6 for security patch
* Update to mastodon releases/v4.2.7 for security patch

---

0.7

* Version bump for new base image
* Update checkout for changed gemfile
* Manually install json-canonicalization 0.3.1
* Update Gemfile manually
* Update Gemfile by copying in custom version
* Fix errors
* Set bundle freeze false
* Set json-canonicalization (1.0.0)
* Set json-ld (3.3.1)
* Switch the alternate patched fork of mastodon https://github.com/hny-gd/mastodon/tree/stable-4.2

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
