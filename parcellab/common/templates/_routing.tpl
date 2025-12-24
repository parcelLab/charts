{{- define "common.routing" -}}
{{- $envoy := .Values.envoy | default dict -}}
{{- $httproute := $envoy.httpRoute | default dict -}}
{{- $ingress := .Values.ingress | default dict -}}

{{- if $httproute.enabled }}
  {{- include "common.httproute" . }}
{{- else if $ingress.enabled }}
  {{- include "common.ingress" . }}
{{- end }}

{{- end -}}
