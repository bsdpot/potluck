disable_mlock = true
ui = true
listener "tcp" {
  address = "127.0.0.1:8200"
  tls_disable = 1
}

# make sure you create a zfs partition and mount it into /mnt
# if you want persistent vault data
# if using another directory update this path accordingly
storage "raft" {
  path    = "/mnt/vault/"
  node_id = "%%nodename%%"
  autopilot_reconcile_interval = "5s"
}
seal "transit" {
  address = "https://127.0.0.1:8099"
  key_name = "autounseal"
  mount_path = "transit/"
  token = "%%vaultunsealtoken%%"
  tls_skip_verify = false
  tls_ca_cert = "/mnt/unsealcerts/ca_root.crt"
  tls_server_name = "localhost"
}
telemetry {
  disable_hostname = true
  prometheus_retention_time = "24h"
}
service_registration "consul" {
  token = "%%consultoken%%"
}
log_format = "standard"
log_level = "Warn"
api_addr = "https://%%ip%%:8200"
cluster_addr = "https://%%ip%%:8201"
