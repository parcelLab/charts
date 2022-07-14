{{/* vim: set filetype=mustache: */}}
{{/*
  Common horizontal pod autoscaler definition:
  {{ include "common.hpa" (
    dict
      "Values" "the values scope"
      "Release" "the release scope"
      "name" "The name of the resource" /optional (defaults to empty)
  ) }}
*/}}
{{- define "common.hpa" -}}
{{- if .Values.autoscaling.enabled -}}
{{- $name := default (include "common.fullname" .) .name -}}
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ $name }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ $name }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    {{- if .Values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        targetAverageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if .Values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        targetAverageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
{{- end -}}
{{- end -}}
