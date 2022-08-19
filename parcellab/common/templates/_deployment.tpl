{{/* vim: set filetype=mustache: */}}
{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.deployment" (
    dict
      "data" "the config data dict"
      "workload" "The specific workload configuration"
  ) }}
*/}}
{{- define "common.deployment" -}}
{{- $fullname := include "common.fullname" . -}}
{{- $workload := default .Values.workload .workload -}}
{{- $workloadname := default $fullname $workload.name -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $workloadname }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  {{- if not (default .Values.autoscaling.enabled $workload.autoscaling.enabled) }}
  replicas: {{ default .Values.replicaCount $workload.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "common.selectors" . | nindent 6 }}
  template:
    metadata:
      annotations:
        {{- include "common.pod.annotations" . | nindent 8 }}
      labels:
        {{- include "common.labels" . | nindent 8 }}
        {{- if and .Values.datadog .Values.datadog.enabled }}
        tags.datadoghq.com/env: {{ include "common.env" . | quote }}
        tags.datadoghq.com/service: {{ $workloadname | quote }}
        tags.datadoghq.com/version: {{ include "common.version" . | quote }}
        {{- end }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "common.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      volumes:
        {{- if $workload.volumes }}
        {{- range $workload.volumes -}}
          - name: {{ .name }}
            {{- toYaml .volumeTemplate | nindent 12 }}
        {{- end }}
        {{- end }}
      {{- if and .Values.datadog .Values.datadog.enabled }}
        - hostPath:
            path: /var/run/datadog/
          name: apmsocketpath
      {{- end }}
      containers:
      - name: {{ $fullname }}
        securityContext:
          {{- toYaml .Values.securityContext | nindent 10 }}
        image: {{ include "common.imageurl" . }}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        {{- with $workload.command }}
        command:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        envFrom:
          {{- if .Values.config }}
          - configMapRef:
              name: {{ $fullname }}
          {{- end }}
          {{- if .Values.externalSecret }}
          - secretRef:
              name: {{ $fullname }}
          {{- end }}
        livenessProbe:
          {{- toYaml (default .Values.livenessProbe $workload.livenessProbe) | nindent 10 }}
        readinessProbe:
          {{- toYaml (default .Values.readinessProbe $workload.livenessProbe) | nindent 10 }}
        ports:
          - name: {{ default .Values.service.name $workload.service.name }}
            containerPort: {{ default .Values.service.port $workload.service.port }}
            protocol: {{ default .Values.service.protocol $workload.service.protocol }}
        resources:
          {{- toYaml (default .Values.resources $workload.resources) | nindent 10 }}
        volumeMounts:
        {{- if and .Values.datadog .Values.datadog.enabled }}
          - mountPath: /var/run/datadog
            name: apmsocketpath
        {{- end }}
        {{- if $workload.volumes }}
        {{- range $workload.volumes -}}
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
    {{- with default .Values.nodeSelector $workload.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
    {{- end }}
    {{- with default .Values.tolerations $workload.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
    {{- end }}
    {{- if default .Values.nodeExclusivity $workload.nodeExclusivity }}
      affinity:
        {{- include "common.nodeExclusivity" . | nindent 8 }}
    {{- else }}
    {{- with default .Values.affinity $workload.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
    {{- end }}
    {{- end }}
{{- end -}}
