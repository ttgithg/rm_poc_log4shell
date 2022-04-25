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

log ">>> Start Script: labconfig.sh >>>"

#------------------------------------------------------------------------------
# Provision server - main_2 method call
#------------------------------------------------------------------------------

log "Starting LAB provisioning tasks on ${HOSTNAME}"

main_2() {
    local dockergrp="docker"
    local dockerusr1="vagrant"
    local dockerusr2="kauser"
    local gitrepo="https://github.com/kozmer/log4j-shell-poc.git"
    local destdir="/log4jlab"
    local pip_requirements=("colorama" "argparse")
    # local wait="5"

    packages_curl_install
    packages_wget_install
    dockerlab_packages_pip_install
    dockerlab_packages_python3_install
    dockerlab_packages_docker_install
    give_group_multiple_users "${dockergrp}" "${dockerusr1}" "${dockerusr2}"
    ensure_docker_service_enabled
    ensure_docker_service_running
    dockerlab_packages_docker-compose_install
    ensure_path_exists "${destdir}"
    clone_gitrepo2destdir "${gitrepo}" "${destdir}"
    vulnerable_jdk2gitrepodir
    dockerlab_pip_requirements_install "${pip_requirements[*]}"
    # reboot_forced "${wait}"
}

#------------------------------------------------------------------------------
# curl
#------------------------------------------------------------------------------

packages_curl_install() {
    if ! curl -V | grep -oP "curl .{0,28}" >/dev/null 2>&1; then
        log "Installing packages: curl"
        install_package curl
    else
        log "curl already installed"
    fi
    log " -> $(curl -V | grep -oP 'curl .{0,28}')"
}

#------------------------------------------------------------------------------
# wget
#------------------------------------------------------------------------------

packages_wget_install() {
    if ! wget -V | grep "built" >/dev/null 2>&1; then
        log "Installing packages: wget"
        install_package wget >/dev/null 2>&1
    else
        log "wget already installed"
    fi
    log " -> $(wget -V | grep -oP '.{5,10}built.{0,13}')"
}

#------------------------------------------------------------------------------
# pip
#------------------------------------------------------------------------------

dockerlab_packages_pip_install() {
    if ! pip -V >/dev/null 2>&1; then
        log "Installing packages: pip"
        install_package pip >/dev/null 2>&1
    else
        log "pip already installed"
    fi
    log " -> $(pip -V | grep -oP 'pip.{0,7}' | head -1)"
}

#------------------------------------------------------------------------------
# python3
#------------------------------------------------------------------------------

dockerlab_packages_python3_install() {
    if ! python3 -V >/dev/null 2>&1; then
        log "Installing packages: python3"
        install_package python3 >/dev/null 2>&1
    else
        log "python3 already installed"
    fi
    log " -> $(python3 -V)"
}

#------------------------------------------------------------------------------
# docker
#------------------------------------------------------------------------------

dockerlab_packages_docker_install() {

    if ! docker -v >/dev/null 2>&1; then
        log "setting-up docker repository"
        log " -> updating the package sources list"
        apt update >/dev/null 2>&1
        log " -> allowing apt over https"
        install_package apt-transport-https >/dev/null 2>&1
        log " -> allowing 3rd party certificate verification"
        install_package ca-certificates >/dev/null 2>&1
        log " -> allowing digital encryption and signing services"
        if ! gpg --version >/dev/null 2>&1; then
            log "    Installing packages: gnupg"
            install_package gnupg >/dev/null 2>&1
        else
            log "    gnupg already installed"
        fi
        log "     -> $(gpg --version | grep 'GnuPG')"
        log " -> allowing management from where software is installed"
        install_package software-properties-common >/dev/null 2>&1
        log " -> adding docker's GPG key"
        curl -fsSL "http://download.docker.com/linux/debian/gpg" | gpg --dearmor -o "/usr/share/keyrings/docker-archive-keyring.gpg"
        log " -> setting-up stable repository"
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian buster stable" | tee "/etc/apt/sources.list.d/docker.list" >/dev/null 2>&1
        #echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee "/etc/apt/sources.list.d/docker.list"
        log " -> updating the package sources list"
        apt update >/dev/null 2>&1

        log "Installing packages: docker (docker-ce, docker-ce-cli, containerd.io)"
        install_package docker-ce >/dev/null 2>&1
        install_package docker-ce-cli >/dev/null 2>&1
        install_package containerd.io >/dev/null 2>&1
    else
        log "docker already installed"
    fi
    log " -> $(docker -v)"
}

