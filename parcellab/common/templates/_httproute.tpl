{{/* vim: set filetype=mustache: */}}
{{/*
  Common httproute definition:
  {{ include "common.httproute" (
    dict
      "Values" "the values scope"
  ) }}
*/}}

{{- define "common.httproute" -}}
{{- $httproute := .Values.httproute | default dict -}}
{{- if $httproute.enabled }}
{{- $name := include "common.fullname" . }}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ include "common.fullname" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  parentRefs:
    - name: {{ required "httproute.parentGateway is required" $httproute.parentGateway }}
      namespace: {{ $httproute.parentGatewayNamespace | default "envoy-gateway" }}
  {{- with $httproute.hosts }}
  hostnames:
    {{- range . }}
    - {{ . | quote }}
    {{- end }}
  {{- end }}
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: {{ $httproute.path | default "/" }}
      backendRefs:
        - name: {{ include "common.fullname" . }}
          port: {{ .Values.service.port }}
{{- end }}
{{- end -}}
