#!/bin/bash
#
# This will edit the nats resolver config default location
# for account jwts. They will be moved to $NATS_HOME
#

display_info "Editing the resolver.conf file. Changing the dir from ./jwt to $NATS_MP/jwt"
if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "b=\$(grep -n \"dir: './jwt'\" $NATS_MP/includes/$NATS_RESOLVER | cut -d ':' -f 1); top=\$((b-1)); cat $NATS_MP/includes/$NATS_RESOLVER | head -n \$top > /tmp/nats-resolver-top.tmp"; then
  cd .
fi
if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "b=\$(grep -n \"dir: './jwt'\" $NATS_MP/includes/$NATS_RESOLVER | cut -d ':' -f 1); total=\$(wc -l $NATS_MP/includes/$NATS_RESOLVER | echo \$(cut -d ' ' -f 1)); bottom=\$((total-b)); cat $NATS_MP/includes/$NATS_RESOLVER | tail -n \$bottom > /tmp/nats-resolver-bottom.tmp;"; then
  cd .
fi
if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "newline=\$(echo \"dir: '$NATS_MP/jwt'\"); cat /tmp/nats-resolver-top.tmp > $NATS_MP/includes/$NATS_RESOLVER; echo \$newline >> $NATS_MP/includes/$NATS_RESOLVER; cat /tmp/nats-resolver-bottom.tmp >> $NATS_MP/includes/$NATS_RESOLVER;"; then
  cd .
fi
