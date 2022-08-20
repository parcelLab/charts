{{/* vim: set filetype=mustache: */}}
{{/*
  Common configmap definition:
  {{ include "common.configmap" (
    dict
      "Values" "the values scope"
      "config" "The configmap spec configuration" /optional (defaults to .Values.config)
      "name" "The configmap name" /optional (defaults to empty)
  ) }}
*/}}
{{- define "common.configmap" -}}
{{- if or .Values.config .config }}
{{- $config := default .Values.config .config -}}
{{- $fullname := default (include "common.fullname" .) .name -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $fullname }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
data:
  {{- include "common.dictdata" (dict "data" $config) | indent 2 }}
{{- end }}
{{- end -}}
