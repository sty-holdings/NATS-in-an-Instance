#!/bin/bash
#
# This will create the nats context for SYS and the SavUp Account

display_info "Creating place holder for user context files"
if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "nats context save ${NATS_USER}"; then
  cd .
fi

display_info "Creating the user context for $NATS_USER"

if [ "${NATS_TLS}" == "false" ]; then
  display_info "Creating NON-TLS context file"
  envsubst < ${TEMPLATE_DIRECTORY}/nats.context.template > /tmp/${NATS_USER}_context.tmp
else
  display_info "Creating TLS context file"
  envsubst < ${TEMPLATE_DIRECTORY}/nats.context.tls.template > /tmp/${NATS_USER}_context.tmp
fi

if gcloud compute scp --recurse --zone ${GC_REGION} /tmp/${NATS_USER}_context.tmp ${GC_REMOTE_LOGIN}:${INSTALL_DIRECTORY}/.config/nats/context/${NATS_USER}.json; then
  cd .
fi
if gcloud compute scp --recurse --zone ${GC_REGION} /tmp/${NATS_USER}_context.tmp ${GC_REMOTE_LOGIN}:${INSTALL_DIRECTORY}/.config/nats/context/${NATS_USER}.json.bkup; then
  cd .
fi
