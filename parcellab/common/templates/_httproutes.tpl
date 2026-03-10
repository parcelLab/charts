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
{{- $globalBackendTrafficPolicy := $envoy.backendTrafficPolicy | default dict -}}
{{- $globalClientTrafficPolicy := $envoy.clientTrafficPolicy | default dict -}}
{{- $baseName := include "common.fullname" . -}}
{{- $globalLabels := include "common.labels" . -}}
{{- $serviceNamespace := .Release.Namespace -}}
{{- $security := default dict $envoy.security -}}
{{- $securityEnabled := default false $security.enabled -}}
{{- $securityLabelKey := printf "%s/security-required" (include "common.parcellabtagsdomain" .) -}}
{{- $rolloutServices := include "common.rolloutServicesMap" (dict "root" $root "baseName" $baseName) | fromJson -}}

{{- $globalBackendTrafficPolicyEnabled := and $globalBackendTrafficPolicy (default true $globalBackendTrafficPolicy.enabled) -}}
{{- $globalBackendTrafficPolicyHasTargetRef := or (and $globalBackendTrafficPolicy.targetRef (gt (len $globalBackendTrafficPolicy.targetRef) 0)) (and $globalBackendTrafficPolicy.spec (hasKey $globalBackendTrafficPolicy.spec "targetRef")) -}}
{{- $globalBackendTrafficPolicyHasTargetRefs := or (gt (len ($globalBackendTrafficPolicy.targetRefs | default list)) 0) (and $globalBackendTrafficPolicy.spec (hasKey $globalBackendTrafficPolicy.spec "targetRefs")) -}}
{{- $globalBackendTrafficPolicyHasTargetSelectors := or (gt (len ($globalBackendTrafficPolicy.targetSelectors | default list)) 0) (and $globalBackendTrafficPolicy.spec (hasKey $globalBackendTrafficPolicy.spec "targetSelectors")) -}}
{{- $globalBackendTrafficPolicyTargetRefs := list -}}
{{- if and $globalBackendTrafficPolicyEnabled (not $globalBackendTrafficPolicyHasTargetRef) (not $globalBackendTrafficPolicyHasTargetRefs) (not $globalBackendTrafficPolicyHasTargetSelectors) -}}
{{- range $index, $route := $httproutes }}
{{- if not (hasKey $route "backendTrafficPolicy") -}}
{{- $rawRouteName := default (printf "%s-%d" $baseName $index) $route.name -}}
{{- $sanitizedRouteName := trunc 63 (trimSuffix "-" (regexReplaceAll "[^a-z0-9-]" (lower $rawRouteName) "-")) -}}
{{- $routeName := default (printf "%s-%d" $baseName $index) $sanitizedRouteName -}}
{{- $globalBackendTrafficPolicyTargetRefs = append $globalBackendTrafficPolicyTargetRefs (dict "group" "gateway.networking.k8s.io" "kind" "HTTPRoute" "name" $routeName) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if and $globalBackendTrafficPolicyEnabled (or $globalBackendTrafficPolicyHasTargetRef $globalBackendTrafficPolicyHasTargetRefs $globalBackendTrafficPolicyHasTargetSelectors (gt (len $globalBackendTrafficPolicyTargetRefs) 0)) -}}
{{- $globalBackendPolicy := deepCopy $globalBackendTrafficPolicy -}}
{{- if and (not $globalBackendTrafficPolicyHasTargetRef) (not $globalBackendTrafficPolicyHasTargetRefs) (not $globalBackendTrafficPolicyHasTargetSelectors) (gt (len $globalBackendTrafficPolicyTargetRefs) 0) -}}
{{- $_ := set $globalBackendPolicy "targetRefs" $globalBackendTrafficPolicyTargetRefs -}}
{{- end -}}
{{ include "common.backendtrafficpolicy" (dict "Values" $root.Values "Release" $root.Release "Chart" $root.Chart "policy" $globalBackendPolicy) }}
{{- end }}

