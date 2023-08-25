#!/bin/bash
#
# This will start the NATS server using the nats.conf file

display_info "Installing nats.service file"
envsubst < ${TEMPLATE_DIRECTORY}/nats-server.servicefile.template > /tmp/nats-server.servicefile.tmp
if gcloud compute scp --recurse --zone ${GC_REGION} /tmp/nats-server.servicefile.tmp ${GC_REMOTE_LOGIN}:${NATS_MP}/nats-server.service; then
  cd .
fi
if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "sudo mv ${NATS_MP}/nats-server.service /etc/systemd/system/nats-server.service; sudo chmod 755 /etc/systemd/system/nats-server.service; sudo systemctl daemon-reload;"; then
  cd .
fi
if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "sudo systemctl start nats-server.service; sleep 2;"; then
  cd .
fi
