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

readonly LOGFILE="/home/ubuntu/init-TODO/bootstrap.log"
readonly REPO_URL="https://github.com/Bhuvaneshloop/todo-deployment.git"
readonly REPO_NAME="todo-deployment"
readonly REPO_PATH="/home/ubuntu/${REPO_NAME}"

# Use the provided tags, otherwise default to latest
readonly BACKEND_TAG="${BACKEND_TAG:-latest}"
readonly UI_TAG="${UI_TAG:-latest}"

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

    log INFO "Installing Docker, Docker Compose and Git..."

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

    if [[ -d "$REPO_PATH" ]]; then

        log INFO "Repository already exists."

        cd "$REPO_PATH"

        log INFO "Pulling latest repository changes..."

        git pull

    else

        log INFO "Cloning deployment repository..."

        git clone "$REPO_URL" "$REPO_PATH"

        cd "$REPO_PATH"

    fi

    log INFO "Repository location: $(pwd)"
}

#######################################
# Prepare Environment File
#######################################

prepare_env() {

    cp .env.example .env

    sed -i "s+^BACKEND_TAG=.*+BACKEND_TAG=${BACKEND_TAG}+" .env
    sed -i "s+^UI_TAG=.*+UI_TAG=${UI_TAG}+" .env

    log INFO ".env created."
    log INFO "Backend tag: ${BACKEND_TAG}"
    log INFO "UI tag: ${UI_TAG}"
}

#######################################
# Deploy Containers
#######################################

deploy() {

    log INFO "Pulling Docker images..."

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
            exit 1
        fi
    done
}

#######################################
# Main
#######################################

main() {

    log INFO "Bootstrap Started."

    log INFO "Backend tag: ${BACKEND_TAG}"
    log INFO "UI tag: ${UI_TAG}"

    install_packages

    clone_repository

    prepare_env

    deploy

    verify

    log INFO "Bootstrap Completed Successfully."
}

main "$@"
