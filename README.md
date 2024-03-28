## SavUp NATS project

Usage: setup-nats.sh -h | -d -e {environment}-o {operator name} -a {account name} -n {user name} -s {server name} -m {remote NATS mount point} -p {port number} -t {directory for certs/keys}

flags:

-h			 display help

-a {account name}	 The name of the starter account that owns the starter user.

-d			 Execute with default prompt selections

-e {local|dev|prod} 	 Target environment

-m {remote NATS mount point}	 The remote mount point where NATS Message is installed.

-n {user name}	 The name of the starter user.

-o {operator name}	 The name of the operator.

-p {port number}	 Optional - Websocket port number. Recommended to use 9222

-s {server name}	 The Gcloud instance name of the server.

-t {directory for certs/keys}	 Optional - location of the SSL Cert, key, and bundle

### CLI Setup examples
```
sh setup-nats.sh -o styh -a SAVUP -n savup -s savup-local-0030.savup.com -p 9222 -m /mnt/disks/savup-local-0030-nats -d -t -e local
sh setup-nats.sh -o styh -a SAVUP -n savup -s savup-dev-0099.savup.com -p 9222 -m /mnt/disks/savup-dev-0099-nats -d -t -e dev
```
