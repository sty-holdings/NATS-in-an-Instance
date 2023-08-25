#!/bin/bash
#
# Name: setup-nats.sh
#
# Description: Installs a stand alone instance of the NATS server
#
# Installation:
#   None required
#
# Note: _MP means mount point
#
# Copyright (c) 2022 STY-Holdings Inc
# All Rights Reserved
#

set -eo pipefail

# script variables
FILENAME=$(basename "$0")
#
# User Controlled variables that should be reviewed and edited if needed.
export CA_NAME=CAbundle.crt
export CERT_NAME=STAR_savup_com.crt
export KEY_NAME=savup.com.key
export INSTALL_DIRECTORY=/home/scott_yacko_sty_holdings_com
GC_USER_ACCOUNT="scott_yacko_sty_holdings_com"
GC_REGION="us-central1-c"
ROOT_DIRECTORY=/Users/syacko/workspace/styh-dev/src/albert
SCRIPT_DIRECTORY=${ROOT_DIRECTORY}/savup-nats/build-deploy/scripts
TEMPLATE_DIRECTORY=${ROOT_DIRECTORY}/savup-nats/build-deploy/templates
export NATS_INSTALL_URL=https://github.com/nats-io/nats-server/releases/download/v2.9.19/nats-server-v2.9.19-linux-amd64.zip
export NATSCLI_INSTALL_URL=https://github.com/nats-io/natscli/releases/download/v0.0.35/nats-0.0.35-linux-amd64.zip
export NSC_INSTALL_URL=https://github.com/nats-io/nsc/releases/download/v2.8.0/nsc-linux-amd64.zip

#
# System variables - Do not change unless you know how this variables work!
export GC_INSTANCE_NAME=""
export NATS_CONF_NAME=nats.conf
export NATS_MP=""
export NATS_OPERATOR=""
export NATS_RESOLVER=resolver.conf
export NATS_USER=""
export NATS_ACCOUNT=""
export NATS_URL=""
export NATS_WEBSOCKET_PORT=""
CERT_BUNDLE_DIRECTORY=""
KEY_FILE=""
DEFAULTS="false"
GC_REMOTE_LOGIN=""
NATS_BIN=/usr/bin/nats-server
NATS_PID=nats.pid
NATS_TLS="false"
NATSCLI_BIN=/usr/bin/nats
NKEYS_PATH=${INSTALL_DIRECTORY}/.local/share/nats/nsc/keys
NSC_BIN=/usr/bin/nsc

function init_script() {
  . /Users/syacko/workspace/styh-dev/src/albert/core/devops/scripts/display-error.sh
  . /Users/syacko/workspace/styh-dev/src/albert/core/devops/scripts/display-info.sh
  . /Users/syacko/workspace/styh-dev/src/albert/core/devops/scripts/display-possible-failure-note.sh
  . /Users/syacko/workspace/styh-dev/src/albert/core/devops/scripts/display-savup-msg.sh
  . /Users/syacko/workspace/styh-dev/src/albert/core/devops/scripts/display-spacer.sh
  . /Users/syacko/workspace/styh-dev/src/albert/core/devops/scripts/display-warning.sh
  . /Users/syacko/workspace/styh-dev/src/albert/core/devops/scripts/echo-colors.sh
  . /Users/syacko/workspace/styh-dev/src/albert/core/devops/scripts/display-skip.sh
  display_info "Script has been initialized."
}

function build_remote_instance_login() {
  GC_REMOTE_LOGIN=${GC_USER_ACCOUNT}@${GC_INSTANCE_NAME}
}

