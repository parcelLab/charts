{{/* vim: set filetype=mustache: */}}
{{/*
  Common vertical pod autoscaler definition:
  {{ include "common.vpa" (
    dict
      "Values" "the values scope"
      "Release" "the release scope"
      "name" "The name of the resource and deployment" /optional (defaults to empty)
      "ignoreContainers" "The container names to be ignored" /optional (defaults to empty)
      "targetKind" "The VPA target resource kind" /optional (defaults to Deployment)
  ) }}
*/}}
{{- define "common.vpa" -}}
{{- if .Values.vpa.enabled -}}
{{- $name := default (include "common.fullname" .) .name -}}
{{- $ignoreContainers := default .Values.vpa.ignoreContainers .ignoreContainers -}}
{{- $targetKind := default "Deployment" .targetKind -}}
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: {{ $name }}
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: {{ $targetKind }}
    name: {{ $name }}
  {{- if $ignoreContainers }}
  # Do not apply recommendations automatically to these specified containers
  resourcePolicy:
    containerPolicies:
      {{- range $ignoreContainers }}
      - containerName: {{ . }}
        mode: "Off"
      {{- end }}
  {{- end }}
  updatePolicy:
    updateMode: {{ .Values.vpa.mode | quote }}
{{- end -}}
{{- end -}}
