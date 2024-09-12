{{/* vim: set filetype=mustache: */}}
{{/*
Labels to use as selectors
  {{ include "common.selectors" (
    dict
      "Chart" "the chart scope"
      "Release" "the release scope"
      "Values" "the chart values scope"
      "component" "the component of the app /optional (defaults to empty)"
  ) }}
*/}}
{{- define "common.selectors" -}}
{{ include "common.parcellabtagsdomain" . }}/app: {{ include "common.fullname" . | quote }}
{{- if .component }}
{{ include "common.parcellabtagsdomain" . }}/component: {{ .component | quote }}
{{- else }}
{{ include "common.parcellabtagsdomain" . }}/component: "default"
{{- end }}
{{ include "common.parcellabtagsdomain" . }}/env: {{ include "common.env" . | quote }}
{{- end -}}

{{/*
Common labels
  {{ include "common.labels" (
    dict
      "Chart" "the chart scope"
      "Release" "the release scope"
      "Values" "the chart values scope"
      "component" "the component of the app /optional (defaults to empty)"
  ) }}
*/}}
{{- define "common.labels" -}}
{{ include "common.selectors" . }}
{{ include "common.parcellabtagsdomain" . }}/chart-version: {{ .Chart.Version | quote }}
{{ include "common.parcellabtagsdomain" . }}/chart-name: {{ .Chart.Name | quote }}
{{ include "common.parcellabtagsdomain" . }}/part-of: {{ include "common.chart" . | quote }}
{{- end -}}

{{/* This is a dummy comment for testing purposes */}}
