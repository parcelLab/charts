{{/* vim: set filetype=mustache: */}}

{{/*
  Define NOTES that will be shown after the helm run:
  {{ include "common.notes" (
    dict
      "Release" "The chart release variables"
      "Values" "The chart values"
  ) }}
*/}}
{{- define "common.notes" -}}
{{- $fullname := include "common.formatname" (dict "chartName" .Values.appName "releaseName" .Release.Name) -}}
{{- $isFrontend := (default (dict "enabled" false ) .Values.nginxConfig).enabled -}}
{{- if .Values.podDisruptionBudget.enabled }}
A Pod Disruption Budget configuration has been added: {{ toYaml .Values.podDisruptionBudget.spec | nindent 2 }}
{{- else -}}
Pod Disruption Budget is skipped. There are no rules to avoid pods from being restarted.
{{- end }}

{{ if .Values.vpa.enabled }}
Vertical Pod Autoscaling is configured in {{ .Values.vpa.mode }} mode.
{{- if .Values.vpa.ignoreContainers }}
  The following containers will be ignored from the autoscaling configuration:
{{- range .Values.vpa.ignoreContainers }}
    {{ . }}
{{- end }}
{{- end }}
{{- else -}}
Vertical Pod Autoscaling is skipped. Resource requests and limits should be specified per pod.
{{- end }}

{{ if .Values.hpa }}
{{ if .Values.hpa.enabled }}
Horizontal Pod Autoscaling is configured with {{ .Values.hpa.minReplicas }}-{{ .Values.hpa.maxReplicas }} replicas.
annotations: {{ toYaml .Values.hpa.annotations | nindent 2 }}
metrics: {{ toYaml .Values.hpa.metrics | nindent 2 }}
{{- else -}}
Horizontal Pod Autoscaling is skipped. Number of replicas per pod is defined manually.
{{- if .Values.replicaCount }}
  Replica count is {{ .Values.replicaCount }}.
{{- end }}
{{- end }}
{{- end }}
{{- end }}
