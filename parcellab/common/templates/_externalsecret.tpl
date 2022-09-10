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
{{- $fullname := include "common.fullname" . -}}
{{- if .name -}}
{{- $fullname = printf "%s-%s" $fullname .name -}}
{{- end -}}
{{- $targetSpec := dict "creationPolicy" "owner" "deletionPolicy" "retain" "name" $fullname -}}
{{- $secretStoreRefSpec := dict "name" "secretsmanager" "kind" "ClusterSecretStore" -}}
{{- $externalSecret := mergeOverwrite
  (dict "target" $targetSpec "secretStoreRef" $secretStoreRefSpec)
  (default .Values.externalSecret .externalSecret)
-}}
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ $fullname }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  {{- toYaml $externalSecret | nindent 2 }}
{{- end }}
{{- end -}}
