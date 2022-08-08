{{/* vim: set filetype=mustache: */}}
{{/*
  Common secretStore definition:
  {{ include "common.externalsecret" (
    dict
      "Values" "the values scope"
      "externalSecret" "The externalSecret spec configuration" /optional (defaults to .Values.externalSecret)
  ) }}
*/}}
{{- define "common.externalsecret" -}}
{{- if .Values.externalSecret }}
{{- $fullname := default (include "common.fullname" .) .nameOverride -}}
{{- $externalSecret := default .Values.externalSecret .externalSecret -}}
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
