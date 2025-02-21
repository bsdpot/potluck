0.3

* Version bump for new base image

---

0.2

* Version bump for new base image
* Quote PATH statements
* Add certificate expiry check with alerts to alertmanager
* Netbox v4.1.11
* Fix consul labels and set IP parameters

---

0.1

* Version bump for new base image
* Update for Netbox version 4.1.10 
* redo, 4.0.11 installed instead of 4.1.10 in ports
* Update for rsync security issue

---

0.0

* First bash at a pot jail with netbox with integrated posgresql and redis, things may be broken
* Fix formatting typos in README breaking hugo
* Update docs for missing parameters
* Use postgresql v16 because postgresql contrib is uninstalling v15 after installing
* Update postgresql.conf file for new format with log_timezone and timezone
* Change to using remote postgresql and redis images instead of integrated
* Downgrade to use postgresql-15 client only
* Documentation update to fix errors
* Remove database check for now
* Fix parameters in cook file
* Fix nginx configuration for static pages
* Fix netbox typos, add domain to ALLOWED_HOSTS, and check upgrade steps before starting netbox
* Automate superuser creation, can be improved in future or set optional
* Adjust service start order to start nginx last
* Fix remaining configuration.py.in typos
* Upgrade steps are not conditional, static files for site need to be generated every time
* Switch to using nginx with SSL, either via self-signed certificate, or acme.sh registration. Add renew script.
* Set media location in mount in storage
* Clean up CHECKLIST
* Fix configure-nginx.sh config missing "|"
* Fix missing logo on login page with clear alias to docs directory
* Fix missing rack images by removing 'add_header X-Frame-Options "DENY"'
* Add plugins netbox-secrets via pkg, and netbox-inventory, netbox-bgp, netbox-topology-views pip
* Set versions on pip python installs
* Remove user flag on pip installs, install to system path
