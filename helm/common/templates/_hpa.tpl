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
{{- $fullname := default (include "common.fullname" .) .name -}}
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ $fullname }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ $fullname }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    {{- if .Values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if .Values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
{{- end -}}
{{- end -}}
