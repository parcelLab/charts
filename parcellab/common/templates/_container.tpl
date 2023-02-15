{{/* vim: set filetype=mustache: */}}
{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.container" (
    dict
      "container" "The specific pod configuration"
      "type" "The tye of container to define /optional (defaults to 'service')"
  ) }}
*/}}
{{- define "common.container" -}}
{{- $commonRefName := .commonRefName -}}
{{- $name := .name -}}
{{- $image := .image -}}
{{- $containerEnv := .containerEnv -}}
{{- $podVolumes := .volumes -}}
{{- $podSecurityContext := .podSecurityContext -}}
- name: {{ $name }}
  {{- with $podSecurityContext }}
  securityContext:
    {{- toYaml $podSecurityContext | nindent 4 }}
  {{- end }}
  image: {{- toYaml $image | nindent 4 }}
  {{- with .livenessProbe }}
  livenessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .readinessProbe }}
  readinessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  ports:
  {{- range .ports }}
    - name: {{ .name }}
      containerPort: {{ .containerPort }}
      protocol: {{ .protocol }}
  {{- end }}
  resources:
    {{- toYaml .resources | nindent 4 }}
  volumeMounts:
    {{- if and .datadog .datadog.enabled }}
    - name: apmsocketpath
      mountPath: /var/run/datadog
    {{- end }}
    {{- if $podVolumes }}
    {{- range $podVolumes }}
    - name: {{ .name }}
      readOnly: {{ default true .readOnly }}
      mountPath: {{ .mountPath }}
    {{- end }}
    {{- end }}
  env:
    {{- if and .datadog .datadog.enabled }}
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
      value: "true"
    - name: DD_TRACE_AGENT_URL
      value: unix:///var/run/datadog/apm.socket
    {{- end }}
    {{- with $containerEnv }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- if or .config .externalSecret .secretName }}
  envFrom:
    {{- /* Config common to all pods */ -}}
    {{- if .config }}
    - configMapRef:
        name: {{ $commonRefName }}
    {{- end }}
    {{- /* External secret common to all pods */ -}}
    {{- if .externalSecret }}
    - secretRef:
        name: {{ $commonRefName }}
    {{- end }}
  {{- end }}
  {{- end }}
