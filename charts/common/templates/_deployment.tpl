{{/* vim: set filetype=mustache: */}}
{{/*
  Common deployment definition:
  {{ include "common.deployment" (
    dict
      "Values" "the values scope"
  ) }}
*/}}
{{- define "common.deployment" -}}
{{- $fullname := include "common.fullname" . }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $fullname }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
    {{- include "common.datadog" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
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
    spec:
      serviceAccountName: {{ include "common.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      volumes:
        - hostPath:
            path: /var/run/datadog/
          name: apmsocketpath
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: {{ include "common.imageurl" . }}
          imagePullPolicy: Always
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
          envFrom:
            {{- if .Values.config }}
            - configMapRef:
                name: {{ $fullname }}
            {{- end }}
            {{- if .Values.secret }}
            - secretRef:
                name: {{ $fullname }}
            {{- end }}
          livenessProbe:
            {{- toYaml .Values.livenessProbe | nindent 12 }}
          readinessProbe:
            {{- toYaml .Values.readinessProbe | nindent 12 }}
          ports:
            - name: {{ .Values.service.name }}
              containerPort: {{ .Values.service.port }}
              protocol: {{ .Values.service.protocol }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
    {{- end }}
    {{- if .Values.includeAntiaffinity }}
      affinity:
        {{- include "common.antiaffinity" . | nindent 8 }}
    {{- end }}
{{- end -}}