function nats_running() {
  display_info "Checking to see if NATS server is running."
  if [ -a tmp/natsAUX-result.tmp ]; then
    rm /tmp/natsAUX-result.tmp
  fi
#  The following 2 gcloud statement must be split otherwise, the combined command line will be picked up by the 'ps aux' command.
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "sudo ps aux > /tmp/natsAUX.tmp;" 2>/dev/null; then
    cd .
  fi
  if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "grep nats-server /tmp/natsAUX.tmp > /tmp/natsAUX-result.tmp" 2>/dev/null; then
    cd .
  fi
  if gcloud compute scp --recurse --zone ${GC_REGION} ${GC_REMOTE_LOGIN}:/tmp/natsAUX-result.tmp /tmp/natsAUX-result.tmp; then
    cd .
  fi

  NATS_PID=$(awk '//{print $2}' < /tmp/natsAUX-result.tmp)
  if [[ -n "$NATS_PID" ]]; then
    display_warning "A NATS Server is running on this system!!"
   	echo "NATS PID: $NATS_PID"
   	echo
 	  if [[ ( "$1" == "Y" ) || ( "$1" == "y" ) ]]; then
      display_warning "Please investigate the configuration of this system."
   	  display_warning "You must stop NATS before this script will run."
      echo "run: sudo systemctl stop nats-server or kill -USR2 $NATS_PID"
   	  echo
   	  exit 1
    fi
  else
      display_info "No NATS Message instance appears to be running. Moving forward."
  fi

  display_spacer
}

function set_variable() {
  cmd="${1}=$2"
  eval "$cmd"
  cmd="${1}_CHECKED=\"true\""
  eval "$cmd"
}

function validate_parameters() {
  if [ -z "$ENVIRONMENT_CHECKED" ]; then
    local Failed="true"
    display_error "The environment parameter is missing"
  else
    if [ "$ENVIRONMENT" == "dev" ]; then
      ENVIRONMENT="development"
    else
      if [ "$ENVIRONMENT" == "prod" ]; then
        ENVIRONMENT="production"
      else
        if [ "$ENVIRONMENT" == "local" ]; then
          ENVIRONMENT="local"
        else
          local Failed="true"
          display_error "The environment parameter must be either dev or prod"
        fi
      fi
    fi
  fi
  if [ -z "$GC_INSTANCE_NAME_CHECKED" ]; then
    local Failed="true"
    display_error "The server name parameter is missing"
  else
    export NATS_URL="nats://$GC_INSTANCE_NAME:4222"
    # shellcheck disable=SC2155
    export GC_INSTANCE_NAME=$(cut -d "." -f 1 <<< $GC_INSTANCE_NAME)
  fi
  if [ -z "$NATS_OPERATOR_CHECKED" ]; then
    local Failed="true"
    display_error "The operator parameter is missing"
  fi
  if [ -z "$NATS_ACCOUNT_CHECKED" ]; then
    local Failed="true"
    display_error "The user account parameter is missing"
  fi
  if [ -z "$NATS_USER_CHECKED" ]; then
    local Failed="true"
    display_error "The user parameter is missing"
  fi
  if [ -z "$NATS_MP_CHECKED" ]; then
    local Failed="true"
    display_error "The remote NATS home parameter is missing"
  fi

  if [ "$Failed" == "true" ]; then
    print_usage
    exit 1
  fi
}

function remove_nats() {
  display_warning "You are about to remove any existing NATS software from the instance!! - 5 sec pause to enter ctrl+c"
  if [ "$DEFAULTS" == "false" ]; then
    display_skip_message N
    read -r continue
  else
    continue="N"
  fi
  sleep 5
  if [[ ( "$continue" == "N" ) || ( "$continue" == "n" ) ]]; then
    display_warning "NATS is being removed from the system."
    if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "sudo rm -rf $NATS_MP/*; sudo rm -rf $INSTALL_DIRECTORY/.local/nats; rm -rf $INSTALL_DIRECTORY/.config/nats; rm -rf $INSTALL_DIRECTORY/.local/share/nats;"; then
      cd .
    fi
    if gcloud compute ssh --zone ${GC_REGION} ${GC_REMOTE_LOGIN} --command "sudo rm $NATS_BIN; sudo rm $NATSCLI_BIN; sudo rm $NSC_BIN;"; then
      cd .
    fi
  else
    echo "You elected to skip this step"
  fi

  display_spacer
}

