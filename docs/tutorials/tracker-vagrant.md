# Using the Tracker container image on MacOS with Parallels and Vagrant

There are a few more steps involved in running Tracker through a container image on arm64 (M1).

Prerequisites:

* [Vagrant CLI](https://developer.hashicorp.com/vagrant/downloads) installed
* [Parallels Pro](https://www.parallels.com/uk/products/desktop/pro/) installed

First, clone the Tracker Git repository and move into the root directory:

```console
git clone git@github.com:khulnasoft-lab/tracker.git

cd tracker
```

Next, use Vagrant to start a Parallels VM:

```console
vagrant up
```

This will use the [Vagrantfile](https://github.com/khulnasoft-lab/tracker/blob/main/Vagrantfile) in the root of the Tracker directory.

Lastly, ssh into the created VM:

```console
vagrant ssh
```

Now, it is possible to run the Tracker Container image:

```shell
docker run --name tracker -it --rm \
  --pid=host --cgroupns=host --privileged \
  -v /etc/os-release:/etc/os-release-host:ro \
  -v /var/run:/var/run:ro \
  khulnasoft/tracker:latest
```

To learn how to install Tracker in a production environment, [check out the Kubernetes guide](./kubernetes-quickstart).
