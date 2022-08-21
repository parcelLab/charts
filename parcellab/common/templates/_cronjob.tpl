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
{{- if or .Values.cronjob.enabled $cronjob.enabled -}}
{{- $fullname := include "common.fullname" . -}}
{{- if $cronjob.name -}}
{{- $fullname = printf "%s-%s" $fullname $cronjob.name -}}
{{- end -}}
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ $fullname }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  concurrencyPolicy: {{ default .Values.cronjob.concurrencyPolicy $cronjob.concurrencyPolicy }}
  failedJobsHistoryLimit: {{ default .Values.cronjob.failedJobsHistoryLimit $cronjob.failedJobsHistoryLimit }}
  schedule: {{ default .Values.cronjob.schedule $cronjob.schedule | quote }}
  successfulJobsHistoryLimit: {{ default .Values.cronjob.successfulJobsHistoryLimit $cronjob.successfulJobsHistoryLimit }}
  suspend: {{ default .Values.cronjob.suspend $cronjob.suspend }}
  jobTemplate:
    spec:
      template:
        metadata:
          annotations:
            {{- include "common.pod.annotations" . | nindent 12 }}
          labels:
            {{- include "common.labels" . | nindent 12 }}
            {{- if and .Values.datadog .Values.datadog.enabled }}
            tags.datadoghq.com/env: {{ include "common.env" . | quote }}
            tags.datadoghq.com/service: {{ $fullname | quote }}
            tags.datadoghq.com/version: {{ include "common.version" . | quote }}
            {{- end }}
        spec:
          {{- include "common.pod"
            (merge (deepCopy .) (dict "pod" $cronjob "type" "cronjob")) | indent 10
          }}
{{- end }}
{{- end -}}
