0.22

* Version bump for new base image
* Clamav services now use underscore in service name

---

0.21

* Version bump for new base image
* Add certificate expiry notices to alertmanager host

---

0.20

* Version bump for new base image
* Update to 2025Q1 for pkg sources
* Update for rsync security issue
* Fix sa-training script for path
* Add script to requeue the 'on hold' mail
* Fix issue with shellcheck for PATH

---

0.19

* Version bump for new base image 14.2

---

0.18

* Version bump for new base image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options

---

0.17

* Version bump for new base image 14.1
* Extra steps to trim image size

---

0.16

* Version bump for new base image

---

0.15

* Version bump for new base image

---

0.14

* Version bump for new base image
* Fix postfix main.cf to replace "smtpd_use_tls" with "smtpd_tls_security_level"

---

0.13

* Version bump for new base image

---

0.12

* Version bump for new base image
* Fix node_exporter zfs issue
* Update quarterlies git branch
* Adjust cert renewal script as variables not expanding
* Update certificate renewal script

---

0.11

* Version bump for new base image
* FBSD14 base image
* Perl36, add net/p5-IO-Socket-INET6 and net/p5-Socket6 to ports pulled from git
* Fix global-acls issue by creating necessary directory /usr/local/etc/dovecot/global-acls
* Add necessary config line to dovecot.conf for ACL fix
* Create file instead of directory for global-acls

---

0.10

* Version bump for new base image

---

0.9

* Version bump for new base image

---

0.8

* Version bump for new base image
* Adjust quarterlies link
* Fix syslog-ng problems for 4.2 version, remove stats_freq option
* Removed TrustedAuthservIDs setting in opendmarc config
* Add local unbound and consul DNS services
* Update README with consul DNS info
* Comment out local_unbound consul dns as fails to work with unbound dependency
* fix local_unbound dns resolution with missing parameters for access control
* Disable consul DNS option with local_unbound as is only practical in VNET jails with a localhost
* Adjust acme.sh setup and renew scripts for '$domain_ecc' suffix which is default now

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
* Fix cert renew script

---

0.4

* Version bump for new base image
* Update syslog-ng.conf stats_freq(0); -> stats(freq(0));
* Update ports for 2023Q2
* Need databases/mysql80-client to replace databases/mysql57-client
* databases/mysql80-client wants /mysql80-server/Makefile, so add mysql80-server
* Add packages p5-Class-XSAccessor and p5-XString

---

0.3

* Version bump for new base image
* Change mailhome location to mail/domain/username
* Update checklist
* Switch to deliver to full uid
* Debugging adjustments for delivery to correct user folder
* Add back user-based auth-bind
* Increase default virtual_alias_expansion_limit to 3000
* Adjustments for Maildir
* Revert some settings
* More changes to Maildir settings
* Add dovecot-spamass_destination_recipient_limit = 1 to main.cf
* Adjust postfix ldap alias filters to get uid
* Create missing sieve directories
* Fix postfix ldap settings again
* Add obscure setting 'receive_override_options = no_address_mappings' in main.cf to allow delivery to 'username' (not 'username@domain') accounts which aren't local but are in virtual aliases
* Permit authenticated and my networks instead of blocking at helo time
* Add custom python-policyd-spf.conf
* Adjust default HELO_reject rule to False in python-policyd-spf.conf
* Include POSTNETWORKS in python-policyd-spf.conf Whitelist
* Adjust note for excluding gateway/firewall in POSTNETWORKS
* Change to WHITELIST for python-policyd-spf.conf Whitelist
* README updates
* Revert some python-policyd-spf.conf settings to original
* Set AuthservID for opendkim to public mail name
* Set myhostname from mail certificate name in postfix main.cf
* Adjust copied in files to subdirectory of root
* Include CUSTOMRBL parameter and update main.cf if set
* Fix sed for CUSTOMRBL

---

0.2

