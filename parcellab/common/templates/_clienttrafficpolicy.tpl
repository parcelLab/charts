{{/* vim: set filetype=mustache: */}}
{{/*
  Common ClientTrafficPolicy definition:
  {{ include "common.clienttrafficpolicy" (
    dict
      "Values" "the values scope"
      "Release" .Release
      "route" "the current HTTPRoute object"
      "index" "the httpRoutes index"
      "routeName" "the rendered HTTPRoute name"
      "globalLabels" "common labels"
  ) }}
*/}}

{{- define "common.clienttrafficpolicy" -}}
{{- $route := .route | default dict -}}
{{- $index := .index | default 0 -}}
{{- $routeName := .routeName | default "" -}}
{{- $globalLabels := .globalLabels | default dict -}}
{{- $serviceNamespace := .Release.Namespace -}}
{{- $clientTrafficPolicy := $route.clientTrafficPolicy -}}
{{- if $clientTrafficPolicy }}
{{- $ctpEnabled := default true $clientTrafficPolicy.enabled -}}
{{- if $ctpEnabled -}}
{{- $ctpName := default (printf "%s-client-traffic-policy" $routeName) $clientTrafficPolicy.name -}}
{{- $ctpLabels := $clientTrafficPolicy.labels | default dict -}}
{{- $ctpAnnotations := $clientTrafficPolicy.annotations | default dict -}}
{{- $ctpTargetRefs := $clientTrafficPolicy.targetRefs | default list -}}
{{- $ctpSpec := $clientTrafficPolicy.spec | default dict -}}
{{- if eq (len $ctpSpec) 0 -}}
{{- $ctpSpec = deepCopy $clientTrafficPolicy -}}
{{- $_ := unset $ctpSpec "enabled" -}}
{{- $_ := unset $ctpSpec "name" -}}
{{- $_ := unset $ctpSpec "labels" -}}
{{- $_ := unset $ctpSpec "annotations" -}}
{{- $_ := unset $ctpSpec "targetRefs" -}}
{{- $_ := unset $ctpSpec "spec" -}}
{{- end -}}
{{- $ctpSpecHasTargetRefs := hasKey $ctpSpec "targetRefs" -}}
{{- if gt (len $ctpTargetRefs) 0 -}}
{{- if $ctpSpecHasTargetRefs -}}
{{- $_ := unset $ctpSpec "targetRefs" -}}
{{- $ctpSpecHasTargetRefs = false -}}
{{- end -}}
{{- end -}}
{{- if and (eq (len $ctpSpec) 0) (eq (len $ctpTargetRefs) 0) (not $ctpSpecHasTargetRefs) -}}
{{- fail (printf "envoy.httpRoutes[%d].clientTrafficPolicy requires spec or fields" $index) -}}
{{- end -}}
---
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: ClientTrafficPolicy
metadata:
  name: {{ $ctpName }}
  namespace: {{ $serviceNamespace }}
  labels:
    {{- $globalLabels | nindent 4 }}
    {{- with $ctpLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $ctpAnnotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if gt (len $ctpTargetRefs) 0 }}
  targetRefs:
    {{- toYaml $ctpTargetRefs | nindent 4 }}
  {{- else if not $ctpSpecHasTargetRefs }}
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: {{ $routeName }}
  {{- end }}
  {{- if gt (len $ctpSpec) 0 }}
  {{- toYaml $ctpSpec | nindent 2 }}
  {{- end }}
{{- end -}}
{{- end -}}
{{- end -}}
