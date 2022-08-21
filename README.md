# The parcelLab Library for Kubernetes

Popular applications and helm libraries, provided by parcelLab, ready to launch
on Kubernetes using Kubernetes Helm.

## Usage

[Helm](https://helm.sh) must be installed to use the charts. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

```sh
helm repo add parcellab https://charts.parcellab.dev
```

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages. You can then run `helm search repo parcellab` to see the charts.

To install the `chart-name` chart:

```sh
helm install <chart-name> parcellab/<chart-name>
```

To uninstall the chart:

```sh
helm delete <chart-name>
```

## Development

The helm charts are automatically packaged and pushed via Github actions to
the `gh-pages` as described in the [Helm Guide](https://helm.sh/docs/topics/chart_repository/#github-pages-example)
with the [Chart Releaser Action](https://helm.sh/docs/howto/chart_releaser_action/).
