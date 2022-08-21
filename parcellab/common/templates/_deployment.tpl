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
    {{- include "common.pod"
      (merge (deepCopy .) (dict "pod" $service "type" "service")) | nindent 4
    }}
{{- end -}}
