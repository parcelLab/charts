{{- define "common.waf" -}}
{{- $waf := .route.waf | default dict -}}
{{- if $waf.enabled }}
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
      # Detection-only must not turn a Wasm runtime failure into an app outage.
      failOpen: true
      code:
        type: Image
        image:
          # Proxy-Wasm 0.6.0: Coraza 3.3.3 / OWASP CRS 4.14.0.
          url: ghcr.io/corazawaf/coraza-proxy-wasm@sha256:65d6009b9da2e8965e592a08b74a86725435fc01aa39c756dce0bd5ea64b3f4e
      config:
        directives_map:
          default:
            - Include @recommended-conf
            - SecRuleEngine DetectionOnly
            - SecResponseBodyAccess Off
            - SecRequestBodyLimit 131072
            - SecRequestBodyInMemoryLimit 131072
            - SecRequestBodyLimitAction ProcessPartial
            - SecAuditEngine Off
            - SecDebugLogLevel 0
            - Include @crs-setup-conf
            - Include @owasp_crs/REQUEST-*.conf
        default_directives: default
{{- end }}
{{- end -}}
