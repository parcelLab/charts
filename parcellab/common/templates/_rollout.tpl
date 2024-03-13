{{/* vim: set filetype=mustache: */}}
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
{{- $argoRollout := default (dict "enabled" false) .Values.argoRollout -}}
{{- $type := default "service" .type -}}
{{- if $argoRollout.enabled }}
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: {{ $name }}
  labels:
    {{- include "common.labels" $componentValues | nindent 4 }}
spec:
  {{- if not (eq $disableReplicaCount true) }}
  replicas: {{ default .Values.replicaCount $service.replicaCount }}
  {{- end }}
  revisionHistoryLimit: {{ .Values.revisionHistoryLimit }}
  selector:
    matchLabels:
      {{- include "common.selectors" $componentValues | nindent 6 }}
  strategy:
    {{- with $argoRollout.canary }}
    canary:
      {{- toYaml . | nindent 6 }}
      templates:
        - templateName: {{ $name }}-canary-analysis
      args:
        - name: service-name
          value: {{ $name }}
    {{- end }}
    {{- with $argoRollout.blueGreen }}
    blueGreen:
      activeService: {{ $name }}
      previewService: {{ $name }}-preview
      {{- toYaml . | nindent 6 }}

      {{- if $argoRollout.blueGreenMetricsPrePromotion }}
      prePromotionAnalysis:
        templates:
          - templateName: {{ $name }}-bluegreen-prepromotion-analysis
        args:
          - name: service-name
            value: {{ $name }}
      {{- end }}

      {{- if $argoRollout.blueGreenMetricsPostPromotion }}
      prePromotionAnalysis:
        templates:
          - templateName: {{ $name }}-bluegreen-postpromotion-analysis
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
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: {{ $name }}-canary-analysis
spec:
  args:
  - name: service-name
  metrics:
{{ toYaml . | indent 4 }}
---
{{- end }}
{{- end }}

{{- if and $argoRollout.blueGreen $argoRollout.blueGreenMetricsPrePromotion }}
{{- range $argoRollout.blueGreenMetricsPrePromotion }}
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: {{ $name }}-bluegreen-prepromotion-analysis
spec:
  args:
  - name: service-name
  metrics:
{{ toYaml . | indent 4 }}
---
{{- end }}
{{- end }}

{{- if and $argoRollout.blueGreen $argoRollout.blueGreenMetricsPostPromotion }}
{{- range $argoRollout.blueGreenMetricsPostPromotion }}
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: {{ $name }}-bluegreen-postpromotion-analysis
spec:
  args:
  - name: service-name
  metrics:
{{ toYaml . | indent 4 }}
---
{{- end }}
{{- end }}

{{- end }}
{{- $previewService := mergeOverwrite $service (dict "name" (printf "%s-preview" $name) ) -}}
{{- include "common.service" (merge (deepCopy .) (dict "service" $previewService )) }}
---
{{- end }}
