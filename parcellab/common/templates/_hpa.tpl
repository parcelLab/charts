{{/* vim: set filetype=mustache: */}}
{{/*
  Common horizontal pod autoscaler definition:
  {{ include "common.hpa" (
    dict
      "Values" "the values scope"
      "Release" "the release scope"
      "autoscaling" "The autoscaling spec configuration" /optional (defaults to empty)
      "name" "The name of the resource" /optional (defaults to empty)
  ) }}
*/}}
{{- define "common.hpa" -}}
{{- $autoscaling := default (dict "enabled" false) .autoscaling -}}
{{- if or .Values.autoscaling.enabled $autoscaling.enabled -}}
{{- $fullname := default (include "common.fullname" .) .name -}}
{{- $targetCPUUtilizationPercentage := default .Values.autoscaling.targetCPUUtilizationPercentage $autoscaling.targetCPUUtilizationPercentage -}}
{{- $targetMemoryUtilizationPercentage := default .Values.autoscaling.targetMemoryUtilizationPercentage $autoscaling.targetMemoryUtilizationPercentage -}}
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
  minReplicas: {{ default .Values.autoscaling.minReplicas $autoscaling.minReplicas }}
  maxReplicas: {{ default .Values.autoscaling.maxReplicas $autoscaling.minReplicas }}
  metrics:
    {{- if $targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ $targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if $targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ $targetMemoryUtilizationPercentage }}
    {{- end }}
{{- end -}}
{{- end -}}
