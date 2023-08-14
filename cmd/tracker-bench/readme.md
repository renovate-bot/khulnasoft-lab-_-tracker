# Documentation

`tracker-bench` is a promQL based tool to query `tracker` runtime performance metrics.
It can be used to benchmark tracker's event pipeline's (see [here](https://khulnasoft-lab.github.io/tracker/dev/architecture/)) performance on your environment.

## Enabling Prometheus

In order to use prometheus with tracker see [this](https://khulnasoft-lab.github.io/tracker/dev/integrating/prometheus/) documentation.
A simple script for running a prometheus container scraping tracker is available in this repository in `prometheus.sh`.

## Metrics tracked

`tracker-bench` tracks three important stats about tracker's performance in your environment:1
1. Avg rate of events emitted per second
2. Avg rate of events lost per second
3. Overall events lost

Ideal performance of tracker should have a stable throughput of events emitted with minimal event loss. If heavy event loss occurs, consider tuning tracker either through [filtering](https://khulnasoft-lab.github.io/tracker/dev/tracing/event-filtering/) or allocating additional CPU (if running on kubernetes).
