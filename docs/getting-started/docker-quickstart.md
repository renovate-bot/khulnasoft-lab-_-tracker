# Docker Quickstart

You can easily start experimenting with Tracker using the Docker image as follows:

```console
docker run \
  --name tracker --rm -it \
  --pid=host --cgroupns=host --privileged \
  -v /etc/os-release:/etc/os-release-host:ro \
  khulnasoft/tracker:latest
```

To learn how to install Tracker in a production environment, [check out the Kubernetes guide](./kubernetes-quickstart).
