#! /bin/bash
#
# Provisioning script common for all servers

#------------------------------------------------------------------------------
# Bash settings
#------------------------------------------------------------------------------

# Enable "Bash strict mode"
set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't mask errors in piped commands

#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

#Users & Groups
#readonly USER='kauser'

#------------------------------------------------------------------------------
# Provisioning tasks
#------------------------------------------------------------------------------

#log 'Starting common provisioning tasks'

#log 'Turning on SELinux and making it enforcing'
#setenforce 1
