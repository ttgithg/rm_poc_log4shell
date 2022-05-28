#! /bin/bash
#
# Provisioning script for log4jlab

#------------------------------------------------------------------------------
# Bash settings
#------------------------------------------------------------------------------

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't mask errors in piped commands

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
# Provision actions
#------------------------------------------------------------------------------

log ">>> Start Script: baseconfig.sh >>>"

#------------------------------------------------------------------------------
# Provision server - main_1 method call
#------------------------------------------------------------------------------

log "Starting BASE provisioning tasks on ${HOSTNAME}"

main_1() {
    local extra_bashuser="kauser"
    # local wait="5"

    keyboard_config
    update_upgrade_clean_system
    guest_additions_packages_install
    create_user "${extra_bashuser}"
    # reboot_forced "${wait}"
}

#------------------------------------------------------------------------------
# keyboard-time
#------------------------------------------------------------------------------

#dpkg-reconfigure keyboard-configuration
#setxkbmap -layout be && timedatectl set-timezone Europe/Brussels
#sudo service keyboard-setup restart

keyboard_config() {
    keyboardConfig="keyboard"
    fromPath="/vagrant/provisioning/files/log4jlab/${keyboardConfig}"
    toPath="/etc/default/keyboard"

    if ! cat ${toPath} | grep "be" >/dev/null 2>&1; then
        log "Copying keyboard configuration to ${toPath}"
        cp "${toPath}" "${toPath}.ORI"
        cp "${fromPath}" "${toPath}"
    else
        log "Belgium keyboard already configured"
    fi
}

#------------------------------------------------
# update/upgrade
#------------------------------------------------

update_upgrade_clean_system() {
    log "updating the package sources list"
    apt update >/dev/null 2>&1
    # log "updating all packages"
    # apt full-upgrade
    # log "removing unused dependencies"
    # apt autoremove
}

#------------------------------------------------------------------------------
# virtualbox guest additions
#------------------------------------------------------------------------------

guest_additions_packages_install() {
    if ! lsmod | grep "vboxguest" >/dev/null 2>&1; then
        log "Installing packages: VirtualBox Guest Additions"
        install_package virtualbox-guest-x11 >/dev/null 2>&1
    else
        log "VirtualBox Guest Additions already installed"
    fi
    log " -> $(dpkg -l | awk '{$1=""; print $0}' | grep -oP 'virtualbox-guest-x11.{0,14}')"
    log " -> $(dpkg -l | awk '{$1=""; print $0}' | grep -oP 'virtualbox-guest-utils.{0,14}')"
}

#------------------------------------------------------------------------------
# extra bash user vs default zsh user
#------------------------------------------------------------------------------

create_user() {
    local user="${1}"

    log "Ensure user ${user} exists"
    if ! getent passwd "${user}" >/dev/null 2>&1; then
        log " -> added user: ${user}"
        useradd -m -s /usr/bin/bash -p '$6$lwSyCkfsfs1XhiU6$.mg66RtWkCyTtmdUcCGKLprfOtD59qTIWPwzl1/gNrhpetMoP04yrNaxfuPlGlAIoW2HyZbCJ4IESrYSAS7io/' -G adm,dialout,cdrom,floppy,sudo,audio,dip,video,plugdev,netdev,bluetooth,scanner,kaboxer,vboxsf kauser
    else
        log " -> user ${user} already exists"
    fi
    log " -> $(getent passwd ${user})"
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
# main_1 method call
#------------------------------------------------------------------------------

main_1

log "<<< End Script: baseconfig.sh <<<"
log ""
