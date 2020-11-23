# Local K8s cluster with Istio

Be sure all the pods are perfectly deployed at every steps. To do so, type `kubectl get pods -A`.

## Dependencies

- Install k3d

`curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash`

- Install istioctl

`curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.6.8 TARGET_ARCH=x86_64 sh -`
`sudo mv istio-1.6.8/bin/istioctl /usr/bin`

## Setup

- Create the cluster

`k3d cluster create -a 3 --no-lb --k3s-server-arg '--no-deploy=traefik'`

- Create the Istio namespace

`kubectl create namespace istio-system`

- Create the Istio manifests

`istioctl manifest generate | kubectl apply -f -`

Note: Add `--set values.prometheus.enabled=false` to install without Prometheus

- Create the base resources

`kubectl apply -f base-istio.yml`

- Deploy dummy application

`kubectl apply -f kube.yml`

- Open port-forwarding

`kubectl port-forward -n istio-system service/istio-ingressgateway 8080:80`

- Enjoy

`curl http://localhost:8080`

## Teardown

- Remove the cluster

`k3d cluster delete`

