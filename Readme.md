![Tracker Logo](docs/images/tracker.png)

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/khulnasoft-labs/tracker)](https://github.com/khulnasoft-labs/tracker/releases)
[![License](https://img.shields.io/github/license/khulnasoft-labs/tracker)](https://github.com/khulnasoft-labs/tracker/blob/main/LICENSE)
[![docker](https://badgen.net/docker/pulls/khulnasoft/tracker)](https://hub.docker.com/r/khulnasoft/tracker)

# Tracker: Runtime Security and Forensics using eBPF

Tracker uses eBPF technology to tap into your system and give you access to hundreds of events that help you understand how your system behaves.
In addition to basic observability events about system activity, Tracker adds a collection of sophisticated security events that expose more advanced behavioral patterns. You can also easily add your own events using the popular [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) language.
Tracker provides a rich filtering mechanism that allows you to eliminate noise and focus on specific workloads that matter most to you.

To learn more about Tracker, check out the [documentation](https://khulnasoft-labs.github.io/tracker).

## Quickstart

You can easily start experimenting with Tracker using the Docker image as follows:

```console
docker run \
  --name tracker --rm -it \
  --pid=host --cgroupns=host --privileged \
  -v /etc/os-release:/etc/os-release-host:ro \
  -v /boot/config-$(uname -r):/boot/config-$(uname -r):ro \
  khulnasoft/tracker:$(uname -m)
```

To learn how to install Tracker in a production environment, [check out the Kubernetes guide](https://khulnasoft-labs.github.io/tracker/latest/getting-started/kubernetes-quickstart).

---

Tracker is an [KhulnaSoft](https://khulnasoft.com) open source project.  
Learn about our open source work and portfolio [Here](https://www.khulnasoft.com/products/open-source-projects/).  
Join the community, and talk to us about any matter in [GitHub Discussion](https://github.com/khulnasoft-labs/tracker/discussions) or [Slack](https://slack.khulnasoft.com).  
