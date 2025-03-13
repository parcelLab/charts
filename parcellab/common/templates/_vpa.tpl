{{/* vim: set filetype=mustache: */}}
{{/*
  Common vertical pod autoscaler definition:
  {{ include "common.vpa" (
    dict
      "Values" "the values scope"
      "Release" "the release scope"
      "vpa" "The vpa spec configuration" /optional (defaults to empty)
      "name" "The name of the resource and deployment" /optional (defaults to empty)
      "ignoreContainers" "The container names to be ignored" /optional (defaults to empty)
      "targetKind" "The VPA target resource kind" /optional (defaults to Deployment)
  ) }}
*/}}
{{- define "common.vpa" -}}
{{- $vpa := default (dict "enabled" false) .vpa -}}
{{- if or .Values.vpa.enabled $vpa.enabled -}}
{{- $fullname := default (include "common.fullname" .) .name -}}
{{- $ignoreContainers := default .Values.vpa.ignoreContainers .vpa.ignoreContainers -}}
{{- $argoRollout := default .Values.argoRollout .argoRollout -}}
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: {{ $fullname }}
spec:
  targetRef:
    apiVersion: {{ if $argoRollout.enabled }} argoproj.io/v1alpha1 {{ else }} apps/v1 {{ end }}
    kind: {{ if $argoRollout.enabled }} Rollout {{ else }} Deployment {{ end }}
    name: {{ $fullname }}
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
    updateMode: {{ default .Values.vpa.mode $vpa.mode }}
{{- end -}}
{{- end -}}
