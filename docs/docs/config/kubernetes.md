# Kubernetes Config

## Configmap

Tracker ConfigMap exposed [tracker configuration](https://github.com/khulnasoft-labs/tracker/blob/main/examples/config/global_config.yaml) to the deployment.

```
---
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
    perf-buffer-size: 1024
    containers: true
    healthz: false
    metrics: true
    pprof: false
    pyroscope: false
    listen-addr: :3366
    log:
        - info
    output:
        - json
        - option:parse-arguments
```

## Customizing

You can customize specific options with the helm installation:

```
# setting blob-perf-event-size
helm install tracker khulnasoft/tracker \
        --namespace tracker-system --create-namespace \
        --set config.blobPerfEventSize=1024


# setting a different output
helm install tracker khulnasoft/tracker \
        --namespace tracker-system --create-namespace \
				--set config.output[0]=table
				--set config.output[1]=option:parse-arguments
```

Or you can pass a config file directly:

```
 helm install tracker khulnasoft/tracker \
        --namespace tracker-system --create-namespace \
				--set-file trackerConfig=<path/to/config/file>
```
