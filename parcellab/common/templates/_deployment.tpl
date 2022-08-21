{{/* vim: set filetype=mustache: */}}
{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.deployment" (
    dict
      "Values" "the values scope"
      "service" "The specific service configuration /optional (defaults to empty)"
  ) }}
*/}}
{{- define "common.deployment" -}}
{{- $service := default (dict "autoscaling" (dict)) .service -}}
{{- $fullname := include "common.fullname" . -}}
{{- if $service.name -}}
{{- $fullname = printf "%s-%s" $fullname $service.name -}}
{{- end -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $fullname }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  {{- if not (default .Values.autoscaling.enabled $service.autoscaling.enabled) }}
  replicas: {{ default .Values.replicaCount $service.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "common.selectors" . | nindent 6 }}
  template:
    metadata:
      annotations:
        {{- include "common.pod.annotations" . | nindent 8 }}
      labels:
        {{- include "common.labels" . | nindent 8 }}
        {{- if and .Values.datadog .Values.datadog.enabled }}
        tags.datadoghq.com/env: {{ include "common.env" . | quote }}
        tags.datadoghq.com/service: {{ $fullname | quote }}
        tags.datadoghq.com/version: {{ include "common.version" . | quote }}
        {{- end }}
    spec:
      {{- include "common.pod"
        (merge (deepCopy .) (dict "pod" $service "type" "service")) | indent 6
      }}
{{- end -}}
