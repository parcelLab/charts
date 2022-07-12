{{/* vim: set filetype=mustache: */}}
{{/*
Annotations to use in pods
  {{ include "common.pod.annotations" (
    dict
      "Chart" "The Chart scope"
      "Values" "the chart values scope"
  ) }}
*/}}
{{- define "common.pod.annotations" -}}
parcellab.dev/name: {{ .Chart.Name }}
parcellab.dev/version: {{ .Chart.AppVersion }}
{{- end -}}
