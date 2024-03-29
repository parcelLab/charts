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
{{- $componentValues := (merge (deepCopy .) (dict "component" .name)) -}}
{{- $name := include "common.componentname" $componentValues -}}
{{- $config := default .Values.config .config -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $name }}
  labels:
    {{- include "common.labels" $componentValues | nindent 4 }}
data:
  {{- include "common.dictdata" (dict "data" $config) | indent 2 }}
{{- end }}
{{- end -}}
