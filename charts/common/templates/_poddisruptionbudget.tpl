{{/* vim: set filetype=mustache: */}}
{{/*
  Common pod disruption budget definition:
  {{ include "common.poddisruptionbudget" (
    dict
      "Values" "the values scope"
      "Release" "the release scope"
      "component" "The component to target" /optional (defaults to empty)
  ) }}
*/}}
{{- define "common.poddisruptionbudget" -}}
{{- if .Values.podDisruptionBudget.enabled }}
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  {{- if .component }}
  name: {{ printf "%s-%s" (include "common.fullname" .) .component }}
  {{- else }}
  name: {{ include "common.fullname" . }}
  {{- end }}
spec:
  {{- toYaml .Values.podDisruptionBudget.spec | nindent 2 }}
  selector:
    matchLabels:
      {{- include "common.selectors" . | nindent 6 }}
      {{- if .component }}
      component: {{ .component }}
      {{- end }}
{{- end }}
{{- end -}}
