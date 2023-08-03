---
hide:
- toc
---
![Tracker Logo >](images/tracker.png)

Before moving on, please consider giving us a star ⭐️
by clicking the button at the top of the [GitHub page](https://github.com/khulnasoft-labs/tracker/)

# Tracker Documentation

👋 Welcome to Tracker Documentation! To help you get around, please notice the different sections at the top global menu:

- You are currently in the [Getting Started](./) section where you can find general information and help with first steps.
- In the [Tutorials](./tutorials/overview) section you can find step-by-step guides that help you accomplish specific tasks.
- In the [Docs](./docs/overview) section you can find the complete reference documentation for all of the different features and settings that Tracker has to offer.
- In the [Contributing](./contributing/overview) section you can find technical developer documentation and contribution guidelines.

# Tracker: Runtime Security and Forensics using eBPF

Tracker uses eBPF technology to tap into your system and give you access to hundreds of events that help you understand how your system behaves.
In addition to basic observability events about system activity, Tracker adds a collection of sophisticated security events that expose more advanced behavioral patterns. You can also easily add your own events using the popular [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) language.
Tracker provides a rich filtering mechanism that allows you to eliminate noise and focus on specific workloads that matter most to you.

## Quickstart

You can easily start experimenting with Tracker using the Docker image as follows:

```console
docker run \
  --name tracker --rm -it \
  --pid=host --cgroupns=host --privileged \
  -v /etc/os-release:/etc/os-release-host:ro \
  aquasec/tracker:latest
```

To learn how to install Tracker in a production environment, [check out the Kubernetes guide](./getting-started/kubernetes-quickstart).

---

Tracker is an [KhulnaSoft](https://aquasec.com) open source project.  
Learn about our open source work and portfolio [Here](https://www.aquasec.com/products/open-source-projects/).  
Join the community, and talk to us about any matter in [GitHub Discussion](https://github.com/khulnasoft-labs/tracker/discussions) or [Slack](https://slack.aquasec.com).  
