#!/bin/bash
#
# This will install NATS, NATSCLI, and NSC
#

display_info "Setting up NATS user, group, home directory, and permissions"

if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "sudo rm /tmp/nats-user.tmp 2>/dev/null; echo \$(awk -F : ' \$1==\"nats\" ' < /etc/passwd) > /tmp/nats-user.tmp"; then
  cd .
fi
if gcloud compute scp --recurse --zone ${GC_REGION} ${GC_REMOTE_LOGIN}:/tmp/nats-user.tmp /tmp/nats-user.tmp; then
  cd .
fi

b=$(cat /tmp/nats-user.tmp)
if [ -n "$b" ]; then
  display_info "NATS user already exist. No action taken."
else
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "sudo groupadd nats; sudo useradd --home $NATS_MP -M -s /bin/false -g nats -G google-sudoers nats; sudo chgrp -R nats $NATS_MP; sudo chmod g+s $NATS_MP"; then
    cd .
  fi
fi
rm /tmp/nats-user.tmp

display_info "Creating NATS server directories"
if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "sudo chown -R $GC_USER_ACCOUNT $NATS_MP/.; sudo chgrp -R nats $NATS_MP/.; sudo chgrp -R nats $NATS_MP/..; mkdir -p $NATS_MP/.keys; mkdir -p $NATS_MP/.certs; mkdir -p $NATS_MP/includes; mkdir -p $NATS_MP/jwt; mkdir -p $NATS_MP/install; mkdir -p $NATS_MP/jwt; mkdir -p $NATS_MP/scripts;"; then
  cd .
fi
if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "sudo chmod 750 $NATS_MP/.*; sudo chmod 755 $NATS_MP/*;"; then
  cd .
fi

display_info "Installing NATS server at $NATS_BIN"
if [ -f "$NATS_BIN" ]; then
	display_info "Server has already been installed"
else
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "curl -L ${NATS_INSTALL_URL} -o $NATS_MP/install/nats-server.zip"; then
    cd .
  fi
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "unzip $NATS_MP/install/nats-server.zip -d $NATS_MP/install/.; sudo cp $NATS_MP/install/nats-server-v2.9.19-linux-amd64/nats-server $NATS_BIN"; then
    cd .
  fi
fi

display_info "Installing NATSCLI server at $NATSCLI_BIN"
if [ -f "$NATSCLI_BIN" ]; then
	display_info "NATSCLI has already been installed"
else
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "curl -L ${NATSCLI_INSTALL_URL} -o $NATS_MP/install/nats-cli.zip"; then
    cd .
  fi
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "unzip $NATS_MP/install/nats-cli.zip -d $NATS_MP/install/.; sudo cp $NATS_MP/install/nats-0.0.35-linux-amd64/nats $NATSCLI_BIN"; then
    cd .
  fi
fi

display_info "Installing NSC server at $NSC_BIN"
if [ -f "$NSC_BIN" ]; then
	display_info "NSC has already been installed"
else
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "curl -L https://github.com/nats-io/nsc/releases/download/v2.8.0/nsc-linux-amd64.zip -o $NATS_MP/install/nsc-linux-amd64.zip"; then
    cd .
  fi
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "unzip $NATS_MP/install/nsc-linux-amd64.zip -d $NATS_MP/install/.; sudo cp $NATS_MP/install/nsc $NSC_BIN"; then
    cd .
  fi
fi

