{{- define "common.waf" -}}
{{- $waf := .route.waf | default dict -}}
{{- if $waf.enabled }}
{{- $config := required (printf "HTTPRoute %q requires waf.config" .routeName) $waf.config -}}
{{- if or (not (kindIs "map" $config)) (empty $config) -}}
{{- fail (printf "HTTPRoute %q requires waf.config to be a non-empty map" .routeName) -}}
{{- end -}}
{{- if not (kindIs "bool" $waf.failOpen) -}}
{{- fail (printf "HTTPRoute %q requires an explicit waf.failOpen boolean" .routeName) -}}
{{- end }}
---
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyExtensionPolicy
metadata:
  name: {{ default (printf "%s-waf" .routeName) $waf.name }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- .globalLabels | nindent 4 }}
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: {{ .routeName }}
  wasm:
    - name: coraza
      failOpen: {{ $waf.failOpen }}
      code:
        type: Image
        image:
          # Proxy-Wasm 0.6.0: Coraza 3.3.3 / OWASP CRS 4.14.0.
          url: ghcr.io/corazawaf/coraza-proxy-wasm@sha256:65d6009b9da2e8965e592a08b74a86725435fc01aa39c756dce0bd5ea64b3f4e
      config:
        {{- toYaml $config | nindent 8 }}
{{- end }}
{{- end -}}
