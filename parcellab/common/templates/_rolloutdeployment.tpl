{{/* vim: set filetype=mustache: */}}
{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.rolloutdeployment" (
    dict
      "Values" "the values scope"
      "service" "The specific service configuration /optional (defaults to empty)"
      "type" "The tye of pod to define /optional (defaults to 'service')"
      "rolloutDeployment" "The specific rollout configuration /optional (defaults to empty)"
  ) }}
*/}}
{{- define "common.rolloutdeployment" -}}
{{- $service := default dict .service -}}
{{- $componentValues := (merge (deepCopy .) (dict "component" $service.name)) -}}
{{- $name := include "common.componentname" $componentValues -}}
{{- $disableReplicaCount := (ternary $service.disableReplicaCount .Values.disableReplicaCount (hasKey $service "disableReplicaCount")) -}}
{{- $rolloutDeployment := default (dict "enabled" false) .rolloutDeployment -}}
{{- $type := default "service" .type -}}
{{- if or .Values.rolloutDeployment.enabled $rolloutDeployment.enabled }}
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
    {{- if .Values.rolloutDeployment.blueGreen }}
    blueGreen:
      activeService: {{ $name }}
      previewService: {{ $name }}-preview
      {{- toYaml .Values.rolloutDeployment.blueGreen | nindent 6 }}
    {{- end }}
    {{- if .Values.rolloutDeployment.canary }}
    canary:
      {{- toYaml .Values.rolloutDeployment.canary | nindent 6 }}
    {{- end }}
  template:
    {{- include "common.pod"
      (merge (deepCopy .) (dict "pod" $service "type" $type)) | nindent 4
    }}
---
{{- $rolloutSpec := dict }}
{{- if .Values.rolloutDeployment.blueGreen }}
  {{- $rolloutSpec = .Values.rolloutDeployment.blueGreen }}
{{- end }}
{{- if .Values.rolloutDeployment.canary }}
  {{- $rolloutSpec = .Values.rolloutDeployment.canary }}
{{- end }}
{{- if $rolloutSpec.metrics }}
{{- range $index, $metric := $rolloutSpec.metrics }}
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: {{ $metric.name }}-analysis
spec:
  args:
  - name: {{ $metric.name }}
  metrics:
{{ toYaml $metric | indent 4 }}

{{- if ne (add $index 1) (len $rolloutSpec.metrics) }}
---
{{- end }}
{{- end }}
{{- end }}
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
