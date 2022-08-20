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
{{- $fullname := include "common.fullname" . -}}
{{- $cronjob := default (dict) .cronjob -}}
{{- $cronjobName := default $fullname $cronjob.name -}}
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ $cronjobName }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  concurrencyPolicy: {{ default .Values.concurrencyPolicy $cronjob.concurrencyPolicy }}
  failedJobsHistoryLimit: {{ default .Values.failedJobsHistoryLimit $cronjob.failedJobsHistoryLimit }}
  schedule: {{ default .Values.schedule $cronjob.schedule | quote }}
  successfulJobsHistoryLimit: {{ default .Values.successfulJobsHistoryLimit $cronjob.successfulJobsHistoryLimit }}
  suspend: {{ default .Values.suspend $cronjob.suspend }}
  jobTemplate:
    spec:
      template:
        metadata:
          annotations:
            {{- include "common.pod.annotations" . | nindent 12 }}
            rollme: {{ randAlphaNum 5 | quote }}
          labels:
            {{- include "common.labels" . | nindent 12 }}
            {{- if and .Values.datadog .Values.datadog.enabled }}
            tags.datadoghq.com/env: {{ include "common.env" . | quote }}
            tags.datadoghq.com/service: {{ $cronjobName | quote }}
            tags.datadoghq.com/version: {{ include "common.version" . | quote }}
            {{- end }}
        spec:
          {{- include "common.pod"
            (merge (deepCopy .) (dict "pod" $cronjob "type" "cronjob")) | indent 10
          }}
{{- end -}}
