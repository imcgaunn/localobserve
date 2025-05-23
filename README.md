# localobserve

this repo is meant to serve as a more or less standalone playground
for experimenting with an opentelemetry collector and the `openobserve`
project, which is a locally hosted alternative to products like datadog for general
application observability tasks like viewing traces, logs, and metrics.

if you are me, this repo is also meant to serve as a reminder of how to
do this kind of thing.

## usage

NOTE: For a brand new setup, to get the otel collector working with
the openobserve backend that gets started by `run_standalone_observe_backend.sh`
you will most likely need to change the authorization token provided in the `Authorization:` header in `scripts/cfg/otelcol.yaml` to the one generated by `openobserve` the first time it starts.

generally, you can start everything up with `just run-in-panels` at a shell prompt. you will need to have `just` installed, along with `docker` and `tmux`
which will be used to run each component of the stack in its own pane in a
new session so it is easier to manage the running environment as a single unit,and to make it easier to view logs for the services as you are tweaking things.
