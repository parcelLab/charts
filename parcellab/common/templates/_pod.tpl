{{/* vim: set filetype=mustache: */}}
{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.pod" (
    dict
      "pod" "The specific pod configuration"
      "type" "The tye of pod to define /optional (defaults to 'service')"
  ) }}
*/}}
{{- define "common.pod" -}}
{{- $fullname := include "common.fullname" . -}}
{{- $containerName := default $fullname .pod.containerName -}}
{{- $podName := default $fullname .pod.name -}}
{{- $configName := default $fullname .pod.configName -}}
{{- $secretName := default $fullname .pod.secretName -}}
{{- $containerEnv := default .Values.containerEnv .pod.containerEnv -}}
{{- $podVolumes := default .Values.volumes .pod.volumes -}}
{{- $type := default "service" .type -}}
metadata:
  annotations:
  {{- with .Values.podAnnotations }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
    {{- include "common.pod.annotations" . | nindent 4 }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
    {{- if and .Values.datadog .Values.datadog.enabled }}
    tags.datadoghq.com/env: {{ include "common.env" . | quote }}
    tags.datadoghq.com/service: {{ $fullname | quote }}
    tags.datadoghq.com/version: {{ include "common.version" . | quote }}
    {{- end }}
spec:
  {{- with .Values.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  serviceAccountName: {{ include "common.serviceAccountName" . }}
  {{- with .Values.securityContext }}
  securityContext:
    {{- toYaml .Values.podSecurityContext | nindent 4 }}
  {{- end }}
  volumes:
    {{- if $podVolumes }}
    {{- range $podVolumes -}}
    - name: {{ .name }}
      {{- toYaml .volumeTemplate | nindent 6 }}
    {{- end }}
    {{- end }}
    {{- if and .Values.datadog .Values.datadog.enabled }}
    - name: apmsocketpath
      hostPath:
        path: /var/run/datadog/
    {{- end }}
  containers:
    - name: {{ $containerName }}
      {{- with .Values.podSecurityContext }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      {{- end }}
      image: {{ include "common.imageurl" . }}
      imagePullPolicy: {{ .Values.image.pullPolicy }}
      {{- if eq $type "cronjob" }}
      {{- with (default .Values.cronjob.command .pod.command) }}
      command:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- else }}
      {{- with (default .Values.command .pod.command) }}
      command:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- end }}
      {{- with (default .Values.livenessProbe .pod.livenessProbe) }}
      livenessProbe:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if eq $type "service" }}
      {{- with (default .Values.readinessProbe .pod.readinessProbe) }}
      readinessProbe:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      ports:
        - name: {{ default .Values.service.name .pod.portName }}
          containerPort: {{ default .Values.service.port .pod.portNumber }}
          protocol: {{ default .Values.service.protocol .pod.portProtocol }}
      {{- end }}
      resources:
        {{- toYaml (default .Values.resources .pod.resources) | nindent 8 }}
      volumeMounts:
        {{- if and .Values.datadog .Values.datadog.enabled }}
        - name: apmsocketpath
          mountPath: /var/run/datadog
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
        {{- toYaml . | nindent 8 }}
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
  {{- if eq $type "cronjob" }}
  restartPolicy: {{ default "OnFailure" .pod.restartPolicy }}
  {{- end }}
  {{- with default .Values.nodeSelector .pod.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with default .Values.tolerations .pod.tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with default .Values.affinity .pod.affinity }}
  affinity:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
