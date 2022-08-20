{{/* vim: set filetype=mustache: */}}
{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.pod" (
    dict
      "pod" "The specific pod configuration"
      "type" "The tye of pod to define /optional (defaults to 'server')"
  ) }}
*/}}
{{- define "common.pod" -}}
{{- $fullname := include "common.fullname" . -}}
{{- $containerName := default $fullname .pod.containerName -}}
{{- $podName := default $fullname .pod.name -}}
{{- $podVolumes := default .Values.volumes .pod.volumes -}}
{{- $configName := default $fullname .pod.configName -}}
{{- $secretName := default $fullname .pod.secretName -}}
{{- $type := default "server" .type -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "common.serviceAccountName" . }}
{{- with .Values.securityContext }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
{{- end }}
volumes:
  {{- if $podVolumes }}
  {{- range $podVolumes -}}
    - name: {{ .name }}
      {{- toYaml .volumeTemplate | nindent 6 }}
  {{- end }}
  {{- end }}
{{- if and .Values.datadog .Values.datadog.enabled }}
  - hostPath:
      path: /var/run/datadog/
    name: apmsocketpath
{{- end }}
containers:
- name: {{ $containerName }}
  {{- with .Values.podSecurityContext }}
  securityContext:
    {{- toYaml .Values.podSecurityContext | nindent 4 }}
  {{- end }}
  image: {{ include "common.imageurl" . }}
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  {{- with (default .Values.command .pod.command) }}
  command:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if or .Values.config .pod.configName .Values.externalSecret .pod.secretName }}
  envFrom:
    {{- if or .Values.config .pod.configName }}
    - configMapRef:
        name: {{ $configName }}
    {{- end }}
    {{- if or .Values.externalSecret .pod.secretName }}
    - secretRef:
        name: {{ $secretName }}
    {{- end }}
  {{- end }}
  {{- if eq $type "service" }}
  livenessProbe:
    {{- toYaml (default .Values.livenessProbe .pod.livenessProbe) | nindent 4 }}
  readinessProbe:
    {{- toYaml (default .Values.readinessProbe .pod.livenessProbe) | nindent 4 }}
  ports:
    - name: {{ default .Values.service.name .pod.portName }}
      containerPort: {{ default .Values.service.port .pod.portNumber }}
      protocol: {{ default .Values.service.protocol .pod.portProtocol }}
  {{- end }}
  resources:
    {{- toYaml (default .Values.resources .pod.resources) | nindent 4 }}
  volumeMounts:
  {{- if and .Values.datadog .Values.datadog.enabled }}
    - mountPath: /var/run/datadog
      name: apmsocketpath
  {{- end }}
  {{- if $podVolumes }}
  {{- range $podVolumes -}}
    - name: {{ .name }}
      readOnly: {{ default true .readOnly }}
      mountPath: {{ .mountPath }}
  {{- end }}
  {{- end }}
  env:
  {{- if and .Values.datadog .Values.datadog.enabled }}
    - name: DD_ENV
      valueFrom:
        fieldRef:
          fieldPath: metadata.labels['tags.datadoghq.com/env']
    - name: DD_SERVICE
      valueFrom:
        fieldRef:
          fieldPath: metadata.labels['tags.datadoghq.com/service']
    - name: DD_VERSION
      valueFrom:
        fieldRef:
          fieldPath: metadata.labels['tags.datadoghq.com/version']
    - name: DD_LOGS_INJECTION
      value: "true"
    - name: DD_TRACE_ENABLED
      value: "true"
    - name: DD_TRACE_AGENT_URL
      value: unix:///var/run/datadog/apm.socket
  {{- end }}
{{- if eq $type "cronjob" }}
restartPolicy: {{ default "OnFailure" .pod.restartPolicy }}
{{- end }}
{{- with default .Values.nodeSelector .pod.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with default .Values.tolerations .pod.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if default .Values.nodeExclusivity .pod.nodeExclusivity }}
affinity:
  {{- include "common.nodeExclusivity" . | nindent 2 }}
{{- else }}
{{- with default .Values.affinity .pod.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
{{- end -}}
