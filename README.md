# Getting Started with Charm Tracing

This README is a quick-start guide that shows how to deploy a minimal tracing setup and view your charm’s traces in action.

## Prerequisites

On your machine, make sure you have the following prerequisites met:

- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) >= v1.5
- [Juju](https://snapcraft.io/juju) >= 3.6.0
- [Charmcraft](https://snapcraft.io/charmcraft) >= 3
- A bootsrapped K8s Juju controller

## Add a COS K8s model
This is the juju K8s model where the testing tracing setup will be deployed

```bash
juju add-model cos
```

## Deploy a testing tracing setup
In this directory, use `terraform` to deploy the module:
```bash
terraform -chdir=terraform init
terraform -chdir=terraform apply -var="model=cos" -auto-approve
```
Wait for a couple of minutes (~6m) until all deployed charms are in active/idle.

## Instrument your charm with ops[tracing]
TODO

## Deploy & Integrate your charm with Tempo
After instrumenting your charm, pack and deploy it:
```bash
cd <charm-path>
charmcraft pack
juju deploy <charm-path> $(yq eval '.resources | to_entries | map("--resource \(.key)=\(.value.upstream-source)") | .[]' charmcraft.yaml)
```

### K8s charm
Then, if it's a K8s charm, integrate it directly with Tempo
```bash
juju integrate <your-charm-app-name>:charm-tracing tempo
```

### Machine charm
If it's a machine charm, it's recommended to use the `cos_agent` interface.

1. In the COS K8s model:

```bash
juju offer tempo:tracing
```

2. In your machine model, deploy an otel collector

```bash
juju deploy opentelemetry-collector otelcol --channel 2/edge
```

3. Integrate your charm with otel collector over `cos-agent`
```bash
juju integrate <your-charm-app-name> otelcol:cos-agent
```

4. CMR with Tempo:
```bash
juju consume <k8s-controller>:admin/cos.tempo
juju integrate otelcol:send-traces tempo
```
> It's ok if `otelcol` is in `blocked/idle`. Charm traces should still go through.
## See your charm traces in action

To open Grafana's UI, In your COS K8s model, you can:
```bash
juju run grafana/0 get-admin-password
```
That should provide you with grafana's ingressed url that you can open from your browser + an initial admin password that you can use to login.

```
username: admin
password: <whatever was outputted from the juju action>
```

Then,
1. Open the `Toggle Menu`(☰) in the top-left corner
2. Select `Explore`
3. In the datasource dropdown, choose your Tempo datasource
4. Use the Filters section to search for your charm’s `Service Name`
5. Click `Run query` to view traces from your charm


Now, all what's left is to inspect your spans and look for potentials bottlenecks! 🔍