{{- define "common.routing" -}}
{{- $httproute := .Values.httproute | default dict -}}
{{- $ingress := .Values.ingress | default dict -}}

{{- if $httproute.enabled }}
  {{- include "common.httproute" . }}
{{- else if $ingress.enabled }}
  {{- include "common.ingress" . }}
{{- end }}

{{- end -}}
