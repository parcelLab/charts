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
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "common.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: {{ include "common.imageurl" . }}
          imagePullPolicy: {{ .Values.image.pullPolicy }}
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
    {{- if .Values.nodeExclusivity }}
      affinity:
        {{- include "common.nodeExclusivity" . | nindent 8 }}
    {{- else }}
    {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
    {{- end }}
    {{- end }}
{{- end -}}
