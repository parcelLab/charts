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
{{ include "common.parcellabtagsdomain" . }}/name: {{ include "common.fullname" . | quote }}
{{ include "common.parcellabtagsdomain" . }}/version: {{ include "common.version" . | quote }}
{{- end -}}
