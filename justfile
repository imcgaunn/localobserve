#!/usr/bin/env just

set dotenv-load := true

run-collector :
  ./scripts/run_standalone_collector.sh

run-observe-backend :
  ./scripts/run_standalone_observe_backend.sh

run-in-panels :
  ./scripts/run_everything_in_panels.sh

shfmt :
  fd -e sh -X shfmt -i 4 -w {}
