{{/* vim: set filetype=mustache: */}}
{{/*
  Common configmap definition:
  {{ include "cronjob.cronjob" (
    dict
      "Values" "the values scope"
      "cronjob" "The cronjob spec configuration /optional (defaults to empty)"
  ) }}
*/}}
{{- define "common.cronjob" -}}
{{- $cronjob := default (dict "enabled" false) .cronjob -}}
{{- if not $cronjob.job -}}
{{- $_ := set $cronjob "job" dict -}}
{{- end -}}
{{- if or .Values.cronjob.enabled $cronjob.enabled -}}
{{- $componentValues := (merge (deepCopy .) (dict "component" $cronjob.name)) -}}
{{- $name := include "common.componentname" $componentValues -}}
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ $name }}
  labels:
    {{- include "common.labels" $componentValues | nindent 4 }}
spec:
  concurrencyPolicy: {{ default .Values.cronjob.concurrencyPolicy $cronjob.concurrencyPolicy }}
  failedJobsHistoryLimit: {{ default .Values.cronjob.failedJobsHistoryLimit $cronjob.failedJobsHistoryLimit }}
  schedule: {{ default .Values.cronjob.schedule $cronjob.schedule | quote }}
  successfulJobsHistoryLimit: {{ default .Values.cronjob.successfulJobsHistoryLimit $cronjob.successfulJobsHistoryLimit }}
  suspend: {{ default .Values.cronjob.suspend $cronjob.suspend }}
  timeZone: {{ default .Values.cronjob.timeZone $cronjob.timeZone | quote }}
  jobTemplate:
    spec:
      activeDeadlineSeconds: {{ default .Values.cronjob.job.activeDeadlineSeconds $cronjob.activeDeadlineSeconds }}
      backoffLimit: {{ default .Values.cronjob.job.backoffLimit $cronjob.backoffLimit }}
      template:
        {{- include "common.pod"
          (merge (deepCopy .) (dict "pod" $cronjob "type" "cronjob")) | nindent 8
        }}
{{- end }}
{{- end -}}
