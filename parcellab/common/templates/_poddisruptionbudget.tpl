{{/* vim: set filetype=mustache: */}}
{{/*
  Common pod disruption budget definition:
  {{ include "common.poddisruptionbudget" (
    dict
      "Values" "the values scope"
      "podDisruptionBudget" "The podDisruptionBudget spec configuration" /optional (defaults to empty)
      "name" "The configmap name" /optional (defaults to empty)
  ) }}
*/}}
{{- define "common.poddisruptionbudget" -}}
{{- $podDisruptionBudget := default (dict "enabled" false) .podDisruptionBudget -}}
{{- $fullname := default (include "common.fullname" .) .name -}}
{{- if or .Values.podDisruptionBudget.enabled $podDisruptionBudget.enabled }}
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: {{ $fullname | default (include "common.fullname" .) }}
spec:
  {{- $pdbSpec := default .Values.podDisruptionBudget.spec $podDisruptionBudget.spec -}}
  {{- toYaml $pdbSpec | nindent 2 }}
  selector:
    matchLabels:
      {{- include "common.selectors" . | nindent 6 }}
{{- end }}
{{- end -}}
