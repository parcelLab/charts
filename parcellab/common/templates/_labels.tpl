{{/* vim: set filetype=mustache: */}}
{{/*
Labels to use as selectors
  {{ include "common.selectors" (
    dict
      "Chart" "the chart scope"
      "Release" "the release scope"
      "Values" "the chart values scope"
  ) }}
*/}}
{{- define "common.selectors" -}}
{{ include "common.parcellabtagsdomain" . }}/app: {{ include "common.fullname" . }}
{{ include "common.parcellabtagsdomain" . }}/env: {{ include "common.env" . }}
{{ include "common.parcellabtagsdomain" . }}/version: {{ include "common.version" . }}
{{- end -}}

{{/*
Common labels
  {{ include "common.labels" (
    dict
      "Chart" "the chart scope"
      "Release" "the release scope"
      "Values" "the chart values scope"
  ) }}
*/}}
{{- define "common.labels" -}}
{{ include "common.selectors" . }}
{{ include "common.parcellabtagsdomain" . }}/chart-version: {{ .Chart.Version | quote }}
{{ include "common.parcellabtagsdomain" . }}/chart-name: {{ .Chart.Name | quote }}
{{ include "common.parcellabtagsdomain" . }}/part-of: {{ include "common.chart" . }}
{{- end -}}
