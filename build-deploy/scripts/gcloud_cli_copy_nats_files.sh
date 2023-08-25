#!/bin/bash
#
# Name: gcloud-cli-create-directories.sh
#
# Description: This will create directories on a gcloud instance.
#
# Installation:
#   None required
#
# Copyright (c) 2022 STY-Holdings Inc
# All Rights Reserved
#

set -o pipefail

# Passed by caller
GC_REGION=$1
GC_REMOTE_LOGIN=$2
NATS_SOURCE_DIRECTORY=$3
TARGET_DIRECTORY=$4
# script variables

if gcloud compute scp --zone "${GC_REGION}" "${NATS_SOURCE_DIRECTORY}"/NATS* "${GC_REMOTE_LOGIN}:${TARGET_DIRECTORY}"/scripts/.; then
  echo -n
fi
if gcloud compute scp --zone "${GC_REGION}" "${NATS_SOURCE_DIRECTORY}"/NATS-setup.sh "${GC_REMOTE_LOGIN}:${TARGET_DIRECTORY}"/scripts/.; then
  echo -n
fi
