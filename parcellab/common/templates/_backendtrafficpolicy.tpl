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
{{- $btpTargetRef := $backendTrafficPolicy.targetRef | default dict -}}
{{- $btpHasTargetRef := and $btpTargetRef (ne (len $btpTargetRef) 0) -}}
{{- $btpTargetRefs := $backendTrafficPolicy.targetRefs | default list -}}
{{- $btpTargetSelectors := list -}}
{{- if $backendTrafficPolicy.targetSelectors }}
  {{- if kindIs "slice" $backendTrafficPolicy.targetSelectors }}
    {{- $btpTargetSelectors = $backendTrafficPolicy.targetSelectors -}}
  {{- else }}
    {{- $btpTargetSelectors = list $backendTrafficPolicy.targetSelectors -}}
  {{- end }}
{{- else if $backendTrafficPolicy.targetSelector }}
  {{- $btpTargetSelectors = list $backendTrafficPolicy.targetSelector -}}
{{- end }}
{{- $btpSpec := $backendTrafficPolicy.spec | default dict -}}
{{- if eq (len $btpSpec) 0 -}}
{{- $btpSpec = deepCopy $backendTrafficPolicy -}}
{{- $_ := unset $btpSpec "enabled" -}}
{{- $_ := unset $btpSpec "name" -}}
{{- $_ := unset $btpSpec "labels" -}}
{{- $_ := unset $btpSpec "annotations" -}}
{{- $_ := unset $btpSpec "targetRef" -}}
{{- $_ := unset $btpSpec "targetRefs" -}}
{{- $_ := unset $btpSpec "targetSelectors" -}}
{{- $_ := unset $btpSpec "targetSelector" -}}
{{- $_ := unset $btpSpec "spec" -}}
{{- end -}}
{{- $btpSpecHasTargetRef := hasKey $btpSpec "targetRef" -}}
{{- $btpSpecHasTargetRefs := hasKey $btpSpec "targetRefs" -}}
{{- $btpSpecHasTargetSelectors := hasKey $btpSpec "targetSelectors" -}}
{{- if $btpHasTargetRef -}}
{{- if $btpSpecHasTargetRef -}}
{{- $_ := unset $btpSpec "targetRef" -}}
{{- $btpSpecHasTargetRef = false -}}
{{- end -}}
{{- end -}}
{{- if gt (len $btpTargetRefs) 0 -}}
{{- if $btpSpecHasTargetRefs -}}
{{- $_ := unset $btpSpec "targetRefs" -}}
{{- $btpSpecHasTargetRefs = false -}}
{{- end -}}
{{- end -}}
{{- if gt (len $btpTargetSelectors) 0 -}}
{{- if $btpSpecHasTargetSelectors -}}
{{- $_ := unset $btpSpec "targetSelectors" -}}
{{- $btpSpecHasTargetSelectors = false -}}
{{- end -}}
{{- end -}}
{{- if and (eq (len $btpSpec) 0) (not $btpHasTargetRef) (eq (len $btpTargetRefs) 0) (eq (len $btpTargetSelectors) 0) (not $btpSpecHasTargetRef) (not $btpSpecHasTargetRefs) (not $btpSpecHasTargetSelectors) -}}
{{- if $hasRoutePolicy -}}
{{- fail (printf "envoy.httpRoutes[%d].backendTrafficPolicy requires spec or fields" $index) -}}
{{- else -}}
{{- fail "envoy.backendTrafficPolicy requires spec or fields" -}}
{{- end -}}
{{- end -}}
{{- if and (not $hasRoutePolicy) (not $btpHasTargetRef) (eq (len $btpTargetRefs) 0) (eq (len $btpTargetSelectors) 0) (not $btpSpecHasTargetRef) (not $btpSpecHasTargetRefs) (not $btpSpecHasTargetSelectors) -}}
{{- fail "envoy.backendTrafficPolicy.targetRef, targetRefs, or targetSelectors is required for global policy" -}}
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
  {{- if $btpHasTargetRef }}
  targetRef:
    {{- toYaml $btpTargetRef | nindent 4 }}
  {{- else if gt (len $btpTargetRefs) 0 }}
  targetRefs:
    {{- toYaml $btpTargetRefs | nindent 4 }}
  {{- else if gt (len $btpTargetSelectors) 0 }}
  targetSelectors:
    {{- toYaml $btpTargetSelectors | nindent 4 }}
  {{- else if and $hasRoutePolicy (not $btpSpecHasTargetRef) (not $btpSpecHasTargetRefs) (not $btpSpecHasTargetSelectors) }}
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: {{ $routeName }}
  {{- end }}
  {{- if gt (len $btpSpec) 0 }}
  {{- toYaml $btpSpec | nindent 2 }}
  {{- end }}
{{""}}
{{- end -}}
{{- end -}}
{{- end -}}
