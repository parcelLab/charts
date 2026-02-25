{{/* vim: set filetype=mustache: */}}
{{/*
  Common ingress definition:
  {{ include "common.ingress" (
    dict
      "Values" "the values scope"
  ) }}
*/}}
{{- define "common.ingress" -}}
{{- $root := . -}}
{{- $ingress := .Values.ingress -}}
{{- $defaultServicePort := .Values.service.port -}}
{{- if $ingress.enabled -}}
{{- $name := include "common.fullname" . }}
{{- $rolloutServices := include "common.rolloutServicesMap" (dict "root" $root "baseName" $name) | fromJson -}}
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
  {{- with $ingress.defaultBackend }}
  defaultBackend:
    service:
      name: {{ .service.name }}
      port:
        name: {{ .service.port.name }}
  {{- end }}
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
            {{- $backendCopy := deepCopy .backend -}}
            {{- if and $backendCopy.service $backendCopy.service.name (hasKey $rolloutServices $backendCopy.service.name) (not (hasSuffix "-rollout" $backendCopy.service.name)) -}}
            {{- $_ := set $backendCopy.service "name" (printf "%s-rollout" $backendCopy.service.name) -}}
            {{- end }}
            backend:
              {{- toYaml $backendCopy | nindent 14 }}
            {{- else }}
            backend:
              service:
                name: {{ if (hasKey $rolloutServices $name) }}{{ $name }}-rollout{{ else }}{{ $name }}{{ end }}
                port:
                  number: {{ $defaultServicePort }}
            {{- end }}
          {{- end }}
    {{- end }}
{{- end }}
{{- end -}}
