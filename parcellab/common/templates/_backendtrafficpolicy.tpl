{{/* vim: set filetype=mustache: */}}
{{/*
  Common BackendTrafficPolicy definition:
  {{ include "common.backendtrafficpolicy" (
    dict
      "Values" "the values scope"
      "Release" .Release
      "route" "the current HTTPRoute object (optional)"
      "index" "the httpRoutes index (optional)"
      "routeName" "the rendered HTTPRoute name (optional)"
      "globalLabels" "common labels (optional)"
  ) }}
*/}}

{{- define "common.backendtrafficpolicy" -}}
{{- $route := .route | default dict -}}
{{- $index := .index | default 0 -}}
{{- $routeName := .routeName | default "" -}}
{{- $globalLabels := .globalLabels | default (include "common.labels" .) -}}
{{- $serviceNamespace := .Release.Namespace -}}
{{- $envoy := .Values.envoy | default dict -}}
{{- $policyOverride := .policy | default dict -}}
{{- $hasPolicyOverride := and (hasKey . "policy") (ne (len $policyOverride) 0) -}}
{{- $hasRoutePolicy := and (hasKey . "route") (ne (len $route) 0) (hasKey $route "backendTrafficPolicy") -}}
{{- $backendTrafficPolicy := ternary $policyOverride (ternary $route.backendTrafficPolicy $envoy.backendTrafficPolicy $hasRoutePolicy) $hasPolicyOverride -}}
{{- if $backendTrafficPolicy }}
{{- $btpEnabled := default true $backendTrafficPolicy.enabled -}}
{{- if $btpEnabled -}}
{{- $btpName := default (printf "%s-backend-traffic-policy" (ternary $routeName (include "common.fullname" .) $hasRoutePolicy)) $backendTrafficPolicy.name -}}
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
{{- if $hasRoutePolicy -}}
{{- fail (printf "envoy.httpRoutes[%d].backendTrafficPolicy requires spec or fields" $index) -}}
{{- else -}}
{{- fail "envoy.backendTrafficPolicy requires spec or fields" -}}
{{- end -}}
{{- end -}}
{{- if and (not $hasRoutePolicy) (eq (len $btpTargetRefs) 0) (not $btpSpecHasTargetRefs) -}}
{{- fail "envoy.backendTrafficPolicy.targetRefs is required for global policy" -}}
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
  {{- else if and $hasRoutePolicy (not $btpSpecHasTargetRefs) }}
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
