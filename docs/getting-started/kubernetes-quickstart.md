# Getting started with tracker in Kubernetes 

This guide was tested using [minikube](https://github.com/kubernetes/minikube), an easy way to run Kubernetes on your development machine, but should work the same with most other Kubernetes clusters.

## Prerequisites

- minikube - see installation instructions [here](https://minikube.sigs.k8s.io/docs/start/). Note that Tracker doesn't support ARM/Apple silicon yet.
- Helm - see installation instructions and dependencies [here](https://helm.sh/docs/intro/install/).

<details>
  <summary>Verify step</summary>
```console
minikube start && kubectl get po -A
```

```text
NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE 
kube-system   coredns-565d847f94-kd9xx           1/1     Running   0          15s 
kube-system   etcd-minikube                      1/1     Running   0          26s 
kube-system   kube-apiserver-minikube            1/1     Running   0          26s 
kube-system   kube-controller-manager-minikube   1/1     Running   0          26s 
kube-system   kube-proxy-cvqjm                   1/1     Running   0          15s 
kube-system   kube-scheduler-minikube            1/1     Running   0          26s 
kube-system   storage-provisioner                1/1     Running   0          15s 
``` 
</details>

## Install Tracker

The provided Helm chart will install Tracker as a DaemonSet so that it's tracing all the nodes in the cluster.

```console
helm repo add khulnasoft https://khulnasoft-labs.github.io/helm-charts/
helm repo update
helm install tracker khulnasoft/tracker --namespace tracker-system --create-namespace
```

<details>
  <summary>Verify step</summary>
```console
kubectl get pods
```

```text
NAME           READY   STATUS    RESTARTS   AGE 
tracker-fcjmp   1/1     Running   0          4m11s
```
</details>

## Interacting with Tracker

Once installed, Tracker immediately starts producing system activity events, such as processes and containers activity, network activity, and more. To see the events that Tracker produces, use can use the `kubectl logs` command.

```console
kubectl logs -f daemonset/tracker -n tracker-system
```

In production scenario you would want to collect and ship the events to a persistent storage.

## Exercising a security event

To see Tracker in action, let's simulate a security event. We'll do a "file-less" execution, which is a common evasion technique used by some malware, and is flagged by Tracker as suspicious activity. To simulate this, we'll use the [tracker-tester](https://registry.hub.docker.com/r/khulnasoft/tracker-tester) example image it will simulate the suspicious activity without harming your environment.

```console
kubectl run tracker-tester --image=khulnasoft/tracker-tester -- TRC-105
```

You can see the event in the logs:

```console
kubectl -n tracker-system logs -f ds/tracker | grep fileless_execution 
```

<details>
  <summary>Result</summary>
```json
{
  "timestamp": 1671119128028881186,
  "threadStartTime": 883410317491,
  "processorId": 1,
  "processId": 9,
  "cgroupId": 8972,
  "threadId": 9,
  "parentProcessId": 8,
  "hostProcessId": 6136,
  "hostThreadId": 6136,
  "hostParentProcessId": 6135,
  "userId": 0,
  "mountNamespace": 4026532816,
  "pidNamespace": 4026532817,
  "processName": "3",
  "hostName": "tracker-tester",
  "containerId": "c7e3c75bf167348bf79262bf6e688088f9b4d54ebcc79464f40b52b80c73ff55",
  "containerImage": "docker.io/khulnasoft/tracker:latest",
  "containerName": "tracker",
  "podName": "tracker-wk8wh",
  "podNamespace": "tracker-system",
  "podUID": "5cb83966-e274-48f1-89fb-25bd748d2773",
  "eventId": "6023",
  "eventName": "fileless_execution",
  "argsNum": 15,
  "returnValue": 0,
  "stackAddresses": null,
  "syscall": "execve",
  "contextFlags": {
    "containerStarted": true,
    "isCompat": false
  },
  "args": [
    {
      "name": "cmdpath",
      "type": "const char*",
      "value": "/dev/fd/3"
    },
    {
      "name": "pathname",
      "type": "const char*",
      "value": "memfd: "
    },
    {
      "name": "dev",
      "type": "dev_t",
      "value": 1
    },
    {
      "name": "inode",
      "type": "unsigned long",
      "value": 1033
    },
    {
      "name": "ctime",
      "type": "unsigned long",
      "value": 1671119128024105994
    },
    {
      "name": "inode_mode",
      "type": "umode_t",
      "value": 33279
    },
    {
      "name": "interpreter_pathname",
      "type": "const char*",
      "value": "/lib/x86_64-linux-gnu/ld-2.28.so"
    },
    {
      "name": "interpreter_dev",
      "type": "dev_t",
      "value": 234
    },
    {
      "name": "interpreter_inode",
      "type": "unsigned long",
      "value": 1704546
    },
    {
      "name": "interpreter_ctime",
      "type": "unsigned long",
      "value": 1671118551446622730
    },
    {
      "name": "argv",
      "type": "const char**",
      "value": [
        ""
      ]
    },
    {
      "name": "interp",
      "type": "const char*",
      "value": "/dev/fd/3"
    },
    {
      "name": "stdin_type",
      "type": "string",
      "value": "S_IFCHR"
    },
    {
      "name": "stdin_path",
      "type": "char*",
      "value": "/dev/null"
    },
    {
      "name": "invoked_from_kernel",
      "type": "int",
      "value": 0
    }
  ]
}
```
</details>

## Next steps

Familiarize with the different events, filters, and configuration options in the [documentation](./../docs/overview.md).

Read other [tutorials](./../tutorials/overview.md).

For help and support, feel free to use [GitHub Discussions](https://github.com/khulnasoft-labs/tracker/discussions).

