# Running Tracker with Docker

This guide will help you get started with running Tracker as a container.

## Prerequisites

- Review the [prerequisites for running Tracker](./prerequisites.md)
- If you are an Apple Mac user, please read [the Mac FAQ](../advanced/mac.md)
- Ensure that you have Docker or a compatible container runtime

## Tracker container image

 Tracker container image is available in Docker Hub as [khulnasoft/tracker](https://hub.docker.com/r/khulnasoft/tracker).

- You can use the `latest` tag or a named version version e.g `khulnasoft/tracker:{{ git.tag }}`.
- If you are trying the most cutting edge features, there is also a `dev` tag which is built nightly from source.
- The Tracker image is a [Multi-platform](https://docs.docker.com/build/building/multi-platform/) image that includes a x86 and arm64 flavors. You can also access the platform-specific images directly with the `aarch64` and `x86_64` tags for the latest version or `aarch64-<version>` and `x86_64-<version>` for a specific version.  
- For most first time users, just use `khulnasoft/tracker`!

## Running Tracker container

 Here is the docker run command, we will analyze it next:

```shell
docker run --name tracker -it --rm \
  --pid=host --cgroupns=host --privileged \
  -v /etc/os-release:/etc/os-release-host:ro \
  -v /var/run:/var/run:ro \
  khulnasoft/tracker:latest
```

 1. Docker general flags:
    - `--name` - name our container so that we can interact with it easily.
    - `--rm` - remove the container one it exits, assuming this is an interactive trial of Tracker.
    - `-it` - allow the container to interact with your terminal.
 2. Since Tracker runs in a container but is instrumenting the host, it will need access to some resources from the host:
    - `--pid=host` - share the host's [process namespace]() with Tracker's container.
    - `--cgroupns-host` - share the host's [cgroup namespace]() with Tracker's container.
    - `--privileged` - run the Tracker container as root so it has all the [required capabilities](./prerequisites.md#process-capabilities).
    - `-v /etc/os-release:/etc/os-release-host:ro` - share the host's [OS information file](./prerequisites.md#os-information) with the Tracker container.
    - `-v /var/run:/var/run` - share the host's container runtime socket for [container enrichment](./container-engines.md)

 After running this command, you should start seeing a stream of events that Tracker is emitting.

 For next steps, please read about Tracker [Policies](../policies/index.md)

## Installing Tracker

 If you are looking to permanently install Tracker, you would probably do the following:

 1. Remove interactive flags `-it` and replace with daemon flag `-d`
 2. Consider how to collect events from the container.

 Or you can follow the [Kubernetes guide](./kubernetes.md) which addresses these concerns.
