{{/* vim: set filetype=mustache: */}}
{{/*
  Common serviceaccount definition:
  {{ include "common.serviceaccount" (
    dict
      "Values" "the values scope"
  ) }}
*/}}
{{- define "common.serviceaccount" -}}
{{- if .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "common.serviceAccountName" . }}
  labels:
{{ include "common.labels" . | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
{{- end -}}
