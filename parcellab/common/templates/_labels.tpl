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
{{ include "common.domainvariables" . }}/app: {{ include "common.fullname" . }}
{{ include "common.domainvariables" . }}/env: {{ include "common.env" . }}
{{ include "common.domainvariables" . }}/version: {{ include "common.version" . }}
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
{{ include "common.domainvariables" . }}/chart-version: {{ .Chart.Version | quote }}
{{ include "common.domainvariables" . }}/chart-name: {{ .Chart.Name | quote }}
{{ include "common.domainvariables" . }}/part-of: {{ include "common.chart" . }}
{{- end -}}
