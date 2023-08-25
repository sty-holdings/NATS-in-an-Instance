#!/bin/bash
#
# This will create a user for SavUp App
#

display_info "Seeing if NATS Message operator already exists"
if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "nsc describe operator $NATS_OPERATOR > /tmp/nats-operator.tmp 2> /dev/null;"; then
  cd .
fi
if gcloud compute scp --recurse --zone ${GC_REGION} ${GC_REMOTE_LOGIN}:/tmp/nats-operator.tmp /tmp/nats-operator.tmp; then
  cd .
fi

b=$(cat /tmp/nats-operator.tmp)
if [ -n "$b" ]; then
  display_info "NATS Message Operator already exists"
else
  display_info "Creating NSC operator: $NATS_OPERATOR"
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "nsc add operator --generate-signing-key --sys --name $NATS_OPERATOR;"; then
    cd .
  fi
  display_info "NSC operator will require signed keys for accounts on $NATS_URL"
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "nsc edit operator --require-signing-keys --account-jwt-server-url $NATS_URL;"; then
    cd .
  fi
  display_info "Creating SYS Account key file for SavUp to use for Dynamic Account/User creation."
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "nsc list keys --all 2> /tmp/nats-keys.tmp; echo \$(awk '\$2==\"SYS\" && \$6==\"*\" { print \$4 } ' < /tmp/nats-keys.tmp) > /tmp/sys-signed.nk.tmp;"; then
    cd .
  fi
  if gcloud compute scp --recurse --zone ${GC_REGION} ${GC_REMOTE_LOGIN}:/tmp/sys-signed.nk.tmp /tmp/sys-signed.nk.tmp; then
    cd .
  fi
  b=$(cut -c2-3 < /tmp/sys-signed.nk.tmp)
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "echo \"file: $NKEYS_PATH/keys/A/$b/*.nk\"; cat $NKEYS_PATH/keys/A/$b/*.nk > $NATS_MP/SYS_SIGNED_KEY_LOCATION.nk;"; then
    cd .
  fi
fi
