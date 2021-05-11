# Overview

This is a ```patroni postgresql``` jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

It requires 5 ```consul-cluster``` servers running and the IPs passed in as part of the ```pot env``` setup.

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

The jail exposes these parameters that can either be set via the environment or by setting the ```cook```parameters (the latter either via ```nomad```, see example below, or by editing the downloaded jails ```pot.conf``` file):

| Environment | Content    | Unfilled column    |
| :---------- | :----------------: | :-----------|
| DATACENTER  | - datacentre name                 | ...  |
| NODENAME    | - unique name for node, each patroni-postgresql instance must have unique name                 | ...       |
| MYIP        | - IP address of this node                 | ...                  |
| SERVICETAG  | - service tag for node (master/replica/standby-leader)     | ...                  |
| CONSULSERVERONE | - IP of first consul server in a 5 node cluster                 | ...             |
| CONSULSERVERTWO | - IP of next consul server in a 5 node cluster                 | ...             |
| CONSULSERVERTHREE | - IP of next consul server in a 5 node cluster                 | ...             |
| CONSULSERVERFOUR | - IP of next consul server in a 5 node cluster                 | ...             |
| CONSULSERVERFIVE | - IP of next consul server in a 5 node cluster                 | ...             |
| ADMPASS     | - admin password                 | ...                  |
| KEKPASS     | - postgresql super user password                 | ...                  |