function add_exports_copy_files() {
  display_info "Adding exports, and copying files"
  if [ "$DEFAULTS" == "false" ]; then
    display_skip_message N
    read -r continue
  else
    continue="N"
  fi
  if  [[ ( "$continue" == "Y" ) || ( "$continue" == "y" ) ]]; then
    display_info "You elected to skip this step"
  else
  	. $SCRIPT_DIRECTORY/add-exports-copy-files.sh
  fi

  display_spacer
}

function install_nats_tools() {
  display_info "Install NATS server, NATS CLI, and NSC at $NATS_MP"
  if [ "$DEFAULTS" == "false" ]; then
    display_skip_message N
    read -r continue
  else
    continue="N"
  fi
  if  [[ ( "$continue" == "Y" ) || ( "$continue" == "y" ) ]]; then
    display_info "You elected to skip this step"
  else
  	. $SCRIPT_DIRECTORY/install-nats-natcli-nsc.sh
  fi

  display_spacer
}

function create_operator_system() {
  display_info "Create NATS operator: $NATS_OPERATOR and SYS at ${NATS_URL} using ${NKEYS_PATH}"
  if [ "$DEFAULTS" == "false" ]; then
    display_skip_message N
    read -r continue
  else
    continue="N"
  fi
  if  [[ ( "$continue" == "Y" ) || ( "$continue" == "y" ) ]]; then
    display_info "You elected to skip this step"
  else
  	. $SCRIPT_DIRECTORY/create-operator-sys.sh
  fi

  display_spacer
}

function create_account() {
  display_info "Create NATS SAVUP account: $NATS_ACCOUNT"
  if [ "$DEFAULTS" == "false" ]; then
    display_skip_message N
    read -r continue
  else
    continue="N"
  fi
  if  [[ ( "$continue" == "Y" ) || ( "$continue" == "y" ) ]]; then
    display_info "You elected to skip this step"
  else
  	. $SCRIPT_DIRECTORY/create-account.sh
  fi

  display_spacer
}

function create_resolver() {
  display_info "Create NATS resolver file: $NATS_RESOLVER"
  if [ "$DEFAULTS" == "false" ]; then
    display_skip_message N
    read -r continue
  else
    continue="N"
  fi
  if  [[ ( "$continue" == "Y" ) || ( "$continue" == "y" ) ]]; then
    display_info "You elected to skip this step"
  else
  	. $SCRIPT_DIRECTORY/create-resolver-file.sh
  	. $SCRIPT_DIRECTORY/edit-jwt-dir.sh
  fi

  display_spacer
}

function create_server_config() {
  display_info "Create NATS config file: $NATS_CONF_NAME using"
  display_info "template: $TEMPLATE_DIRECTORY with "
  display_info "CERT/Keys: $CERT_NAME, $KEY_NAME, $CA_NAME"
  if [ "$DEFAULTS" == "false" ]; then
    display_skip_message N
    read -r continue
  else
    continue="N"
  fi
  if  [[ ( "$continue" == "Y" ) || ( "$continue" == "y" ) ]]; then
    display_info "You elected to skip this step"
  else
    	. $SCRIPT_DIRECTORY/create-config-file.sh
    fi

  display_spacer
}

function start_server() {
  display_info "Start the NATS server with systemd"
  if [ "$DEFAULTS" == "false" ]; then
    display_skip_message N
    read -r continue
  else
    continue="N"
  fi
  if  [[ ( "$continue" == "Y" ) || ( "$continue" == "y" ) ]]; then
    display_info "You elected to skip this step"
  else
  	. $SCRIPT_DIRECTORY/start-server-service.sh
  fi

  display_spacer
}

function push_accounts_users() {
  display_info "Push NSC account to NATS server"
  if [ "$DEFAULTS" == "false" ]; then
    display_skip_message N
    read -r continue
  else
    continue="N"
  fi
  if  [[ ( "$continue" == "Y" ) || ( "$continue" == "y" ) ]]; then
    display_info "You elected to skip this step"
  else
  	. $SCRIPT_DIRECTORY/push-accounts-users.sh
  fi

  display_spacer
}

