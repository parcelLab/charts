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
{{- $envoy := .Values.envoy | default dict -}}
{{- $referenceGrant := .Values.envoy.referenceGrant | default dict -}}
{{- $gateway := $envoy.gateway | default dict -}}
{{- $name := include "common.fullname" . }}
{{- $serviceNamespace := .Release.Namespace }}
{{- if $envoy.enabled -}}
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: {{ (printf "%s-reference-grant" $name) }}
  namespace: {{ $serviceNamespace | quote }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with $referenceGrant.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  from:
    {{- range $referenceGrant.from }}
    - group: {{ .group | default "gateway.networking.k8s.io" | quote }}
      kind: {{ required "referenceGrant.from.kind is required" .kind | quote }}
      namespace: {{ $serviceNamespace | quote }}
      {{- with .name }}
      name: {{ . | quote }}
      {{- end }}
    {{- end }}
  to:
    {{- range $referenceGrant.to }}
    - group: {{ .group | default "" | quote }}
      kind: {{ required "referenceGrant.to.kind is required" .kind | quote }}
      {{- with .name }}
      name: {{ . | quote }}
      {{- end }}
    {{- end }}
{{- end -}}
{{- end -}}
