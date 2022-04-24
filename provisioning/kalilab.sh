#! /bin/bash
#
# Provisioning script for srv001

#------------------------------------------------------------------------------
# Bash settings
#------------------------------------------------------------------------------

# Enable "Bash strict mode"
set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't mask errors in piped commands

#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

# Location of provisioning scripts and files
export readonly PROVISIONING_SCRIPTS="/vagrant/provisioning"
# Location of files to be copied to this server
export readonly PROVISIONING_FILES="${PROVISIONING_SCRIPTS}/files/${HOSTNAME}"

#------------------------------------------------------------------------------
# "Imports"
#------------------------------------------------------------------------------

# Utility functions
source ${PROVISIONING_SCRIPTS}/util.sh
# Actions/settings common to all servers
source ${PROVISIONING_SCRIPTS}/common.sh

#------------------------------------------------------------------------------
# Provision server - main method call
#------------------------------------------------------------------------------

log "Starting PROVISIONING tasks on ${HOSTNAME}"
log ""

main() {
    # local wait="5"

    run_script1_baseconfiguration
    run_script2_labconfiguration
    # reboot_forced "${wait}"
}

#------------------------------------------------------------------------------
# run script 1: base configuration
#------------------------------------------------------------------------------

run_script1_baseconfiguration(){
    log "------------------"
    log "BASE CONFIGURATION"
    log ""
    bash ${PROVISIONING_SCRIPTS}/${HOSTNAME}/baseconfig.sh
}

#------------------------------------------------------------------------------
# run script 2: lab configuration
#------------------------------------------------------------------------------

run_script2_labconfiguration(){
    log "------------------"
    log "LAB CONFIGURATION"
    log ""
    bash ${PROVISIONING_SCRIPTS}/${HOSTNAME}/labconfig.sh
}

#------------------------------------------------------------------------------
# Reboot
#------------------------------------------------------------------------------

reboot_forced() {
    local wait="${1}"

    log "reboot in ${wait} seconds"
    sleep "${wait}"
    reboot
    #reboot friendly
    #echo 'Reboot? (y/n)' && read x && [[ "$x" == "y" ]] && /sbin/reboot;
}

#------------------------------------------------------------------------------
# main method call
#------------------------------------------------------------------------------

main
