# common

[![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/common)](https://artifacthub.io/packages/helm/parcellab/common) [![Test](https://github.com/parcelLab/charts/actions/workflows/test.yaml/badge.svg)](https://github.com/parcelLab/charts/actions/workflows/test.yaml)

Common Helm templates that abstract code marks to other charts.

## Route-scoped Coraza WAF

The monolith and microservice charts share Coraza policy rendering through
`common.httproutes`. Applications opt in individual HTTPRoutes:

```yaml
envoy:
  enabled: true
  httpRoutes:
    - name: public-route
      hosts:
        - public.example.com
      waf:
        enabled: true
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          backendRefs:
            - name: my-app
              port: 80
```

WAF defaults to off for every route. `waf.enabled: false` omits its
`EnvoyExtensionPolicy`; Helm upgrade or GitOps pruning removes an existing policy,
so on/off trials compare against no filter. Disabling `envoy.enabled` also omits
all WAF policies. There is no gateway-wide opt-in and no automatic SSO selection:
choose public routes explicitly. GRPCRoutes are not covered.

The policy targets the rendered HTTPRoute name in the release namespace. Its
name defaults to `<route-name>-waf`; optional `waf.name` preserves an existing
policy's identity during migration. Names must be unique within the namespace.

`templates/_waf.tpl` owns the shared digest-pinned Proxy-Wasm image and policy
defaults. Applications do not need to configure an image or copy directives.
Updating the common library and releasing new consuming charts distributes WAF
updates through application chart dependency upgrades.

The initial policy is detection-only and fails open on Wasm runtime failure.
It uses Proxy-Wasm 0.6.0 (Coraza 3.3.3 / CRS 4.14.0), paranoia level 1 defaults,
request inspection up to 128 KiB with partial inspection above that limit, and no
response-body inspection. Full audit and debug logs are disabled, but native
detection messages can contain matched values, client IPs and request URIs.
Review log access, redaction and retention before using real customer data.

Envoy Gateway with Wasm-capable `EnvoyExtensionPolicy` support must already be
installed. This chart does not install a proxy or a standalone Coraza service.
Policy acceptance and HTTP success alone are not proof of inspection: verify
synthetic detections on every proxy replica. Detection-only does not block attacks.

The upstream [release notes](https://github.com/corazawaf/coraza-proxy-wasm/releases/tag/0.6.0)
warn of memory leaks and performance degradation. Start with a staging trial,
monitor shared proxy CPU/memory, errors and application-specific downstream
latency, and compare equal off/on/off windows before expanding coverage.

Run the shared WAF regression checks after building both consuming charts:

```sh
helm dependency update parcellab/microservice
helm dependency update parcellab/monolith
npm run test:waf
```

The WAF workflow runs these tests for pull requests and main without requiring
Node dependencies beyond the built-in test runner.
