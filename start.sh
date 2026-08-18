#!/usr/bin/env bash

# =============================================================================
# Author      : Bhuvanesh
# Description : Bootstrap a fresh Ubuntu server by installing Docker,
#               Docker Compose, cloning the deployment repository,
#               and deploying the Todo application.
# =============================================================================

set -Eeuo pipefail

#######################################
# Global Variables
#######################################

readonly LOGFILE="$HOME/init-TODO/bootstrap.log"
readonly REPO_URL="https://github.com/Bhuvaneshloop/todo-deployment.git"
readonly REPO_NAME="todo-deployment"

mkdir -p "$(dirname "$LOGFILE")"

#######################################
# Logging Function
#######################################

log() {
    local level="$1"
    shift

    local message="$*"
    local timestamp

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" | tee -a "$LOGFILE"
}

#######################################
# Install Docker & Compose
#######################################

install_packages() {

    log INFO "Updating package index..."

    sudo apt update

    log INFO "Installing Docker..."

    sudo apt install -y docker.io docker-compose-v2 git

    sudo systemctl enable docker
    sudo systemctl start docker

    if command -v docker >/dev/null 2>&1; then
        log INFO "Docker Installed Successfully."
    else
        log ERROR "Docker Installation Failed."
        exit 1
    fi

    if docker compose version >/dev/null 2>&1; then
        log INFO "Docker Compose Installed Successfully."
    else
        log ERROR "Docker Compose Installation Failed."
        exit 1
    fi

    if command -v git >/dev/null 2>&1; then
        log INFO "Git Installed Successfully."
    else
        log ERROR "Git Installation Failed."
        exit 1
    fi
}

#######################################
# Clone Repository
#######################################

clone_repository() {

    if [[ -d "$REPO_NAME" ]]; then

        log INFO "Repository already exists."

        cd "$REPO_NAME"

        git pull

    else

        log INFO "Cloning deployment repository..."

        git clone "$REPO_URL"

        cd "$REPO_NAME"

    fi
}

#######################################
# Prepare Environment File
#######################################

prepare_env() {

    if [[ ! -f ".env" ]]; then

        cp .env.example .env

        log INFO ".env created."

    else

        log INFO ".env already exists."

    fi
}

#######################################
# Deploy Containers
#######################################

deploy() {

    log INFO "Pulling latest Docker images..."

    sudo docker compose pull

    log INFO "Starting Containers..."

    sudo docker compose up -d
}

#######################################
# Verify Deployment
#######################################

verify() {

    local containers=(
        postgres
        todo-app
        todo-ui
    )

    for container in "${containers[@]}"
    do
        if sudo docker ps --format "{{.Names}}" | grep -qw "$container"
        then
            log INFO "$container is running."
        else
            log ERROR "$container is NOT running."
        fi
    done
}

#######################################
# Main
#######################################

main() {

    log INFO "Bootstrap Started."

    install_packages

    clone_repository

    prepare_env

    deploy

    verify

    log INFO "Bootstrap Completed Successfully."
}

main "$@"
