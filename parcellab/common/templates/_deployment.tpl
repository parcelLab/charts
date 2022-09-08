{{/* vim: set filetype=mustache: */}}
{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.deployment" (
    dict
      "Values" "the values scope"
      "service" "The specific service configuration /optional (defaults to empty)"
      "type" "The tye of pod to define /optional (defaults to 'service')"
  ) }}
*/}}
{{- define "common.deployment" -}}
{{- $service := default dict .service -}}
{{- $autoscalingEnabled := .Values.autoscaling.enabled -}}
{{- if $service.autoscaling -}}
{{- $autoscalingEnabled = $service.autoscaling.enabled -}}
{{- end -}}
{{- $fullname := include "common.fullname" . -}}
{{- if $service.name -}}
{{- $fullname = printf "%s-%s" $fullname $service.name -}}
{{- end -}}
{{- $type := default "service" .type -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $fullname }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  {{- if not $autoscalingEnabled }}
  replicas: {{ default .Values.replicaCount $service.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "common.selectors" . | nindent 6 }}
  template:
    {{- include "common.pod"
      (merge (deepCopy .) (dict "pod" $service "type" $type)) | nindent 4
    }}
{{- end -}}
