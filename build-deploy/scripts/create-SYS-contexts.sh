#!/bin/bash
#
# This will create the nats context for SYS and the SavUp Account

display_info "Creating place holder for user context files"
if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "nats context save ${NATS_OPERATOR}_sys --nsc nsc://$NATS_OPERATOR/SYS/sys"; then
  cd .
fi

if [ "${NATS_TLS}" == "false" ]; then
  display_info "Creating NON-TLS context file"
  envsubst < ${TEMPLATE_DIRECTORY}/nats.context.template > /tmp/${NATS_OPERATOR}_sys_context.tmp
else
  display_info "Creating TLS context file"
  envsubst < ${TEMPLATE_DIRECTORY}/nats.context.tls.template > /tmp/${NATS_OPERATOR}_sys_context.tmp
fi

if gcloud compute scp --recurse --zone ${GC_REGION} /tmp/${NATS_OPERATOR}_sys_context.tmp ${GC_REMOTE_LOGIN}:${INSTALL_DIRECTORY}/.config/nats/context/${NATS_OPERATOR}_sys.json; then
  cd .
fi