#------------------------------------------------------------------------------
# docker users and group
#------------------------------------------------------------------------------

give_group_multiple_users() {
    local group="${1}"
    shift

    while [ "${#}" -ne "0" ]; do
        if ! id -nG "${1}" | grep -qw "${group}"; then
            # log "Adding user ${1} to group: ${group}"
            # usermod -aG "${group}" "${1}"
            assign_groups "${1}" "${group}"
        else
            log "user ${1} already belongs to group: ${group}"
        fi
        shift
    done

    # log "changing current GID (group ID) during login session"
    # newgrp ${group}
}

#------------------------------------------------------------------------------
# docker.service
#------------------------------------------------------------------------------

ensure_docker_service_enabled() {
    if ! systemctl status docker.service | grep "vendor preset: enabled" >/dev/null 2>&1; then
        log "enabling docker.service"
        enable_service docker.service
    else
        log "docker.service already enabled"
    fi
}

ensure_docker_service_running() {
    if ! systemctl status docker.service | grep "active (running)" >/dev/null 2>&1; then
        log "starting docker.service"
        restart_service docker.service
    else
        log "docker.service already running"
    fi
}

#------------------------------------------------------------------------------
# docker-compose
#------------------------------------------------------------------------------

dockerlab_packages_docker-compose_install() {
    if ! docker-compose version >/dev/null 2>&1; then
        # curl -L "https://github.com/docker/compose/releases/download/v2.4.1/docker-compose-linux-x86_64" -o "/usr/local/bin/docker-compose"
        downloadDC() {
            curl -L "https://github.com/docker/compose/releases/download/$(curl https://github.com/docker/compose/releases | grep -m1 '<a href="/docker/compose/releases/download/' | grep -o 'v[0-9:].[0-9].[0-9]')/docker-compose-$(uname -s)-$(uname -m)" -o "/usr/local/bin/docker-compose"
        }

        log "Installing packages: docker-compose"
        downloadDC >/dev/null 2>&1
        chmod +x "/usr/local/bin/docker-compose"
        #ln -s "/usr/local/bin/docker-compose" "/usr/bin/docker-compose"
    else
        log "docker-compose already installed"
    fi
    log " -> $(docker-compose version)"
}

#------------------------------------------------------------------------------
# cloning gitrepo to destination
#------------------------------------------------------------------------------

clone_gitrepo2destdir() {
    local gitrepo="${1}"
    local destdir="${2}"

    if [ -d "${destdir}" ]; then
        if [ "$(ls -A ${destdir})" ]; then
            log "${destdir} is not Empty"
        else
            log "cloning gitrepo in ${destdir}"
            git clone "${gitrepo}" "${destdir}"
        fi
    else
        log "${destdir} not found"
    fi
}

#------------------------------------------------------------------------------
# Copy vulnerable jdk to cloned repo / poc
#------------------------------------------------------------------------------

vulnerable_jdk2gitrepodir() {
    jdk=jdk-8u20-linux-x64.tar.gz
    provisionDir="/vagrant/provisioning/files/log4jlab"
    jdkPath="${provisionDir}/${jdk}"
    destdir="/log4jlab"

    if [ ! -f "${destdir}/${jdk}" ]; then
        log "Copying vulnerable jdk: ${jdk} to ${destdir}"
        cp -r "${jdkPath}" "${destdir}"
        if [ -f "${destdir}/${jdk}" ]; then
            tar -xf "${destdir}/${jdk}" "${destdir}"
        fi
    else
        log "vulnerable jdk: ${jdk} already in ${destdir}"
    fi
}

#------------------------------------------------------------------------------
# Install cloned repo / poc Requirements
#------------------------------------------------------------------------------

dockerlab_pip_requirements_install() {
    local reqs=(${1})

    for req in "${reqs[@]}"; do
        if ! python3 -m pip show ${req} >/dev/null 2>&1; then
            log "Installing python requirement: ${req}"
            pip install ${req} >/dev/null 2>&1
            log "${req} Installed"
        else
            log "Python requirement: ${req} already installed"
        fi
        log " -> ${req} version $(python3 -m pip show ${req} | grep -oP 'Version: \K.*')"
    done
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
# main_2 method call
#------------------------------------------------------------------------------

main_2

log "<<< End Script: labconfig.sh <<<"
log ""