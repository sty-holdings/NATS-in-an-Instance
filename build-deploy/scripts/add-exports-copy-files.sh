#!/bin/bash
#
# This will create the nats-server resolver config
#

display_info "Downloading bash_exports from $GC_REMOTE_LOGIN/.bash_exports."
if gcloud compute scp --recurse --zone ${GC_REGION} ${GC_REMOTE_LOGIN}:.bash_exports /tmp/bash_exports.tmp; then
  cd .
fi

display_info "Add NATS_HOME to local bash_exports copy."
if grep -q "${NATS_MP}" /tmp/bash_exports.tmp; then
	display_info "NATS exports already exist. No action taken."
else
  display_info "Appending NATS_HOME to local bash_exports copy"
	cat >> /tmp/bash_exports.tmp <<- EOF
export NATS_HOME=$NATS_MP
EOF
  display_info "Uploading local bash_exports copy to ${GC_REMOTE_LOGIN}:${TARGET_DIRECTORY}/.bash_exports"
	if gcloud compute scp --recurse --zone ${GC_REGION} /tmp/bash_exports.tmp ${GC_REMOTE_LOGIN}:.bash_exports; then
	  cd .
	fi
fi

if [ "${NATS_TLS}" == "true" ]; then
  display_info "Adding Certs, Keys, CA Bundle to $NATS_MP/.certs"
  if gcloud compute scp --recurse --zone ${GC_REGION} ${CERT_BUNDLE_DIRECTORY}/STAR_savup_com.crt ${GC_REMOTE_LOGIN}:${NATS_MP}/.certs/.; then
    cd .
  fi
  if gcloud compute scp --recurse --zone ${GC_REGION} ${CERT_BUNDLE_DIRECTORY}/CAbundle.crt ${GC_REMOTE_LOGIN}:${NATS_MP}/.certs/.; then
    cd .
  fi
  if gcloud compute scp --recurse --zone ${GC_REGION} ${KEY_FILE} ${GC_REMOTE_LOGIN}:${NATS_MP}/.keys/.; then
    cd .
  fi
fi

display_info "Copying scripts to $NATS_MP/scripts"
if gcloud compute scp --recurse --zone ${GC_REGION} ${ROOT_DIRECTORY}//savup-nats/scripts/nats-gen-user-credentials.sh ${GC_REMOTE_LOGIN}:${NATS_MP}/scripts/.; then
  cd .
fi
