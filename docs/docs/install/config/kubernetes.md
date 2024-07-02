# Configuring Tracker in Kubernetes

In Kubernetes, Tracker uses a ConfigMap, called `tracker` to make Tracker configuration accessible. The ConfigMap includes a data file called `config.yaml` with the desired configuration. For example:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/name: tracker
    app.kubernetes.io/component: tracker
    app.kubernetes.io/part-of: tracker
  name: tracker
data:
  config.yaml: |-
    cache:
      - cache-type=mem
      - mem-cache-size=512
```

## Kubectl

You can use `kubectl` to interact with it:

View:

```shell
kubectl get cm tracker-config -n tracker
```

Edit:

```shell
kubectl edit cm tracker-config -n tracker
```

## Helm

You can customize specific options with the helm installation:

```
helm install tracker khulnasoft/tracker \
        --namespace tracker --create-namespace \
        --set config.blobPerfBufferSize=1024
```

or after installation:

```
helm install tracker khulnasoft/tracker \
        --namespace tracker --create-namespace \
        --set config.output.format=table
```

or to provide a complete config file:

```
 helm install tracker khulnasoft/tracker \
        --namespace tracker --create-namespace \
        --set-file configFile=myconfig.yaml
```
