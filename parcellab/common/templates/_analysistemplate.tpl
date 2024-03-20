{{/* vim: set filetype=mustache: */}}
{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.analysistemplate" (
    dict
      "name" "the name data dict"
      "metrics" "the metrics data dict"
  ) }}
*/}}
{{- define "common.analysisTemplate" -}}
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: {{ .name }}
spec:
  args:
  - name: service-name
  metrics:
{{- if .metrics }}
{{- if eq (typeOf .metrics) "list" }}
{{ toYaml .metrics | indent 4 }}
{{- else }}
  - {{ toYaml .metrics | indent 4 | trim }}
{{- end }}
{{- end }}
---
{{- end }}
