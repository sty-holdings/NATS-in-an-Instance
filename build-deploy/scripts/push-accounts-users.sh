#!/bin/bash
#
# This will push all NSC accounts and user to NATS

display_info "Pushing Accounts and Users"
if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "nsc push -A"; then
  cd .
fi
