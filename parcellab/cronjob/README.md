# cronjob

Generic helm chart for Kubernetes cronjobs.

## Introduction

This chart creates cronjobs with commonly used Kubernetes resources
using the [Helm](https://helm.sh) package manager. The goal is to allow the
consumers to toggle resources that are common in most deployment scenarios.

### Essential resources

These resources will always be provisioned, as they are essential to define
what we consider a "cronjob".

- `cronjob`

### Togglable resources

These resources can be configured or totally skipped depending on your business
needs.

- `configmap`
  - The attributes defined in `config` will automatically be loaded as environment
    variables to the target cronjob pod.
- `externalsecret` -> `secret`
  - An [external secret](https://external-secrets.io/) can be defined with the `externalSecret` setting.
    Its generated secret's data values will be loaded as environment variables to the target cronjob pod.
- `serviceaccount`
  - Configure a service account for the cronjob pods. Defined with `serviceAccount`.

## Installing the Chart

Add the `parcellab` charts repo:

```sh
helm repo add parcellab https://charts.parcellab.dev
```

Install the chart:

```bash
helm install --name my-cronjob-name parcellab/cronjob
```

## Uninstalling the Chart

To delete the deployed chart:

```bash
helm uninstall my-cronjob-name
```

The command removes all the Kubernetes components associated with the chart
and deletes the release.

## Updating the Chart

You can update the chart values and trigger a pod reload.
If the configmap changes, it will automatically retrieve the new values.

```bash
helm upgrade -f values.yaml my-cronjob-name parcellab/cronjob
```
