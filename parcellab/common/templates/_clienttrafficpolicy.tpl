{{/* vim: set filetype=mustache: */}}
{{/*
  Common ClientTrafficPolicy definition:
  {{ include "common.clienttrafficpolicy" (
    dict
      "Values" "the values scope"
      "Release" .Release
      "route" "the current HTTPRoute object (optional)"
      "index" "the httpRoutes index (optional)"
      "routeName" "the rendered HTTPRoute name (optional)"
      "globalLabels" "common labels (optional)"
  ) }}
*/}}

{{- define "common.clienttrafficpolicy" -}}
{{- $route := .route | default dict -}}
{{- $index := .index | default 0 -}}
{{- $routeName := .routeName | default "" -}}
{{- $globalLabels := .globalLabels | default (include "common.labels" .) -}}
{{- $serviceNamespace := .Release.Namespace -}}
{{- $envoy := .Values.envoy | default dict -}}
{{- $policyOverride := .policy | default dict -}}
{{- $hasPolicyOverride := and (hasKey . "policy") (ne (len $policyOverride) 0) -}}
{{- $hasRoutePolicy := and (hasKey . "route") (ne (len $route) 0) (hasKey $route "clientTrafficPolicy") -}}
{{- $clientTrafficPolicy := ternary $policyOverride (ternary $route.clientTrafficPolicy $envoy.clientTrafficPolicy $hasRoutePolicy) $hasPolicyOverride -}}
{{- if $clientTrafficPolicy }}
{{- $ctpEnabled := default true $clientTrafficPolicy.enabled -}}
{{- if $ctpEnabled -}}
{{- $ctpName := default (printf "%s-client-traffic-policy" (ternary $routeName (include "common.fullname" .) $hasRoutePolicy)) $clientTrafficPolicy.name -}}
{{- $ctpLabels := $clientTrafficPolicy.labels | default dict -}}
{{- $ctpAnnotations := $clientTrafficPolicy.annotations | default dict -}}
{{- $ctpTargetRef := $clientTrafficPolicy.targetRef | default dict -}}
{{- $ctpHasTargetRef := and $ctpTargetRef (ne (len $ctpTargetRef) 0) -}}
{{- $ctpTargetRefs := $clientTrafficPolicy.targetRefs | default list -}}
{{- $ctpTargetSelectors := list -}}
{{- if $clientTrafficPolicy.targetSelectors }}
  {{- if kindIs "slice" $clientTrafficPolicy.targetSelectors }}
    {{- $ctpTargetSelectors = $clientTrafficPolicy.targetSelectors -}}
  {{- else }}
    {{- $ctpTargetSelectors = list $clientTrafficPolicy.targetSelectors -}}
  {{- end }}
{{- else if $clientTrafficPolicy.targetSelector }}
  {{- $ctpTargetSelectors = list $clientTrafficPolicy.targetSelector -}}
{{- end }}
{{- $ctpSpec := $clientTrafficPolicy.spec | default dict -}}
{{- if eq (len $ctpSpec) 0 -}}
{{- $ctpSpec = deepCopy $clientTrafficPolicy -}}
{{- $_ := unset $ctpSpec "enabled" -}}
{{- $_ := unset $ctpSpec "name" -}}
{{- $_ := unset $ctpSpec "labels" -}}
{{- $_ := unset $ctpSpec "annotations" -}}
{{- $_ := unset $ctpSpec "targetRef" -}}
{{- $_ := unset $ctpSpec "targetRefs" -}}
{{- $_ := unset $ctpSpec "targetSelectors" -}}
{{- $_ := unset $ctpSpec "targetSelector" -}}
{{- $_ := unset $ctpSpec "spec" -}}
{{- end -}}
{{- $ctpSpecHasTargetRef := hasKey $ctpSpec "targetRef" -}}
{{- $ctpSpecHasTargetRefs := hasKey $ctpSpec "targetRefs" -}}
{{- $ctpSpecHasTargetSelectors := hasKey $ctpSpec "targetSelectors" -}}
{{- if $ctpHasTargetRef -}}
{{- if $ctpSpecHasTargetRef -}}
{{- $_ := unset $ctpSpec "targetRef" -}}
{{- $ctpSpecHasTargetRef = false -}}
{{- end -}}
{{- end -}}
{{- if gt (len $ctpTargetRefs) 0 -}}
{{- if $ctpSpecHasTargetRefs -}}
{{- $_ := unset $ctpSpec "targetRefs" -}}
{{- $ctpSpecHasTargetRefs = false -}}
{{- end -}}
{{- end -}}
{{- if gt (len $ctpTargetSelectors) 0 -}}
{{- if $ctpSpecHasTargetSelectors -}}
{{- $_ := unset $ctpSpec "targetSelectors" -}}
{{- $ctpSpecHasTargetSelectors = false -}}
{{- end -}}
{{- end -}}
{{- if and (eq (len $ctpSpec) 0) (not $ctpHasTargetRef) (eq (len $ctpTargetRefs) 0) (eq (len $ctpTargetSelectors) 0) (not $ctpSpecHasTargetRef) (not $ctpSpecHasTargetRefs) (not $ctpSpecHasTargetSelectors) -}}
{{- if $hasRoutePolicy -}}
{{- fail (printf "envoy.httpRoutes[%d].clientTrafficPolicy requires spec or fields" $index) -}}
{{- else -}}
{{- fail "envoy.clientTrafficPolicy requires spec or fields" -}}
{{- end -}}
{{- end -}}
{{- if and (not $hasRoutePolicy) (not $ctpHasTargetRef) (eq (len $ctpTargetRefs) 0) (eq (len $ctpTargetSelectors) 0) (not $ctpSpecHasTargetRef) (not $ctpSpecHasTargetRefs) (not $ctpSpecHasTargetSelectors) -}}
{{- fail "envoy.clientTrafficPolicy.targetRef, targetRefs, or targetSelectors is required for global policy" -}}
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
  {{- if $ctpHasTargetRef }}
  targetRef:
    {{- toYaml $ctpTargetRef | nindent 4 }}
  {{- else if gt (len $ctpTargetRefs) 0 }}
  targetRefs:
    {{- toYaml $ctpTargetRefs | nindent 4 }}
  {{- else if gt (len $ctpTargetSelectors) 0 }}
  targetSelectors:
    {{- toYaml $ctpTargetSelectors | nindent 4 }}
  {{- else if and $hasRoutePolicy (not $ctpSpecHasTargetRef) (not $ctpSpecHasTargetRefs) (not $ctpSpecHasTargetSelectors) }}
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
