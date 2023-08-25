#!/bin/bash
#
# Cleaning up the variables used for NATS install and config scripts
#

display_info "Restarting NATS message server"
if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "sudo systemctl restart nats-server.service; sudo systemctl status nats-server.service"; then
  cd .
fi


display_info "Done"
