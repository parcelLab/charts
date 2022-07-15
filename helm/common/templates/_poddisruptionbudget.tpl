{{/* vim: set filetype=mustache: */}}
{{/*
  Common pod disruption budget definition:
  {{ include "common.poddisruptionbudget" (
    dict
      "Values" "the values scope"
  ) }}
*/}}
{{- define "common.poddisruptionbudget" -}}
{{- if .Values.podDisruptionBudget.enabled }}
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: {{ include "common.fullname" . }}
spec:
  {{- toYaml .Values.podDisruptionBudget.spec | nindent 2 }}
  selector:
    matchLabels:
      {{- include "common.selectors" . | nindent 6 }}
{{- end }}
{{- end -}}
