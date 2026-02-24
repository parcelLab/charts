{{/* vim: set filetype=mustache: */}}
{{/*
  Common BackendTrafficPolicy definition:
  {{ include "common.backendtrafficpolicy" (
    dict
      "Values" "the values scope"
      "Release" .Release
      "route" "the current HTTPRoute object"
      "index" "the httpRoutes index"
      "routeName" "the rendered HTTPRoute name"
      "globalLabels" "common labels"
  ) }}
*/}}

{{- define "common.backendtrafficpolicy" -}}
{{- $route := .route | default dict -}}
{{- $index := .index | default 0 -}}
{{- $routeName := .routeName | default "" -}}
{{- $globalLabels := .globalLabels | default dict -}}
{{- $serviceNamespace := .Release.Namespace -}}
{{- $backendTrafficPolicy := $route.backendTrafficPolicy -}}
{{- if $backendTrafficPolicy }}
{{- $btpEnabled := default true $backendTrafficPolicy.enabled -}}
{{- if $btpEnabled -}}
{{- $btpName := default (printf "%s-backend-traffic-policy" $routeName) $backendTrafficPolicy.name -}}
{{- $btpLabels := $backendTrafficPolicy.labels | default dict -}}
{{- $btpAnnotations := $backendTrafficPolicy.annotations | default dict -}}
{{- $btpTargetRefs := $backendTrafficPolicy.targetRefs | default list -}}
{{- $btpSpec := $backendTrafficPolicy.spec | default dict -}}
{{- if eq (len $btpSpec) 0 -}}
{{- $btpSpec = deepCopy $backendTrafficPolicy -}}
{{- $_ := unset $btpSpec "enabled" -}}
{{- $_ := unset $btpSpec "name" -}}
{{- $_ := unset $btpSpec "labels" -}}
{{- $_ := unset $btpSpec "annotations" -}}
{{- $_ := unset $btpSpec "targetRefs" -}}
{{- $_ := unset $btpSpec "spec" -}}
{{- end -}}
{{- $btpSpecHasTargetRefs := hasKey $btpSpec "targetRefs" -}}
{{- if gt (len $btpTargetRefs) 0 -}}
{{- if $btpSpecHasTargetRefs -}}
{{- $_ := unset $btpSpec "targetRefs" -}}
{{- $btpSpecHasTargetRefs = false -}}
{{- end -}}
{{- end -}}
{{- if and (eq (len $btpSpec) 0) (eq (len $btpTargetRefs) 0) (not $btpSpecHasTargetRefs) -}}
{{- fail (printf "envoy.httpRoutes[%d].backendTrafficPolicy requires spec or fields" $index) -}}
{{- end -}}
---
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: BackendTrafficPolicy
metadata:
  name: {{ $btpName }}
  namespace: {{ $serviceNamespace }}
  labels:
    {{- $globalLabels | nindent 4 }}
    {{- with $btpLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $btpAnnotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if gt (len $btpTargetRefs) 0 }}
  targetRefs:
    {{- toYaml $btpTargetRefs | nindent 4 }}
  {{- else if not $btpSpecHasTargetRefs }}
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: {{ $routeName }}
  {{- end }}
  {{- if gt (len $btpSpec) 0 }}
  {{- toYaml $btpSpec | nindent 2 }}
  {{- end }}
{{- end -}}
{{- end -}}
{{- end -}}
