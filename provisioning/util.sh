#! /bin/bash
#
# Utility functions that are useful in all provisioning scripts.

#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

# Set to 'yes' if debug messages should be printed.
readonly debug_output='yes'

#------------------------------------------------------------------------------
# Logging and debug output
#------------------------------------------------------------------------------
# Three levels of logging are provided: log (for messages you always want to
# see), debug (for debug output that you only want to see if specified), and
# error (obviously, for error messages).

# Usage: log [ARG]...
#
# Prints all arguments on the standard error stream
log() {
  printf '\e[0;33m[LOG]  %s\e[0m\n' "${*}" 1>&2
}

# Usage: debug [ARG]...
#
# Prints all arguments on the standard error stream
debug() {
  if [ "${debug_output}" = 'yes' ]; then
    printf '\e[0;36m[DBG] %s\e[0m\n' "${*}" 1>&2
  fi
}

# Usage: error [ARG]...
#
# Prints all arguments on the standard error stream
error() {
  printf '\e[0;31m[ERR] %s\e[0m\n' "${*}" 1>&2
}

#------------------------------------------------------------------------------
# Useful tests
#------------------------------------------------------------------------------

# Usage: files_differ FILE1 FILE2
#
# Tests whether the two specified files have different content
#
# Returns with exit status 0 if the files are different, a nonzero exit status
# if they are identical.
files_differ() {
  local file1="${1}"
  local file2="${2}"

  # If the second file doesn't exist, it's considered to be different
  if [ ! -f "${file2}" ]; then
    return 0
  fi

  local -r checksum1=$(md5sum "${file1}" | cut -c 1-32)
  local -r checksum2=$(md5sum "${file2}" | cut -c 1-32)

  [ "${checksum1}" != "${checksum2}" ]
}


#------------------------------------------------------------------------------
# SELinux
#------------------------------------------------------------------------------

# Usage: ensure_sebool VARIABLE
#
# Ensures that an SELinux boolean variable is turned on
ensure_sebool()  {
  local -r sebool_variable="${1}"
  local -r current_status=$(getsebool "${sebool_variable}")

  if [ "${current_status}" != "${sebool_variable} --> on" ]; then
    setsebool -P "${sebool_variable}" on
  fi
}

#------------------------------------------------------------------------------
# User management
#------------------------------------------------------------------------------

# Usage: ensure_user_exists USERNAME
#
# Create the user with the specified name if it doesn’t exist
ensure_user_exists() {
  local user="${1}"
  log "Ensure user ${user} exists"
  if ! getent passwd "${user}"; then
    log " -> user added"
    useradd "${user}"
  else
    log " -> already exists"
  fi
}

# Usage: ensure_group_exists GROUPNAME
#
# Creates the group with the specified name, if it doesn’t exist
ensure_group_exists() {
  local group="${1}"

  log "Ensure group ${group} exists"
  if ! getent group "${group}"; then
    log " -> group added"
    groupadd "${group}"
  else
    log " -> already exists"
  fi
}

# Usage: assign_groups USER GROUP...
#
# Adds the specified user to the specified groups
assign_groups() {
  local user="${1}"
  shift
  log "Adding user ${user} to groups: ${*}"
  while [ "$#" -ne "0" ]; do
    usermod -aG "${1}" "${user}"
    shift
  done
}

#------------------------------------------------------------------------------
# App management
#------------------------------------------------------------------------------

install_package() {
  local pkg="${1}"
  shift
  log "Installing ${pkg}"
  apt -y install ${pkg}
}

enable_service(){
  local pkg="${1}"
  shift
  log "enabling and starting up ${pkg}"
  systemctl enable --now ${pkg}.service
}

restart_service(){
  local pkg="${1}"
  shift
  log "restarting ${pkg}"
  systemctl restart ${pkg}.service
}

ensure_path_exists(){
  local path2dir="${1}"
  if [ ! -d ${path2dir} ];then
    log "Directory ${path2dir} wordt aangemaakt ..."
    mkdir ${path2dir}
  else
    log "Directory ${path2dir} bestaat reeds"
  fi
}

check_filepath_exists(){
  local path2file="${1}"
  if [ ! -f ${path2file} ];then
    log "Filepath ${path2file} bestaat niet ..."
    bestaat=0
  else
    log "Filepath ${path2file} bestaat reeds ..."
    bestaat=1
  fi
}

#------------------------------------------------------------------------------
# firewall management
#------------------------------------------------------------------------------

ensure_firewall_up(){
if ! systemctl status firewalld | grep "active (running)"; then
  log "Enabling and starting up Firewall .."
  systemctl enable --now firewalld
else
  log "Firewall reeds up en running"
fi
}

add_to_firewall(){
  local service="${1}"
  log "Ensure Firewall ${service} rule exists"
  if [ ! $(firewall-cmd --list-services | grep -ow ${service}) ]; then
    log " -> adding ${service} rule to pass through firewall"
    firewall-cmd --add-service=${service} --permanent
    firewall-cmd --reload
  else
    log " -> ${service} rule already exists"
  fi
}