{{/* vim: set filetype=mustache: */}}
{{/*
  Common secretStore definition:
  {{ include "common.externalsecret" (
    dict
      "Values" "the values scope"
      "externalSecret" "The externalSecret spec configuration" /optional (defaults to .Values.externalSecret)
      "name" "The configmap name" /optional (defaults to empty)
  ) }}
*/}}
{{- define "common.externalsecret" -}}
{{- if or .Values.externalSecret .externalSecret }}
{{- $externalSecret := default .Values.externalSecret .externalSecret -}}
{{- $fullname := include "common.fullname" . -}}
{{- if .name -}}
{{- $fullname = printf "%s-%s" $fullname .name -}}
{{- end -}}
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ $fullname }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  {{- with $externalSecret }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end }}
{{- end -}}
