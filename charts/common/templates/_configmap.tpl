{{/* vim: set filetype=mustache: */}}
{{/*
  Common configmap definition:
  {{ include "common.configmap" (
    dict
      "Values" "the values scope"
  ) }}
*/}}
{{- define "common.configmap" -}}
{{- if .Values.config }}
apiVersion: v2
kind: ConfigMap
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
data:
  {{- if .Values.config }}
  {{- include "common.dictdata" (dict "data" .Values.config) | nindent 2 }}
  {{- end }}
{{- end }}
{{- end -}}
