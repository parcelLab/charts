# microservice

[![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/microservice)](https://artifacthub.io/packages/helm/parcellab/microservice) ![Test](https://github.com/parcelLab/charts/actions/workflows/test.yaml/badge.svg)](https://github.com/parcelLab/charts/actions/workflows/test.yaml)

Generic helm chart to create a Kubernetes microservice.

## Introduction

This chart creates a microservice with commonly used Kubernetes resources
using the [Helm](https://helm.sh) package manager. The goal is to allow the
consumers to toggle resources that are common in most deployment scenarios.

### Essential resources

These resources will always be provisioned, as they are essential to define
what we consider an "application".

- `deployment`
- `service`

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
- `ingress`
  - Rules to open external access to the workload. Can be defined with `ingress`.
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
helm install --name my-microservice-name parcellab/microservice
```

## Uninstalling the Chart

To delete the deployed chart:

```bash
helm uninstall my-microservice-name
```

The command removes all the Kubernetes components associated with the chart
and deletes the release.

## Updating the Chart

You can update the chart values and trigger a pod reload.
If the configmap changes, it will automatically retrieve the new values.

```bash
helm upgrade -f values.yaml my-microservice-name parcellab/microservice
```
