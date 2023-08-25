#!/bin/bash
#
# This will create the nats-server resolver config
#

display_info "Creating NATS Resolver"
if gcloud compute scp --recurse --zone ${GC_REGION} ${GC_REMOTE_LOGIN}:$NATS_MP/includes/$NATS_RESOLVER /tmp/nats-resolver.tmp 2>/dev/null; then
  cd .
fi

if [ -f "/tmp/nats-resolver.tmp" ]; then
	display_info "Renaming exiting $NATS_RESOLVER file"
	DATE=$(date +"%Y-%m-%d-%H-%M")
	NATS_RESOLVER_OLD="$NATS_RESOLVER-$DATE"
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "mv $NATS_MP/includes/$NATS_RESOLVER $NATS_MP/includes/$NATS_RESOLVER_OLD 2> /dev/null;"; then
    cd .
  fi
fi

display_info "Setting NSC environment operator and creating resolver config file"
if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "nsc env -o $NATS_OPERATOR; nsc generate config --nats-resolver --sys-account SYS --config-file $NATS_MP/includes/$NATS_RESOLVER"; then
  cd .
fi
