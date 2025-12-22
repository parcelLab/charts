{{/* vim: set filetype=mustache: */}}
{{/*
  Common ReferenceGrant definition:
  {{ include "common.referencegrant" (
    dict
      "Values" "the values scope"
      "Release" .Release
  ) }}
*/}}

{{- define "common.referencegrant" -}}
{{- $referenceGrant := .Values.referenceGrant | default dict -}}
{{- if $referenceGrant.enabled }}
{{- $name := include "common.fullname" . }}
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: {{ $referenceGrant.name | default (printf "%s-grant" $name) }}
  namespace: {{ $referenceGrant.namespace | default .Release.Namespace }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with $referenceGrant.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  from:
    {{- if $referenceGrant.from }}
    {{- range $referenceGrant.from }}
    - group: {{ .group | quote }}
      kind: {{ .kind | quote }}
      namespace: {{ .namespace | quote }}
      {{- with .name }}
      name: {{ . | quote }}
      {{- end }}
    {{- end }}
    {{- else }}
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: {{ .Release.Namespace | quote }}
    {{- end }}
  to:
    {{- if $referenceGrant.to }}
    {{- range $referenceGrant.to }}
    - group: {{ .group | quote }}
      kind: {{ .kind | quote }}
      {{- with .name }}
      name: {{ . | quote }}
      {{- end }}
    {{- end }}
    {{- else }}
    - group: ""
      kind: Service
    {{- end }}
{{- end }}
{{- end -}}