* Version bump for new base image
* Adjust postfix ldap search parameters
* Update quarterly release pulled to 2023Q1
* Update port names to latest versions, include databases/mysql57-client
* Fix logic to import existing certificates to postfix
* Shellcheck ignore for SC2039
* Forced copy and move of certificates into postfix
* Simplifying postfix ldap search
* Adjust mailboxes to /mnt/dovecot/mail/username
* dovecot-ldap needs extra fields to work with new setup

---

0.1

* New versioning format
* Update opendkim setup, requires mailnull ownership on keys
* Fix postfix dovecot-spamass transport
* Acme.sh renew script set to use letsencrypt

---

0.0.39

* postmap transport file

---

0.0.38

* Version bump to rebuild

---

0.0.37

* Version bump for rebuild to fix missing images on potluck site

---

0.0.36

* Version bump for p3 rebuild

---

0.0.35

* Adding back 'or true' option

---

0.0.34

* Fix errors introduced by last change
* Make directory /root/.acme.sh/

---

0.0.33

* Add log for acme.sh
* Add second attempt to register if first fails

---

0.0.32

* Remove acme.sh insecure flag
* Set 'or true' on acme.sh commands

---

0.0.31

* Specify letsencrypt twice

---

0.0.30

* Switch to letsencrypt for certificates due to issues with zerossl
* add options for standalone server to use port 80, insecure

---

0.0.29

* update git quarterlies branch to origin 2022Q4
* Add checklist
* Update consul config

---

0.0.28

* Version bump for rebuild on new base image
* Adjustments to cook for disabling in nomad and .env.cook

---

0.0.27

* Version bump for FreeBSD-13.1 image

---

0.0.26

* Left out LDAP option, adjusting format for make.conf

---

0.0.25

* Test with option-sets for ports building configured in make.conf

---

0.0.24

* Adjusting build process, works manually, not via automation

---

0.0.23

* Adding some packages to ports tree git checkout to make dovecot-ldap work

---

0.0.22

* Need to postmap copied in config files
* adjusting make command with all parameters set or unset for compiled ports

---

0.0.21

* Still says "Support not compiled in for passdb driver 'ldap'"
* Added dovecot-ldap.conf.ext customisations

---

0.0.20

* Step by step build process for compiled ports to test fix:
* dovecot error "auth: Fatal: Support not compiled in for passdb driver 'ldap'"

---

0.0.19

* chmod -> chown typo fix again
* remove ssh onedisable entirely, already disabled

---

0.0.18

* change to onedisable for ssh disable to remove error
* remove double start for opendkim-milter causing error code
* create /var/run/clamav and set owner clamav

---

0.0.17

* freshclam needs full path

---

0.0.16

* chmod -> chown typo fix

---

0.0.15

* Adding vhost user for dovecot
* fix clamav socket

---

0.0.14

* Cleanup opendkim permissions causing script failure
* Cleanup old comments

---

0.0.13

* Version bump for rebuild

---

0.0.12

* Fix to POSTSIZELIMIT variable in README
* Changing how postfix starts to retry

---

0.0.11

* Fix typo in previous commit

---

0.0.10

* Set postfix ownership on /mnt/postfix to correct startup error

---

0.0.9

* Set persistent storage as home directory for initial acme.sh account creation

---

0.0.8

* Create missing directories in persistent storage

---

0.0.7

* Removed folder permissions change and users for opendkim and opendmarc as users don't exist
* Tweaked opendkim.conf template to fix restart parameter error

---


0.0.6

* acme.sh changes to register account and use zerossl
* updated renewal script

---

0.0.5

* Fixing error with missing /etc/mail/certs/dh.param
* Removing postfix option dovecot-spamass_destination_recipient_limit
* Removing postfix option policyd-spf_time_limit
* Adding ROOTMAIL parameter for /etc/aliases and root mails

---

0.0.4

* Adding gossipkey to docs and parameter check
* Fixing sendmail disable twice causing error, removed second instance

---

0.0.3

* Adding missing package consul

---

0.0.2

* Adding missing items to README such as spamassassin whitelist copy-in
* Typos fixed
* node_exporter package wasn't included, added in

---

0.0.1

* This is the start of a postfix-ldap, dovecot, spamassassin and related, pot flavour