{{- $globalClientTrafficPolicyEnabled := and $globalClientTrafficPolicy (default true $globalClientTrafficPolicy.enabled) -}}
{{- $globalClientTrafficPolicyHasTargetRef := or (and $globalClientTrafficPolicy.targetRef (gt (len $globalClientTrafficPolicy.targetRef) 0)) (and $globalClientTrafficPolicy.spec (hasKey $globalClientTrafficPolicy.spec "targetRef")) -}}
{{- $globalClientTrafficPolicyHasTargetRefs := or (gt (len ($globalClientTrafficPolicy.targetRefs | default list)) 0) (and $globalClientTrafficPolicy.spec (hasKey $globalClientTrafficPolicy.spec "targetRefs")) -}}
{{- $globalClientTrafficPolicyHasTargetSelectors := or (gt (len ($globalClientTrafficPolicy.targetSelectors | default list)) 0) (and $globalClientTrafficPolicy.spec (hasKey $globalClientTrafficPolicy.spec "targetSelectors")) -}}
{{- $globalClientTrafficPolicyTargetRefs := list -}}
{{- if and $globalClientTrafficPolicyEnabled (not $globalClientTrafficPolicyHasTargetRef) (not $globalClientTrafficPolicyHasTargetRefs) (not $globalClientTrafficPolicyHasTargetSelectors) -}}
{{- range $index, $route := $httproutes }}
{{- if not (hasKey $route "clientTrafficPolicy") -}}
{{- $rawRouteName := default (printf "%s-%d" $baseName $index) $route.name -}}
{{- $sanitizedRouteName := trunc 63 (trimSuffix "-" (regexReplaceAll "[^a-z0-9-]" (lower $rawRouteName) "-")) -}}
{{- $routeName := default (printf "%s-%d" $baseName $index) $sanitizedRouteName -}}
{{- $globalClientTrafficPolicyTargetRefs = append $globalClientTrafficPolicyTargetRefs (dict "group" "gateway.networking.k8s.io" "kind" "HTTPRoute" "name" $routeName) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if and $globalClientTrafficPolicyEnabled (or $globalClientTrafficPolicyHasTargetRef $globalClientTrafficPolicyHasTargetRefs $globalClientTrafficPolicyHasTargetSelectors (gt (len $globalClientTrafficPolicyTargetRefs) 0)) -}}
{{- $globalClientPolicy := deepCopy $globalClientTrafficPolicy -}}
{{- if and (not $globalClientTrafficPolicyHasTargetRef) (not $globalClientTrafficPolicyHasTargetRefs) (not $globalClientTrafficPolicyHasTargetSelectors) (gt (len $globalClientTrafficPolicyTargetRefs) 0) -}}
{{- $_ := set $globalClientPolicy "targetRefs" $globalClientTrafficPolicyTargetRefs -}}
{{- end -}}
{{ include "common.clienttrafficpolicy" (dict "Values" $root.Values "Release" $root.Release "Chart" $root.Chart "policy" $globalClientPolicy) }}
{{- end }}

{{- range $index, $route := $httproutes }}
{{- $hosts := required (printf "envoy.httpRoutes[%d].hosts is required" $index) $route.hosts -}}
{{- if eq (len $hosts) 0 -}}
{{- fail (printf "envoy.httpRoutes[%d].hosts cannot be empty" $index) -}}
{{- end -}}
{{- $policyRoute := $route -}}
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
{{- toYaml (list $ruleCopy) | nindent 4 }}
    {{- end }}
  {{- end }}
{{- if hasKey $route "backendTrafficPolicy" }}
{{ include "common.backendtrafficpolicy" (dict "Values" $root.Values "Release" $root.Release "Chart" $root.Chart "route" $policyRoute "index" $index "routeName" $routeName "globalLabels" $globalLabels) }}
{{- end }}
{{- if hasKey $route "clientTrafficPolicy" }}
{{ include "common.clienttrafficpolicy" (dict "Values" $root.Values "Release" $root.Release "Chart" $root.Chart "route" $policyRoute "index" $index "routeName" $routeName "globalLabels" $globalLabels) }}
{{- end }}
{{ end }}
{{- end }}
{{- end }}
