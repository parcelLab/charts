{{/* vim: set filetype=mustache: */}}
{{/*
  Common ingress definition:
  {{ include "common.ingress" (
    dict
      "Values" "the values scope"
  ) }}
*/}}
{{- define "common.ingress" -}}
{{- $ingress := .Values.ingress -}}
{{- $defaultServicePort := .Values.service.port -}}
{{- if $ingress.enabled -}}
{{- $name := include "common.fullname" . }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $name }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with $ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  ingressClassName: {{ $ingress.className }}
  {{- if $ingress.tls }}
  tls:
    {{- range $ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range $ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            {{- if .pathType }}
            pathType: {{ .pathType }}
            {{- end }}
            {{- if .backend }}
            backend:
              {{- toYaml .backend | nindent 14 }}
            {{- else }}
            backend:
              service:
                name: {{ if .Values.argoRollout.enabled }} {{ $name }}-rollout {{ else }} {{ $name }} {{ end }}
                port:
                  number: {{ $defaultServicePort }}
            {{- end }}
          {{- end }}
    {{- end }}
{{- end }}
{{- end -}}
