# Local K8s cluster with Istio

Be sure all the pods are perfectly deployed at every steps. To do so, type `kubectl get pods -A`.

## Dependencies

- Install k3d

```
curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
```

- Install istioctl

```
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.6.8 TARGET_ARCH=x86_64 sh -
sudo mv istio-1.6.8/bin/istioctl /usr/bin
```

## Setup

- Create the cluster

```
k3d cluster create -a 3 --no-lb --k3s-server-arg '--no-deploy=traefik'
```

- Create the Istio namespace

```
kubectl create namespace istio-system
```

- Create the Istio manifests

```
istioctl manifest generate | kubectl apply -f -
```

Note: Add `--set values.prometheus.enabled=false` to install without Prometheus

- Create the base Istio resources

```
kubectl apply -f base-istio.yml
```

- Deploy Keycloak

```
kubectl apply -f keycloak.yml
```

- Add entries to /etc/hosts

```
echo "127.0.0.1   keycloak.keycloak.svc.cluster.local" >> /etc/hosts
echo "127.0.0.1   svc-test-app.demo-one.svc.cluster.local" >> /etc/hosts
echo "127.0.0.1   svc-test-app.demo-two.svc.cluster.local" >> /etc/hosts
```

- Open port-forwarding

```
kubectl port-forward -n istio-system service/istio-ingressgateway 8080:80
```

- Provision Keycloak with dummy resources

```
./provision.sh
```

- Deploy first dummy application

```
kubectl apply -f demo-one.yml
```

## Testing Istio with Keycloak

- Open https://oidcdebugger.com/

```
Authorize URI (required): http://keycloak.keycloak.svc.cluster.local:8080/auth/realms/test-istio/protocol/openid-connect/auth
Redirect URI (required):  https://oidcdebugger.com/debug
Client ID (required):     test-client-oidcdebugger
Scope (required):         openid
Response type (required): token
```

- Press [SEND REQUEST]

- Authenticate on Keycloak

```
Username: john.doe@domain.com
Password: john.doe@domain.com
```

- Press [LOGIN]

- Copy the Access Token

```
export TOKEN="<token-here>"
```

- Call the service using JWT

```
curl --header "Authorization: Bearer $TOKEN" http://svc-test-app.demo-one.svc.cluster.local:8080/demo-one
```

## Testing Istio with a Keycloak Service Account

- Deploy second dummy application

```
kubectl apply -f demo-two.yml
```

- Get a JWT

```
export TOKEN=$(curl --silent --request POST http://keycloak.keycloak.svc.cluster.local:8080/auth/realms/test-istio/protocol/openid-connect/token --header "Content-Type: application/x-www-form-urlencoded" --data "client_id=test-service-account&client_secret=cedddd8f-e84b-453d-b86f-8d571cc99fd1&grant_type=client_credentials" | jq -r ".access_token")
```

- Call the service using JWT

```
curl --header "Authorization: Bearer $TOKEN" http://svc-test-app.demo-two.svc.cluster.local:8080/demo-two
```

## Links

- [Keycloak](http://keycloak.keycloak.svc.cluster.local:8080/auth/)
- [Demo-one](http://svc-test-app.demo-one.svc.cluster.local:8080/demo-one)
- [Demo-two](http://svc-test-app.demo-two.svc.cluster.local:8080/demo-two)

## Teardown

- Remove the cluster

```
k3d cluster delete
```

