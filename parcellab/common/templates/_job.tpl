{{- define "common.job" -}}
{{- $job := default (dict "enabled" false) .job -}}
{{- if not $job.job -}}
{{- $_ := set $job "job" dict -}}
{{- end -}}
{{- if or .Values.job.enabled $job.enabled -}}
{{- $fullname := include "common.fullname" . -}}
{{- if $job.name -}}
{{- $fullname = printf "%s-%s" $fullname $job.name -}}
{{- end -}}
apiVersion: batch/v1
kind: Job
metadata:
  generateName: {{ $fullname }}-
  annotations:
    argocd.argoproj.io/hook: {{ default "Skip" $job.hook }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  activeDeadlineSeconds: {{ default .Values.job.job.activeDeadlineSeconds $job.job.activeDeadlineSeconds }}
  backoffLimit: {{ default .Values.job.job.backoffLimit $job.job.backoffLimit }}
  template:
    {{- include "common.pod"
      (merge (deepCopy .) (dict "pod" $job "type" "job")) | nindent 4
    }}
{{- end }}
{{- end -}}
