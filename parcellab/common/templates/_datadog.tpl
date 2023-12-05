{{/* vim: set filetype=mustache: */}}
{{/*
  Create chart/subchart name and version as used by the chart/subchart label:
  {{ include "common.datadogEnvironmentVariables" (
    dict
      "enabled" "flag for datadog enabled"
  ) }}
*/}}
{{- define "common.datadogEnvironmentVariables" -}}
{{- $datadog := .datadog -}}
{{- if and $datadog $datadog.enabled -}}
- name: DD_ENV
  valueFrom:
    fieldRef:
      apiVersion: v1
      fieldPath: metadata.labels['tags.datadoghq.com/env']
- name: DD_SERVICE
  valueFrom:
    fieldRef:
      apiVersion: v1
      fieldPath: metadata.labels['tags.datadoghq.com/service']
- name: DD_VERSION
  valueFrom:
    fieldRef:
      apiVersion: v1
      fieldPath: metadata.labels['tags.datadoghq.com/version']
- name: DD_LOGS_INJECTION
  value: "true"
- name: DD_TRACE_ENABLED
  value: "false"
- name: DD_TRACE_AGENT_URL
  value: unix:///var/run/datadog/apm.socket
- name: DD_AGENT_HOST
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP
{{- end -}}
{{- end -}}
