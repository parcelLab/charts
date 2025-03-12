{{/* vim: set filetype=mustache: */}}
{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.deployment" (
    dict
      "Values" "the values scope"
      "service" "The specific service configuration /optional (defaults to empty)"
      "type" "The tye of pod to define /optional (defaults to 'service')"
  ) }}
*/}}
{{- define "common.deployment" -}}
{{- $service := default dict .service -}}
{{- $componentValues := (merge (deepCopy .) (dict "component" $service.name)) -}}
{{- $name := include "common.componentname" $componentValues -}}
{{- $disableReplicaCount := (ternary $service.disableReplicaCount .Values.disableReplicaCount (hasKey $service "disableReplicaCount")) -}}
{{- $type := default "service" .type -}}
{{- $argoRollout := default .Values.argoRollout $service.argoRollout -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $name }}
  labels:
    {{- include "common.labels" $componentValues | nindent 4 }}
spec:
  {{- if not $disableReplicaCount }}
  replicas: {{ if $argoRollout.enabled }} 0 {{ else }} {{ default .Values.replicaCount $service.replicaCount }} {{ end }}
  {{- end }}
  {{- if hasKey $service "strategy" }}
  strategy:
    {{- toYaml $service.strategy | nindent 4 }}
  {{- else }}
  strategy:
    {{- toYaml .Values.strategy | nindent 4 }}
  {{- end }}
  revisionHistoryLimit: {{ .Values.revisionHistoryLimit }}
  selector:
    matchLabels:
      {{- include "common.selectors" $componentValues | nindent 6 }}
  template:
    {{- include "common.pod"
      (merge (deepCopy .) (dict "pod" $service "type" $type)) | nindent 4
    }}
{{- end -}}
