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
{{ include "common.domainvariables" . }}/name: {{ include "common.fullname" . }}
{{ include "common.domainvariables" . }}/version: {{ include "common.version" . }}
{{- end -}}
