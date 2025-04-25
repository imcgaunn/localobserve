#!/bin/zsh

setopt no_unset
setopt err_exit
setopt pipe_fail

export SCRIPT_DIR="${0:A:h}"
export CONFIG_DIR="${SCRIPT_DIR}/cfg"
export VECTOR_DATA_DIR="${SCRIPT_DIR}/../data/vector"
export LOG_DATA_DIR="${SCRIPT_DIR}/../data/logs"

export DD_API_KEY="$DD_API_KEY"
export DD_ENV="dev"
export DD_SERVICE="imcg-thruput-vector"
export DD_VERSION="0.9.0-imcg"

export VECTOR_CONTAINER_NAME="localobserve-vector"
export VECTOR_IMAGE_NAME="timberio/vector"
export VECTOR_IMAGE_TAG="0.37.1-debian"
export DOCKER_NETWORK="observe"

function cleanup() {
    logger -s "$(printf "cleanup called\n")"
    stop_vector
    logger -s "$(printf "cleanup completed\n")"
}

function force_stop_container() {
    local container_name="$1"
    logger -s "$(printf "stopping container [name=%s]\n" "${container_name}")"
    docker stop -t 5 "${container_name}" >/dev/null 2>&1 || true
    docker rm "${container_name}" >/dev/null 2>&1 || true
    logger -s "$(printf "stopped container [name=%s]\n" "${container_name}")"
}

function die() {
    local msg="$1"
    logger -s "$(printf "%s\n" "${msg}")"
    exit 222
}

function start_vector() {
    docker create -i -t \
        --name "${VECTOR_CONTAINER_NAME}" \
        --network "${DOCKER_NETWORK}" \
        -e DD_API_KEY=${DD_API_KEY} \
        -e DD_ENV=${DD_ENV} \
        -e DD_SERVICE=${DD_SERVICE} \
        -e DD_VERSION=${DD_VERSION} \
        -e DD_TAGS="poc-name:localobserve" \
        --mount type=bind,src=${CONFIG_DIR}/vector.files.yaml,dst=/etc/vector/vector.yaml \
        --mount type=bind,src=${VECTOR_DATA_DIR},dst=/var/lib/vector \
        --mount type=bind,src=${LOG_DATA_DIR},dst=/tmp/logs \
        ${VECTOR_IMAGE_NAME}:${VECTOR_IMAGE_TAG} || die "could not create container ${VECTOR_CONTAINER_NAME}"
    docker start -ia "${VECTOR_CONTAINER_NAME}"
    logger -s "$(printf "Started container [name=%s]\n" "${VECTOR_CONTAINER_NAME}")"
}

function stop_vector() {
    force_stop_container "${VECTOR_CONTAINER_NAME}"
}

trap 'cleanup' EXIT
start_vector || die "could not start ${VECTOR_CONTAINER_NAME}"
