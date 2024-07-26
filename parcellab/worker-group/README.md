# worker-group

[![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/worker-group)](https://artifacthub.io/packages/helm/parcellab/worker-group) [![Test](https://github.com/parcelLab/charts/actions/workflows/test.yaml/badge.svg)](https://github.com/parcelLab/charts/actions/workflows/test.yaml)

Generic helm chart to create worker applications.

## Introduction

This chart creates workers with commonly used Kubernetes resources
using the [Helm](https://helm.sh) package manager. The goal is to allow the
consumers to toggle resources that are common in most deployment scenarios.

### Essential resources

These resources will always be provisioned, as they are essential to define
what we consider an "application".

- `deployment`

Every element defined in the `workers` list will create a different deployment, without
a service, as such workloads are expected to run indefinitely without network traffic.

### Togglable resources

These resources can be configured or totally skipped depending on your business
needs.
 
- `configmap`
  - The attributes defined in `config` will automatically be loaded as environment
    variables to the target pod.
- `externalsecret` -> `secret`
  - An [external secret](https://external-secrets.io/) can be defined with the `externalSecret` setting.
    Its generated secret's data values will be loaded as environment variables to the target pod.
- `hpa`
  - Horizontal automatic scaling rules of pods. Can be defined with the `autoscaling` setting.
- `poddisruptionbudget`
  - Limit the number of concurrent disruptions for the application. Defined with `podDisruptionBudget`.
- `serviceaccount`
  - Configure a service account for the pods. Defined with `serviceAccount`.
- `vpa`
  - Set up vertical pod autoscaling. Defined with `vpa`.

## Installing the Chart

Add the `parcellab` charts repo:

```sh
helm repo add parcellab https://charts.parcellab.dev
```

Install the chart:

```bash
helm install --name my-worker-group-name parcellab/microservice
```

## Uninstalling the Chart

To delete the deployed chart:

```bash
helm uninstall my-worker-group-name
```

The command removes all the Kubernetes components associated with the chart
and deletes the release.

## Updating the Chart

You can update the chart values and trigger a pod reload.
If the configmap changes, it will automatically retrieve the new values.

```bash
helm upgrade -f values.yaml my-worker-group-name parcellab/worker-group
```
