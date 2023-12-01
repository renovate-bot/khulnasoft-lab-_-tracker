---
hide:
- toc
---
![Tracker Logo >](images/tracker.png)

👋 Welcome to Tracker Documentation! To help you get around, please notice the different sections at the top global menu:

- You are currently in the [Getting Started](./) section where you can find general information and help with first steps.
- In the [Tutorials](./tutorials/overview) section you can find step-by-step guides that help you accomplish specific tasks.
- In the [Docs](./docs/overview) section you can find the complete reference documentation for all of the different features and settings that Tracker has to offer.
- In the [Contributing](./contributing/overview) section you can find technical developer documentation and contribution guidelines.

<!-- links that differ between docs and readme -->
[installation]:./docs/install/index.md
[docker-guide]:./docs/install/docker.md
[kubernetes-guide]:./docs/install/kubernetes.md
[prereqs]:./docs/install/prerequisites.md
[macfaq]:./docs/advanced/mac.md
<!-- everything below is copied from readme -->

Before moving on, please consider giving us a GitHub star ⭐️. Thank you!

## About Tracker

Tracker is a runtime security and observability tool that helps you understand how your system and applications behave.  
It is using [eBPF technology](https://ebpf.io/what-is-ebpf/) to tap into your system and expose that information as events that you can consume.  
Events range from factual system activity events to sophisticated security events that detect suspicious behavioral patterns.

To learn more about Tracker, check out the [documentation](https://khulnasoft-lab.github.io/tracker/). 

## Quickstart

To quickly try Tracker use one of the following snippets. For a more complete installation guide, check out the [Installation section][installation].  
Tracker should run on most common Linux distributions and kernels. For compatibility information see the [Prerequisites][prereqs] page. Mac users, please read [this FAQ](macfaq).

### Using Docker

```shell
docker run --name tracker -it --rm \
  --pid=host --cgroupns=host --privileged \
  -v /etc/os-release:/etc/os-release-host:ro \
  -v /var/run:/var/run:ro \
  khulnasoft/tracker:latest
```

For a complete walkthrough please see the [Docker getting started guide][docker-guide].

### On Kubernetes

```shell
helm repo add khulnasoft https://khulnasoft-lab.github.io/helm-charts/
helm repo update
helm install tracker khulnasoft/tracker --namespace tracker --create-namespace
```

```shell
kubectl logs --follow --namespace tracker daemonset/tracker
```

For a complete walkthrough please see the [Kubernetes getting started guide][kubernetes-guide].

## Contributing
  
Join the community, and talk to us about any matter in the [GitHub Discussions](https://github.com/khulnasoft-lab/tracker/discussions) or [Slack](https://slack.khulnasoft.com).  
If you run into any trouble using Tracker or you would like to give use user feedback, please [create an issue.](https://github.com/khulnasoft-lab/tracker/issues)

Find more information on [contribution documentation](./contributing/overview/).

## More about Khulnasoft Security

Tracker is an [Khulnasoft Security](https://khulnasoft.com) open source project.  
Learn about our open source work and portfolio [here](https://www.khulnasoft.com/products/open-source-projects/).
