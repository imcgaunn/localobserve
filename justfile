#!/usr/bin/env just

set dotenv-load := true

default :
  @just --list

run-collector :
  ./scripts/run_standalone_collector.sh

run-dd-collector :
  DD_API_KEY=$DD_API_KEY ./scripts/run_standalone_datadog_collector.sh

run-vector :
  ./scripts/run_vector.sh

run-observe-backend :
  ./scripts/run_standalone_observe_backend.sh

run-in-panels :
  ./scripts/run_everything_in_panels.sh

shfmt :
  fd -e sh -X shfmt -i 4 -w {}
