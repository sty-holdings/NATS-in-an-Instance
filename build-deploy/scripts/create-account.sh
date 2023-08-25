#!/bin/bash
#
# This will create an application account and user
#

if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "nsc describe account $NATS_ACCOUNT > /tmp/nats-account.tmp 2> /dev/null;"; then
  cd .
fi
if gcloud compute scp --recurse --zone ${GC_REGION} ${GC_REMOTE_LOGIN}:/tmp/nats-account.tmp /tmp/nats-account.tmp; then
  cd .
fi

b=$(cat /tmp/nats-account.tmp)
if [ -n "$b" ]; then
  display_info "NATS Message User Account already exists"
else
  display_info "Creating NSC $NATS_ACCOUNT account"
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "nsc add account $NATS_ACCOUNT;"; then
    cd .
  fi
  display_info "Generate $NATS_ACCOUNT account signature key"
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "nsc edit account $NATS_ACCOUNT --sk generate;"; then
    cd .
  fi
fi
