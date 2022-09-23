{{- define "common.presyncjob" -}}
{{- $presyncjob := default (dict "enabled" false) .presyncjob -}}
{{- if not $presyncjob.job -}}
{{- $_ := set $presyncjob "job" dict -}}
{{- end -}}
{{- if or .Values.presyncjob.enabled $presyncjob.enabled -}}
{{- $fullname := include "common.fullname" . -}}
{{- if $presyncjob.name -}}
{{- $fullname = printf "%s-%s" $fullname $presyncjob.name -}}
{{- end -}}
apiVersion: batch/v1
kind: Job
metadata:
  generateName: {{ $fullname }}-
  annotations:
    argocd.argoproj.io/hook: PreSync
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  activeDeadlineSeconds: {{ default .Values.presyncjob.job.activeDeadlineSeconds $presyncjob.job.activeDeadlineSeconds }}
  backoffLimit: {{ default .Values.presyncjob.job.backoffLimit $presyncjob.job.backoffLimit }}
  template:
    {{- include "common.pod"
      (merge (deepCopy .) (dict "pod" $presyncjob "type" "presyncjob")) | nindent 4
    }}
{{- end }}
{{- end -}}
