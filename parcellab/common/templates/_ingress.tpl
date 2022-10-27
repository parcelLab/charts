{{/* vim: set filetype=mustache: */}}
{{/*
  Common ingress definition:
  {{ include "common.ingress" (
    dict
      "Values" "the values scope"
      "ingress" "The ingress spec configuration" /optional (defaults to empty)
  ) }}
*/}}
{{- define "common.ingress" -}}
{{- $ingress := default (dict "enabled" false) .ingress -}}
{{- if or .Values.ingress.enabled $ingress.enabled -}}
{{- $componentValues := (merge (deepCopy .) (dict "component" $ingress.name)) -}}
{{- $name := include "common.componentname" $componentValues -}}
{{- $tls := default .Values.ingress.tls $ingress.tls -}}
{{- $serviceName := default $name $ingress.serviceName -}}
{{- $servicePort := default .Values.service.port $ingress.servicePort -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $name }}
  labels:
    {{- include "common.labels" $componentValues | nindent 4 }}
  {{- with default .Values.ingress.annotations $ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  ingressClassName: {{ default .Values.ingress.className $ingress.className }}
  {{- if $tls }}
  tls:
    {{- range $tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range default .Values.ingress.hosts $ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            {{- if .pathType }}
            pathType: {{ .pathType }}
            {{- end }}
            backend:
              service:
                name: {{ $serviceName }}
                port:
                  number: {{ $servicePort }}
          {{- end }}
    {{- end }}
{{- end }}
{{- end -}}
