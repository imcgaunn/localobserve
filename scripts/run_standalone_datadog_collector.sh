#!/bin/zsh

setopt err_exit
setopt no_unset
setopt pipe_fail

export CONFIG_DIR="${0:A:h}/cfg"
export OTEL_COLLECTOR_GRPC_PORT="${OTEL_COLLECTOR_GRPC_PORT:-4317}"
export OTEL_COLLECTOR_CONTAINER_NAME="${OTEL_COLLECTOR_CONTAINER_NAME:-local-otel-coll}"

export OTEL_COLLECTOR_IMAGE="ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib"
export OTEL_COLLECTOR_IMAGE_TAG="0.124.0"

export OPENOBSERVE_AUTH_HEADER="${OPENOBSERVE_AUTH_HEADER}"

function die() {
    local msg="$1"
    printf "%s\n" "${msg}" >&2
    exit 222
}

function stop_collector() {
    # stop collector program started earlier
    printf "stopping collector container %s\n" "${OTEL_COLLECTOR_CONTAINER_NAME}"
    docker kill "${OTEL_COLLECTOR_CONTAINER_NAME}" >/dev/null 2>&1 || true
    docker rm "${OTEL_COLLECTOR_CONTAINER_NAME}" >/dev/null 2>&1 || true
    printf "stopped collector container ${OTEL_COLLECTOR_CONTAINER_NAME}"
}

function start_collector() {
    local collector_port="$1"
    # start the collector program listening on the desired grpc port
    printf "starting collector on port %s\n" "${collector_port}"
    # run the container with all of my wonderful settings
    # and detach from it, while keeping stdin open and allocating a tty
    docker create -i -t \
        --name=${OTEL_COLLECTOR_CONTAINER_NAME} \
        -p 44317:${OTEL_COLLECTOR_GRPC_PORT} \
        -e "DD_API_KEY=$DD_API_KEY" \
        -e "OPENOBSERVE_AUTH_HEADER=$OPENOBSERVE_AUTH_HEADER" \
        --network observe \
        --mount type=bind,src=/etc/localtime,dst=/etc/localtime,ro \
        --mount type=bind,src=${CONFIG_DIR}/otelcoldatadog.yaml,dst=/etc/otelcol-contrib/config.yaml \
        --tmpfs=/tmp:rw,noexec,nosuid,size=128m \
        "${OTEL_COLLECTOR_IMAGE}:${OTEL_COLLECTOR_IMAGE_TAG}" || die "could not create container"
    printf "started container [name=%s]\n" "${OTEL_COLLECTOR_CONTAINER_NAME}"
    # attach the container's in/out file descriptors
    docker start -ia ${OTEL_COLLECTOR_CONTAINER_NAME}
}

function cleanup() {
    # do any necessary cleanup here to make sure program doesn't
    # leave something running after exit.
    printf "cleanup called\n"
    stop_collector
}

# call cleanup function on exit to remove anything
# we may have created
trap 'cleanup' EXIT
start_collector "${OTEL_COLLECTOR_GRPC_PORT}" || die "failed to start collector"
