0.21

* Version bump for new base image

---

0.20

* Version bump for new base image
* Quote PATH statements
* Fix consul labels and set IP parameters

---

0.19

* Version bump for new base image
* Update for rsync security issue

---

0.18

* Version bump for new base image 14.2

---

0.17

* Version bump for new base image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options
 
---

0.16

* Version bump for new base image 14.1
* Extra steps to trim image size

---

0.15

* Version bump for new base image

---

0.14

* Version bump for new base image

---

0.13

* Version bump for new base image
* Python is py311 now

---

0.12

* Version bump for new base image

---

0.11

* Remove opensearch and grafana
* Introduce a script to produce 3 charts from aggregate.csv
* Fix write path for index.html report
* Fix script to generate charts by changing to correct directory

---

0.10

* Version bump for new base image
* Switch from zincsearch to opensearch with security plugins disabled
* Fix node_exporter zfs issue
* Update parsedmarc version and config
* Create opensearch indexes manually
* Add py39-regex
* Fix typo for create-index.sh not configure-index.sh

---

0.9

* Version bump for base image
* FBSD14 base image

---

0.8

* Version bump for new base image

---

0.7

* Version bump for new base image

---

0.6

* Version bump for new base image

---

0.5

* Version bump for new base image
* New zincsearch

---

0.4

* Version bump for new base image

---

0.3

* Version bump for new base image
* Still WIP image, not working 100% yet for reports
* Update to zincsearch 0.4.7
* Make nginx fake elasticsearch on ip:9200/_bulk by proxy_pass to ip:4080/api/_bulk
* Make parsedmarc send to ip:9200
* Adjustments to parsedmarc rc script
* Add zinc user/pass to parsedmarc elasticsearch config
* Start parsedmarc service last
* Increase request entity size for fake elasticsearch to 512MB
* Enable prometheus monitoring for zincsearch
* Proxy_pass to elasticsearch compatible API bulk endpoint
* Adjust proxy_pass to /es/
* Fixup changes to parsedmarc ini for fake elasticsearch
* Force zincsearch index creation for 'dmarc_aggregate' and 'dmarc_forensic' before parsedmarc setup
* Fix stall in index creation
* Create a default index after checking zincsearch is responding. Don't create 'dmarc_aggregate' and 'dmarc_forensic'.
* Bugfixing index creation step
* Revert to forcing zincsearch index creation for 'dmarc_aggregate' and 'dmarc_forensic' before parsedmarc setup
* Split index creation to own script before parsedmarc install
* Use 127.0.0.1 instead of localhost
* Add grafana8 to use with custom dashboard for parsedmarc, suitable dashboard to be tested still
* Further adjustments to index creation
* Add grafana variables, simplify index creation script
* Fix missing grafana.ini
* Update to Grafana9
* Remove fake elasticsearch proxy_pass for testing direct
* Tweaks to parsedmarc elasticsearch config, add back fake elasticsearch for parsedmarc ingestion
* Fix Grafana datasource and add first dashboard
* Fix syslog-ng problems for 4.2 version, remove stats_freq option
* Updates to make Grafana play nice with fake elasticsearch
* Create alias for index creation, configure Grafana to use alias
* Add cron job to update alias (commented out)
* Fix grafana database pattern, separate datasources for aggregate and forensic
* Manually set elasticsearch version in zincsearch rc
* Add local unbound and consul DNS services
* Update README with consul DNS info
* fix local_unbound dns resolution with missing parameters for access control
* Disable consul DNS option with local_unbound as is only practical in VNET jails with a localhost

---

0.2

* Version bump for new base image
* Signified
* Fix nologin shell for nodeexport user
* Fix nologin shell for zincsearch user

---

0.1

* Rework project to start with parsedmarc python application
* Remove serverport parameter
* Fix username parsedmarc in user creation
* Update checklist for python39 changes
* Add parsedmarc.ini with imported parameters
* Add outputfolder parameter
* Touch log file and set permissions
* Add rc script for parsedmarc
* Update README
* Add zincsearch, an elasticsearch clone
* Make parsedmarc log to zincsearch automatically
* Remove Elasticsearch and Kibana install
* Fix zincsearch download
* Add back rust
* Fix zincsearch startup

---

0.0

* First bash at a pot jail with automatic dmarc report by accessing IMAP mailbox
* Use node pm2 as process manager to background node app