function create_user() {
  display_info "Create user"
  if [ "$DEFAULTS" == "false" ]; then
    display_skip_message N
    read -r continue
  else
    continue="N"
  fi
  if  [[ ( "$continue" == "Y" ) || ( "$continue" == "y" ) ]]; then
    display_info "You elected to skip this step"
  else
  	. $SCRIPT_DIRECTORY/create-user.sh
  fi

  display_spacer
}

function create_contexts() {
  display_info "Create NATS context for SYS and $NATS_USER"
  if [ "$DEFAULTS" == "false" ]; then
    display_skip_message N
    read -r continue
  else
    continue="N"
  fi
  if  [[ ( "$continue" == "Y" ) || ( "$continue" == "y" ) ]]; then
    display_info "You elected to skip this step"
  else
  	. $SCRIPT_DIRECTORY/create-SYS-contexts.sh
  	. $SCRIPT_DIRECTORY/create-user-contexts.sh
  fi

  display_spacer
}

function clean_up() {
  display_info "Cleaning up"
  if [ "$DEFAULTS" == "false" ]; then
    display_skip_message N
    read -r continue
  else
    continue="N"
  fi
  if  [[ ( "$continue" == "Y" ) || ( "$continue" == "y" ) ]]; then
    display_info "You elected to skip this step"
  else
  	. $SCRIPT_DIRECTORY/clean-up.sh
  	echo "==> Clean up is done"
  fi
}

# shellcheck disable=SC2028
function print_parameters() {
  display_info "Here are the values you have supplied:"
  if [ "$DEFAULTS" == "true" ]; then
    display_warning "Script will run with default prompt selections!"
  fi
  echo "ENVIRONMENT:\t\t${ENVIRONMENT}"
  echo "GC_INSTANCE_NAME:\t${GC_INSTANCE_NAME}"
  echo "GC_REMOTE_LOGIN:\t${GC_REMOTE_LOGIN}"
  echo "GC_REGION:\t\t${GC_REGION}"
  echo "GC_USER_ACCOUNT: \t${GC_USER_ACCOUNT}"
  echo "NATS_CONF_NAME:\t\tnats.conf"
  echo "NATS_MP:\t\t${NATS_MP}"
  echo "NATS_OPERATOR:\t\t${NATS_OPERATOR}"
  echo "NATS_ACCOUNT:\t\t${NATS_ACCOUNT}"
  echo "NATS_USER:\t\t${NATS_USER}"
  echo "NATS_URL:\t\t${NATS_URL}"
  if [ -z "${NATS_WEBSOCKET_PORT}" ]; then
    echo "NATS_WEBSOCKET_PORT:\t is not being used"
  else
    echo "NATS_WEBSOCKET_PORT:\t${NATS_WEBSOCKET_PORT}"
  fi
  if [ "${NATS_TLS}" == "false" ]; then
    echo "TLS:\t\t\tNo"
  else
    echo "TLS:\t\t\tYes"
    echo "\t\t\tCert:\t\t${CERT_BUNDLE_DIRECTORY}/${CERT_NAME}"
    echo "\t\t\tCA Bundle:\t${CERT_BUNDLE_DIRECTORY}/${CA_NAME}"
    echo "\t\t\tKey file:\t${KEY_FILE}"
  fi
  echo
  echo "Here are the pre-set or defined variables:"
  echo "ROOT_DIRECTORY:\t\t${ROOT_DIRECTORY}"
  echo "SCRIPT_DIRECTORY:\t${SCRIPT_DIRECTORY}"
  echo "CERT_BUNDLE_DIRECTORY:\t${CERT_BUNDLE_DIRECTORY}"
  echo "INSTALL_DIRECTORY:\t${INSTALL_DIRECTORY}"
  display_spacer

}

