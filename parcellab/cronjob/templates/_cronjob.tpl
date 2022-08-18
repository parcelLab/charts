{{/* vim: set filetype=mustache: */}}
{{/*
  Common configmap definition:
  {{ include "cronjob.cronjob" (
    dict
      "Values" "the values scope"
      "cronjob" "The cronjob configuration"
  ) }}
*/}}
{{- define "cronjob.cronjob" -}}
{{- $fullname := include "common.fullname" . }}
{{- $cronjobname := printf "%s-%s" $fullname .cronjob.name }}
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ $cronjobname }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  concurrencyPolicy: {{ .cronjob.concurrencyPolicy | default "Allow" }}
  failedJobsHistoryLimit: {{ .cronjob.failedJobsHistoryLimit | default 1 }}
  schedule: {{ .cronjob.schedule | quote }}
  successfulJobsHistoryLimit: {{ .cronjob.successfulJobsHistoryLimit | default 3 }}
  suspend: {{ .cronjob.suspend | default false }}
  jobTemplate:
    spec:
      template:
        metadata:
          annotations:
            {{- include "common.pod.annotations" . | nindent 12 }}
          labels:
            {{- include "common.labels" . | nindent 12 }}
            {{- if and .Values.datadog .Values.datadog.enabled }}
            tags.datadoghq.com/env: {{ include "common.env" . | quote }}
            tags.datadoghq.com/service: {{ $cronjobname | quote }}
            tags.datadoghq.com/version: {{ include "common.version" . | quote }}
            {{- end }}
        spec:
          {{- with .Values.imagePullSecrets }}
          imagePullSecrets:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          serviceAccountName: {{ include "common.serviceAccountName" . }}
          securityContext:
            {{- toYaml .Values.podSecurityContext | nindent 12 }}
          {{- if and .Values.datadog .Values.datadog.enabled }}
          volumes:
            - hostPath:
                path: /var/run/datadog/
              name: apmsocketpath
          {{- end }}
          containers:
          - name: {{ .Chart.Name }}
            image: {{ include "common.imageurl" . }}
            imagePullPolicy: {{ .Values.image.pullPolicy }}
            {{- with .cronjob.command }}
            command:
              {{- toYaml . | nindent 14 }}
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
            resources:
              {{- toYaml .Values.resources | nindent 14 }}
            {{- if and .Values.datadog .Values.datadog.enabled }}
            volumeMounts:
              - mountPath: /var/run/datadog
                name: apmsocketpath
            env:
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
          restartPolicy: OnFailure
          {{- with .Values.nodeSelector }}
          nodeSelector:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.tolerations }}
          tolerations:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- if .Values.nodeExclusivity }}
          affinity:
            {{- include "common.nodeExclusivity" . | nindent 12 }}
          {{- else }}
          {{- with .Values.affinity }}
          affinity:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- end }}
{{- end -}}
