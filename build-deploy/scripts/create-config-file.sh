#!/bin/bash
#
# This will create the nats-server resolver config
#

display_info "Building NATS configuration file: $NATS_CONF_NAME"
if [ "${NATS_TLS}" == "false" ] || [ "${BYPASS_TLS}" == "true" ]; then
  display_info "Creating NON-TLS configuration file"
  if [ "${BYPASS_TLS}" == "true" ]; then
    display_info " so the NATS server can be started and the NSC push will work."
  fi
  envsubst < ${TEMPLATE_DIRECTORY}/nats.conf.template > /tmp/nats.conf.tmp
else
  display_info "Creating TLS configuration file"
  envsubst < ${TEMPLATE_DIRECTORY}/nats.conf.tls.template > /tmp/nats.conf.tmp
fi

if gcloud compute scp --recurse --zone ${GC_REGION} /tmp/nats.conf.tmp ${GC_REMOTE_LOGIN}:${NATS_MP}/${NATS_CONF_NAME}; then
  cd .
fi