# shellcheck disable=SC2028
function print_usage() {
  display_info "This will create a NATS Message server on existing GCloud instance."
  echo
  echo "Usage: ${FILENAME} -h | -d -e {environment}-o {operator name} -a {account name} -n {username} -s {server name} -m {remote NATS mount point} -p {port number} -t {directory for certs/keys}"
  echo
  echo "flags:"
  echo "  -h\t\t\t\t display help"
  echo "  -a {account name}\t\t The name of the starter account that owns the starter user."
  echo "  -d\t\t\t\t Execute with default prompt selections"
  echo "  -e {local | dev | prod} \t Target environment"
  echo "  -m {remote NATS mount point}\t The remote mount point where NATS Message is installed."
  echo "  -n {username}\t\t\t The name of the starter user."
  echo "  -o {operator name}\t\t The name of the operator."
  echo "  -p {port number}\t\t Optional - Websocket port number. Recommended to use 9222."
  echo "  -s {server name}\t\t The Gcloud instance name of the server."
  echo "  -t {directory for certs/keys}\t Optional - location of the SSL Cert, key, and bundle"
  echo
}

# Main function of this script
function run_script {
  if [ "$#" == "0" ]; then
    display_error "No parameters where provided."
    print_usage
    exit 1
  fi

  while getopts 'do:a:n:s:m:p:the:' OPT; do # see print_usage
    case "$OPT" in
    a)
      set_variable NATS_ACCOUNT "$OPTARG"
      ;;
    d)
      DEFAULTS="true"
      ;;
    e)
      set_variable ENVIRONMENT "$OPTARG"
      ;;
    m)
      set_variable NATS_MP "$OPTARG"
      ;;
    n)
      set_variable NATS_USER "$OPTARG"
      ;;
    p)
      set_variable NATS_WEBSOCKET_PORT "$OPTARG"
      ;;
    o)
      set_variable NATS_OPERATOR "$OPTARG"
      ;;
    s)
      set_variable GC_INSTANCE_NAME "$OPTARG"
      ;;
    t)
      NATS_TLS="true"
      ;;
    h)
      print_usage
      exit 0
      ;;
    *)
      display_error "Please review the usage printed below:" >&2
      print_usage
      exit 1
      ;;
    esac
  done

  validate_parameters
  CERT_BUNDLE_DIRECTORY=${ROOT_DIRECTORY}/keys/${ENVIRONMENT}/.keys/savup/STAR_savup_com
  KEY_FILE=${ROOT_DIRECTORY}/keys/${ENVIRONMENT}/.keys/savup/${KEY_NAME}
  build_remote_instance_login
  print_parameters
  sleep 10

  if [ ! -d "$ROOT_DIRECTORY" ]; then
    display_error "Directory $ROOT_DIRECTORY DOES NOT exists. Edit the 'Directory and files' section at the top of the script to match your system."
    exit 9
  fi

  nats_running Y
  remove_nats
  install_nats_tools
  add_exports_copy_files
  create_operator_system
  create_account
  create_resolver
  # create_server_config without TLS setting so push works
  BYPASS_TLS="true"
  create_server_config
  start_server
  nats_running N
  push_accounts_users
  create_user
  create_contexts
  # create_server_config WITH TLS setting so push works
  BYPASS_TLS="false"
  create_server_config

  display_info "You will need to copy this file, if you are going to use SYS remotely:"
  echo $NATS_MP/SYS_SIGNED_KEY_LOCATION.nk
  display_info "which is on $GC_INSTANCE_NAME and locate it on the SavUp server so it has access to the NATS message server."
  display_info "The location where the file should be placed can be found in the SavUp server configuration file."
  display_info
  clean_up
  display_spacer
  display_info "READ READ READ"
  display_info "READ READ READ"
  display_info "READ READ READ"
  display_info "READ READ READ"
  display_info "================================ MUST DO ================================"
  display_info "=======> Post installation steps:"
  display_info "=======> 1) run the nats-gen-user-credentials.sh script on the nats server"
  display_info "=======> 2) copy the nats credentials to the nats-savup.creds file in your keys directory"
  display_info "=======> 3) update the AWS System Manager Parameter Store for the environment!"
}

init_script
run_script "$@"
