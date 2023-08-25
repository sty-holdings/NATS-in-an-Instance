#!/bin/bash

#
# Generating NATS User credentials
#

# TODO: Pass variable to sub scripts to make them reusable

echo
echo "================================"
echo "  N    N    AA    TTTTTT   SSSS"
echo "  NN   N   A  A     TT    S    "
echo "  N N  N   AAAA     TT     SSS "
echo "  N  N N   A  A     TT        S"
echo "  N   NN  A    A    TT    SSSS "
echo "==============================="
echo

echo "--------------------------"
echo " Setting script variables "
#
export MY_NSC_BIN=/usr/bin/nsc
export MY_NATS_HOME=/mnt/disks/nats_home
#
export MY_NATS_ACCOUNT=SAVUP
export MY_NATS_USER=savup
#

echo " WARNING"
echo " WARNING: You are creating a user credential file that has sensitive information!!!! "
echo " WARNING           Handle with care and with system security in mind!!!!"
echo " WARNING"
echo " WARNING          The created file is located in $MY_NATS_HOME/user-creds"
echo

mkdir -p $MY_NATS_HOME/user-creds
nsc generate creds --account $MY_NATS_ACCOUNT --name $MY_NATS_USER
