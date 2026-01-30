{{/* vim: set filetype=mustache: */}}
{{/*
  Common HTTPRoute definition with deterministic names and labels:
  {{ include "common.httproutes" . }}
*/}}

{{- define "common.httproutes" -}}
{{- $envoy := .Values.envoy | default dict -}}
{{- if $envoy.enabled -}}
{{- $gateway := default (dict "name" "gateway-api" "namespace" "envoy-gateway") $envoy.gateway -}}
{{- $httproutes := default (list) $envoy.httpRoutes -}}
{{- $baseName := include "common.fullname" . -}}
{{- $globalLabels := include "common.labels" . -}}
{{- $serviceNamespace := .Release.Namespace -}}
{{- $security := default dict $envoy.security -}}
{{- $securityEnabled := default false $security.enabled -}}
{{- $securityLabelKey := printf "%s/security-required" (include "common.parcellabtagsdomain" .) -}}

{{- range $index, $route := $httproutes }}
{{- $hosts := required (printf "envoy.httpRoutes[%d].hosts is required" $index) $route.hosts -}}
{{- if eq (len $hosts) 0 -}}
{{- fail (printf "envoy.httpRoutes[%d].hosts cannot be empty" $index) -}}
{{- end -}}
{{- $rawRouteName := default (printf "%s-%d" $baseName $index) $route.name -}}
{{- $sanitizedRouteName := trunc 63 (trimSuffix "-" (regexReplaceAll "[^a-z0-9-]" (lower $rawRouteName) "-")) -}}
{{- $routeName := default (printf "%s-%d" $baseName $index) $sanitizedRouteName }}
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ $routeName }}
  namespace: {{ $serviceNamespace }}
  labels:
    {{- $globalLabels | nindent 4 }}
    {{ $securityLabelKey }}: {{ (ternary "true" "false" $securityEnabled) | quote }}
    {{- with $route.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  annotations:
    external-dns.alpha.kubernetes.io/hostname: |
    {{- range $hosts }}
      {{ . }}
    {{- end }}
spec:
  parentRefs:
    - name: {{ $gateway.name }}
      namespace: {{ $gateway.namespace }}
      group: gateway.networking.k8s.io
      kind: Gateway
  hostnames:
  {{- range $hosts }}
    - {{ . | quote }}
  {{- end }}
  {{- with $route.rules }}
  rules:
    {{ toYaml . | nindent 4 }}
  {{ end }}
{{ end }}
{{- end }}
{{- end }}
