{{/* vim: set filetype=mustache: */}}
{{/*
  Common GRPCRoute definition with deterministic names and labels:
  {{ include "common.grpcroutes" . }}
*/}}

{{- define "common.grpcroutes" -}}
{{- $root := . -}}
{{- $envoy := .Values.envoy | default dict -}}
{{- if $envoy.enabled -}}
{{- $gateway := default (dict "name" "gateway-api" "namespace" "envoy-gateway") $envoy.gateway -}}
{{- $grpcroutes := default (list) $envoy.grpcRoutes -}}
{{- $baseName := include "common.fullname" . -}}
{{- $globalLabels := include "common.labels" . -}}
{{- $serviceNamespace := .Release.Namespace -}}
{{- $security := default dict $envoy.security -}}
{{- $securityEnabled := default false $security.enabled -}}
{{- $securityLabelKey := printf "%s/security-required" (include "common.parcellabtagsdomain" .) -}}
{{- $rolloutServices := include "common.rolloutServicesMap" (dict "root" $root "baseName" $baseName) | fromJson -}}

{{- range $index, $route := $grpcroutes }}
{{- $hosts := required (printf "envoy.grpcRoutes[%d].hosts is required" $index) $route.hosts -}}
{{- if eq (len $hosts) 0 -}}
{{- fail (printf "envoy.grpcRoutes[%d].hosts cannot be empty" $index) -}}
{{- end -}}
{{- $policyRoute := $route -}}
{{- $rawRouteName := default (printf "%s-grpc-%d" $baseName $index) $route.name -}}
{{- $sanitizedRouteName := trunc 63 (trimSuffix "-" (regexReplaceAll "[^a-z0-9-]" (lower $rawRouteName) "-")) -}}
{{- $routeName := default (printf "%s-grpc-%d" $baseName $index) $sanitizedRouteName }}
---
apiVersion: gateway.networking.k8s.io/v1
kind: GRPCRoute
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
    external-dns.alpha.kubernetes.io/hostname: "{{ join "," $route.hosts }}"
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
    {{- range $rule := . }}
    {{- $ruleCopy := deepCopy $rule -}}
    {{- if $ruleCopy.backendRefs }}
    {{- range $backend := $ruleCopy.backendRefs }}
    {{- $backendKind := default "Service" $backend.kind -}}
    {{- $backendGroup := default "" $backend.group -}}
    {{- if and (eq $backendKind "Service") (eq $backendGroup "") }}
    {{- $backendName := $backend.name -}}
    {{- if and $backendName (hasKey $rolloutServices $backendName) (not (hasSuffix "-rollout" $backendName)) -}}
    {{- $_ := set $backend "name" (printf "%s-rollout" $backendName) -}}
    {{- end -}}
    {{- end -}}
    {{- end -}}
    {{- end -}}
{{- toYaml (list $ruleCopy) | nindent 4 }}
    {{- end }}
  {{- end }}
{{- if hasKey $route "backendTrafficPolicy" }}
{{ include "common.backendtrafficpolicy" (dict "Values" $root.Values "Release" $root.Release "Chart" $root.Chart "route" $policyRoute "index" $index "routeName" $routeName "routeKind" "GRPCRoute" "routeValuesPath" "envoy.grpcRoutes" "globalLabels" $globalLabels) }}
{{- end }}
{{ end }}
{{- end }}
{{- end }}
