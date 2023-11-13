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
{{- $componentValues := (merge (deepCopy .) (dict "component" $service.name)) -}}
{{- $name := include "common.componentname" $componentValues -}}
{{- $type := default "service" .type -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $name }}
  labels:
    {{- include "common.labels" $componentValues | nindent 4 }}
spec:
  {{- if .Values.replicaCount -}}
  replicas: {{ default .Values.replicaCount $service.replicaCount }}
  {{- end }}
  {{- with .Values.strategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "common.selectors" $componentValues | nindent 6 }}
  template:
    {{- include "common.pod"
      (merge (deepCopy .) (dict "pod" $service "type" $type)) | nindent 4
    }}
{{- end -}}
