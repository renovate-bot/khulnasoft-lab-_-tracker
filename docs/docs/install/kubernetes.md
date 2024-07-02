# Installing Tracker in Kubernetes 

This guide will help you get started with Tracker by installing it in a Kubernetes cluster.  


## Prerequisites

- Supported environment - please refer to the [Prerequisites](../install/prerequisites.md)
- Kubernetes - this was tested on [minikube](https://github.com/kubernetes/minikube), but should work the same with most other Kubernetes distributions
- [Helm](https://helm.sh/docs/intro/install/)

<details>
  <summary>Verify step</summary>
```console
kubectl get po -A
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
helm repo add khulnasoft https://khulnasoft-lab.github.io/helm-charts/
helm repo update
helm install tracker khulnasoft/tracker --namespace tracker --create-namespace
```

<details>
  <summary>Verify step</summary>
```console
kubectl get pods -n tracker
```

```text
NAME           READY   STATUS    RESTARTS   AGE 
tracker-fcjmp   1/1     Running   0          4m11s
```
</details>

Once installed, Tracker immediately starts producing events. Since Tracker is deployed as a DaemonSet, a Tracker Pod is running on every node in the cluster. Every Tracker Pod is monitoring the node it is running on.

## Viewing Events

The easiest way to tap into the log stream of all Tracker Pods is with the `kubectl logs` command:

```console
kubectl logs -f daemonset/tracker -n tracker
```

!!! Note
    Tracker can produce a very high volume of events which could overwhelm kubectl's log collection command. If run in a busy cluster or with a verbose policy, this command might be slow or unresponsive.

In production scenario you would probably want to collect and ship events logs into a persistent storage that you can query.   
You can use any log collection solution of your choosing. We have a tutorial on how to do this using the open source Grafana Stack [here](../../tutorials/deploy-grafana-dashboard.md).

## Applying Policies

By default, Tracker collects a basic set of events that gives you a general overview of the cluster. If you're looking to do more with Tracker, You might want to create a new [Policy](../policies/index.md). A policy lets you capture specific set of events from a specific set of workloads. For example, if you have an application that you want to monitor more closely, or in a specialized way, you can create a policy scoped to that application, with a different set of events and filters applied. To learn more, please refer to the [Events](../events/index.md) and [Policies](../policies/index.md) sections.

When you are ready to apply a policy, it's as easy as `kubectl apply -f your-policy.yaml`. More details [here](../policies/usage/kubernetes.md).

## Configuring Tracker

In some cases you will need to configure Tracker to your preferences. For example, to change the output event format, or to set a different log level. To learn more about available configuration options please see the [configuration](../install/config/index.md) section.

Tracker's configuration is accessible as a ConfigMap in Kubernetes. Since we installed Tracker with Helm, you can also configure Tracker with it, for example: `helm upgrade tracker --set config.cache.size=1024`. More details [here](../install/config/kubernetes.md).

## Optional: Exercising a security event

To see Tracker in action, let's simulate a security event. We'll do a "file-less" execution, which is a common evasion technique used by some malware, and is flagged by Tracker as suspicious activity. To simulate this, we'll use the [tracker-tester](https://registry.hub.docker.com/r/khulnasoft/tracker-tester) example image it will simulate the suspicious activity without harming your environment.

```console
kubectl run tracker-tester --image=khulnasoft/tracker-tester -- TRC-105
```

You can see the event in the logs:

```console
kubectl logs -f ds/tracker -n tracker | grep fileless_execution 
```

## Next steps

Familiarize with the different events, filters, and configuration options in the [documentation](../overview.md).

Read other [tutorials](../../tutorials/overview.md).

For help and support, feel free to use [GitHub Discussions](https://github.com/khulnasoft-lab/tracker/discussions).


## Video Content

If you prefer a video version of the Kubernetes installation guide, have a look at the following video:

Getting started with eBPF in Kubernetes - Tracker Installation Guide 

[![Watch the video](../../images/ebpftrackerhelminstall.png)](https://youtu.be/YQdEvf2IS9k?si=LhQM0CI8_QKvOCeK)
