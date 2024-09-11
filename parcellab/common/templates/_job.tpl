{{- define "common.job" -}}
{{- $job := default (dict "enabled" false) .job -}}
{{- if or .Values.job.enabled $job.enabled -}}
{{- $componentValues := (merge (deepCopy .) (dict "component" $job.name)) -}}
{{- $name := include "common.componentname" $componentValues -}}
apiVersion: batch/v1
kind: Job
metadata:
  {{- if $job.hook }}
  generateName: {{ $name }}-
  annotations:
    argocd.argoproj.io/hook: {{ $job.hook }}
    argocd.argoproj.io/hook-delete-policy: {{ default "HookSucceeded" $job.hookDeletePolicy }}
  {{- else }}
  name: {{ $name }}
  {{- end }}
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
