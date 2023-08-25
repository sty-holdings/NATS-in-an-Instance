#!/bin/bash
#
# This will create an application user
#

display_info "Creating user: $NATS_USER"
if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "nsc add user --account $NATS_ACCOUNT $NATS_USER"; then
  cd .
fi
