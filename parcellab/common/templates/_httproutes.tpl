{{/* vim: set filetype=mustache: */}}
{{/*
  Common HTTPRoute definition with deterministic names and labels:
  {{ include "common.httproutes" . }}
*/}}

{{- define "common.httproutes" -}}
{{- $root := . -}}
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
{{- $rolloutServices := dict -}}
{{- $globalRollout := .Values.argoRollout | default dict -}}
{{- if $globalRollout.enabled -}}
{{- $_ := set $rolloutServices $baseName true -}}
{{- end -}}
{{- range .Values.extraServices | default list -}}
{{- if and .argoRollout .argoRollout.enabled -}}
{{- $svcName := include "common.componentname" (merge (deepCopy $root) (dict "component" .name)) -}}
{{- $_ := set $rolloutServices $svcName true -}}
{{- end -}}
{{- end -}}

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
    {{- $ruleYaml := toYaml $ruleCopy -}}
    {{- $ruleYaml = replace $ruleYaml "\n" "\n  " -}}
    {{- $ruleYaml = printf "- %s" $ruleYaml -}}
    {{- $ruleYaml | nindent 4 }}
    {{- end }}
  {{- end }}
{{ end }}
{{- end }}
{{- end }}
