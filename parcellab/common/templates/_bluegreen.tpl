{{/* vim: set filetype=mustache: */}}
{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.deployment" (
    dict
      "Values" "the values scope"
      "service" "The specific service configuration /optional (defaults to empty)"
      "blueGreen" "The specific blueGreen rollout configuration /optional (defaults to empty)"
  ) }}
*/}}
{{- define "common.bluegreen" -}}
{{- $service := default dict .service -}}
{{- $componentValues := (merge (deepCopy .) (dict "component" $service.name)) -}}
{{- $name := include "common.componentname" $componentValues -}}
{{- $disableReplicaCount := (ternary $service.disableReplicaCount .Values.disableReplicaCount (hasKey $service "disableReplicaCount")) -}}
{{- $blueGreen := default (dict "enabled" false) .blueGreen -}}
{{- $type := default "service" .type -}}
{{- if or .Values.blueGreen.enabled $blueGreen.enabled }}
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
    blueGreen:
      activeService: {{ $name }}
      previewService: {{ $name }}-preview
      {{- if .Values.blueGreen.spec }}
      {{- toYaml .Values.blueGreen.spec | nindent 6 }}
      {{- end }}
  template:
    {{- include "common.pod"
      (merge (deepCopy .) (dict "pod" $service "type" $type)) | nindent 4
    }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $name }}-preview
  labels:
    {{- include "common.labels" $componentValues | nindent 4 }}
spec:
  type: {{ default .Values.service.type $service.serviceType }}
  ports:
    - port: {{ default .Values.service.port $service.portNumber }}
      targetPort: {{ default .Values.service.targetPort $service.portName }}
      protocol: {{ default .Values.service.protocol $service.portProtocol }}
      name: {{ default .Values.service.name $service.portName }}
  selector:
    {{- include "common.selectors" $componentValues | nindent 4 }}
    {{- if $service.extraSelectors }}
    {{- toYaml $service.extraSelectors | nindent 4 }}
    {{- end }}
{{- end }}
{{- end -}}
