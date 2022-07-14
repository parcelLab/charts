{{/* vim: set filetype=mustache: */}}
{{/*
  Common service definition:
  {{ include "common.service" (
    dict
      "Chart" "the chart scope"
      "Release" "the release scope"
      "Values" "the values scope"
      "extraSelectors" "Extra pod label selectors" /optional (defaults to empty)
      "nameOverride" "Override the name of the service"
      "service" "The service spec configuration" /optional (defaults to .Values.service)
  ) }}
*/}}
{{- define "common.service" -}}
{{- $extraSelectors := default "" .extraSelectors -}}
{{- $name := default (include "common.fullname" .) .nameOverride -}}
{{- $service := default .Values.service .service -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ $name }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  {{- with $service }}
  type: {{ .type | default "ClusterIP" }}
  ports:
    - port: {{ .port | default 80 }}
      targetPort: {{ .targetPort | default "http" }}
      protocol: {{ .protocol | default "TCP" }}
      name: {{ .name | default "http" }}
  {{- end }}
  selector:
    {{- include "common.selectors" . | nindent 4 }}
    {{- if $extraSelectors }}
    {{- toYaml $extraSelectors | nindent 4 }}
    {{- end }}
{{- end -}}
