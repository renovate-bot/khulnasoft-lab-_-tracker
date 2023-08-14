# Install **Tracker** on Kubernetes

In the [deploy/](https://github.com/khulnasoft-lab/tracker/tree/{{ git.tag}}/deploy) directory you will find Yaml files to deploy Tracker
in a Kubernetes environment either with **Helm** or with a static yaml.

!!! Tip
    The **preferred** way to deploy **Tracker** is through its [Helm] chart!

[Helm]: https://helm.sh

1. Install **Tracker** using **Helm**

	1. Add KhulnaSoft chart repository:

		```console
		helm repo add khulnasoft https://khulnasoft-lab.github.io/helm-charts/
		helm repo update
		```

		or clone the Helm chart:

		```console
		git clone --depth 1 --branch {{ git.tag }} https://github.com/khulnasoft-lab/tracker.git
		cd tracker
		```


	2. Install the chart from the KhulnaSoft chart repository:

		```console
		helm install tracker khulnasoft/tracker \
				--namespace tracker-system --create-namespace
		```
  
		or install the Helm chart from a local directory:

		```console
		helm install tracker ./deploy/helm/tracker \
				--namespace tracker-system --create-namespace
		```

2. Install **Tracker** **Manually**

    To install Tracker 
    
    ```console
    kubectl create namespace tracker-system
    kubectl create -n tracker-system \
        -f https://raw.githubusercontent.com/khulnasoft-lab/tracker/main/deploy/kubernetes/tracker/tracker.yaml
    ```

[HERE]: https://github.com/khulnasoft-lab/postee/blob/main/cfg.yaml

## Platform Support

This approach assumes that host nodes have either BTF available or kernel
headers available under conventional location. See Tracker's
[prerequisites](../installing/prerequisites.md) for more info. For the major
Kubernetes platforms this should work out-of-the-box, including GKE, EKS, AKS,
minikube.

[deploy/kubernetes]:https://github.com/khulnasoft-lab/tracker/blob/{{ git.tag }}/deploy/kubernetes
