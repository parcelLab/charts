{{/* vim: set filetype=mustache: */}}
{{/*
  Common service definition:
  {{ include "common.service" (
    dict
      "Chart" "the chart scope"
      "Release" "the release scope"
      "Values" "the values scope"
      "service" "The service spec configuration" /optional (defaults to .Values.service)
  ) }}
*/}}
{{- define "common.service" -}}
{{- $service := default (dict) .service -}}
{{- $fullname := default (include "common.fullname" .) $service.name -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ $fullname }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  type: {{ default .Values.service.type $service.serviceType }}
  ports:
    - port: {{ default .Values.service.port $service.portNumber }}
      targetPort: {{ default .Values.service.targetPort $service.portName }}
      protocol: {{ default .Values.service.protocol $service.portProtocol }}
      name: {{ default .Values.service.name $service.portName }}
  selector:
    {{- include "common.selectors" . | nindent 4 }}
    {{- if $service.extraSelectors }}
    {{- toYaml $service.extraSelectors | nindent 4 }}
    {{- end }}
{{- end -}}
