{{- define "common.job" -}}
{{- $job := default (dict "enabled" false) .job -}}
{{- if or .Values.job.enabled $job.enabled -}}
{{- $componentValues := (merge (deepCopy .) (dict "component" $job.name)) -}}
{{- $name := include "common.componentname" $componentValues -}}
apiVersion: batch/v1
kind: Job
metadata:
  generateName: {{ $name }}-
  annotations:
    argocd.argoproj.io/hook: {{ default "Skip" $job.hook }}
  labels:
    {{- include "common.labels" $componentValues | nindent 4 }}
spec:
  activeDeadlineSeconds: {{ default .Values.job.activeDeadlineSeconds $job.activeDeadlineSeconds }}
  backoffLimit: {{ default .Values.job.backoffLimit $job.backoffLimit }}
  ttlSecondsAfterFinished: {{ default .Values.job.ttlSecondsAfterFinished $job.ttlSecondsAfterFinished }}
  template:
    {{- include "common.pod"
      (merge (deepCopy .) (dict "pod" $job "type" "job")) | nindent 4
    }}
{{- end }}
{{- end -}}
