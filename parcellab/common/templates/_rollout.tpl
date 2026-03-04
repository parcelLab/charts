{{/* vim: set filetype=mustache: */}}
{{/*
Builds the map of service names that should target their -rollout counterpart.
Returns JSON so callers can deserialise with fromJson.
Usage:
  {{- $rolloutServices := include "common.rolloutServicesMap" (dict "root" . "baseName" $baseName) | fromJson -}}
*/}}
{{- define "common.rolloutServicesMap" -}}
{{- $root := .root -}}
{{- $baseName := .baseName -}}
{{- $rolloutServices := dict -}}
{{- $globalRollout := $root.Values.argoRollout | default dict -}}
{{- if $globalRollout.enabled -}}
{{- $_ := set $rolloutServices $baseName true -}}
{{- end -}}
{{- range $root.Values.extraServices | default list -}}
{{- if and .argoRollout .argoRollout.enabled -}}
{{- $svcName := include "common.componentname" (merge (deepCopy $root) (dict "component" .name)) -}}
{{- $_ := set $rolloutServices $svcName true -}}
{{- end -}}
{{- end -}}
{{- $rolloutServices | toJson -}}
{{- end -}}

{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.argorollout" (
    dict
      "Chart" "the chart scope"
      "Release" "the release scope"
      "Values" "the values scope"
      "service" "The specific service configuration /optional (defaults to empty)"
      "type" "The type of pod to define /optional (defaults to 'service', 'job' is not supported)"
  ) }}
*/}}
{{- define "common.argorollout" -}}
{{- $service := default dict .service -}}
{{- $componentValues := (merge (deepCopy .) (dict "component" $service.name)) -}}
{{- $name := include "common.componentname" $componentValues -}}
{{- $disableReplicaCount := (ternary $service.disableReplicaCount .Values.disableReplicaCount (hasKey $service "disableReplicaCount")) -}}
{{- $argoRollout := default .Values.argoRollout .argoRollout -}}
{{- $type := default "service" .type }}
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: {{ $name | default (include "common.fullname" .) }}
  labels:
    {{- include "common.labels" $componentValues | nindent 4 }}
  {{- if $argoRollout.notifications }}
  annotations:
    {{- with $argoRollout.notifications.triggers }}
    {{- range . }}
    notifications.argoproj.io/subscribe.{{ .name }}.slack: {{ join ";" .channels }}
    {{- end }}
    {{- end }}
  {{- end }}
spec:
  revisionHistoryLimit: {{ .Values.revisionHistoryLimit }}
  selector:
    matchLabels:
      {{- include "common.selectors" $componentValues | nindent 6 }}
  strategy:
    {{- with $argoRollout.canary }}
    canary:
      {{- if $argoRollout.canaryMetrics }}
      analysis:
        templates:
          - templateName: {{ $name }}-canary
        args:
          - name: service-name
            value: {{ $name }}
      {{- end }}
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with $argoRollout.blueGreen }}
    blueGreen:
      activeService: {{ $name }}
      previewService: {{ $name }}-rollout
      {{- toYaml . | nindent 6 }}

      {{- if $argoRollout.blueGreenMetricsPrePromotion }}
      prePromotionAnalysis:
        templates:
          - templateName: {{ $name }}-bluegreen-prepromotion
        args:
          - name: service-name
            value: {{ $name }}
      {{- end }}

      {{- if $argoRollout.blueGreenMetricsPostPromotion }}
      postPromotionAnalysis:
        templates:
          - templateName: {{ $name }}-bluegreen-postpromotion
        args:
          - name: service-name
            value: {{ $name }}
      {{- end }}

    {{- end }}
  template:
    {{- include "common.pod"
      (merge (deepCopy .) (dict "pod" $service "type" $type)) | nindent 4
    }}
---

{{- if and $argoRollout.canary $argoRollout.canaryMetrics }}
{{- range $argoRollout.canaryMetrics }}
{{- include "common.analysisTemplate" (dict "name" (printf "%s-canary" $name) "metrics" .) | nindent 0 }}
{{- end }}
{{- end }}

{{- if and $argoRollout.blueGreen $argoRollout.blueGreenMetricsPrePromotion }}
{{- range $argoRollout.blueGreenMetricsPrePromotion }}
{{- include "common.analysisTemplate" (dict "name" (printf "%s-bluegreen-prepromotion" $name) "metrics" .) | nindent 0 }}
{{- end }}
{{- end }}

{{- if and $argoRollout.blueGreen $argoRollout.blueGreenMetricsPostPromotion }}
{{- range $argoRollout.blueGreenMetricsPostPromotion }}
{{- include "common.analysisTemplate" (dict "name" (printf "%s-bluegreen-postpromotion" $name) "metrics" .) | nindent 0 }}
{{- end }}
{{- end }}

---
{{- end }}
