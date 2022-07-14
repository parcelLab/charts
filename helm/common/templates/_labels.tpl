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
app: {{ .Chart.Name | quote }}
env: {{ .Values.env | quote }}
version: {{ .Chart.AppVersion | quote }}
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
chart-version: {{ .Chart.Version | quote }}
package: {{ .Chart.Name | quote }}
part-of: {{ include "common.chart" . }}
managed-by: argocd
{{- end -}}
