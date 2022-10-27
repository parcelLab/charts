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
{{- $componentValues := (merge (deepCopy .) (dict "component" .name)) -}}
{{- $name := include "common.componentname" $componentValues -}}
{{- $targetSpec := dict "creationPolicy" "Owner" "deletionPolicy" "Retain" "name" $name -}}
{{- $secretStoreRefSpec := dict "name" "secretsmanager" "kind" "ClusterSecretStore" -}}
{{- $externalSecret := mergeOverwrite
  (dict "target" $targetSpec "secretStoreRef" $secretStoreRefSpec)
  (default .Values.externalSecret .externalSecret)
}}
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ $name }}
  labels:
    {{- include "common.labels" $componentValues | nindent 4 }}
spec:
  {{- toYaml $externalSecret | nindent 2 }}
{{- end }}
{{- end -}}
