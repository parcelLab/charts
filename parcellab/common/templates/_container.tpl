{{/* vim: set filetype=mustache: */}}
{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.container" (
    dict
      "name": "Name for the container"
      "image": "Image for the container"
      "livenessProbe": "Liveness probe for the container"
      "readinessProbe": "Readiness probe for the container"
      "lifecycle": "Lifecycle hooks for the container"
      "ports": "Dict of port specifications (name, containerPort, protocol)"
      "resources": "Additional resources for the container"
      "config": "Configmap for the container"
      "commonConfig" "Configmap passed from the parent service to be present in the container as well"
      "externalSecret": "ExternalSecret for the container"
      "commonExternalSecret" "Secret passed from the parent service to be present in the container as well"
      "podSecurityContext": "As the name tells"
      "volumes" "list of volumes for the container, dict with name, readonly and mountPath"
      "containerEnv" "Environment variables"
      "datadog" "dict for datadog settings"
      "commonRefName" "Name of the parent service to be included as prefix in the resource names for transparency"
  ) }}
*/}}
{{- define "common.container" -}}
name: {{ .name }}
{{- with .podSecurityContext }}
securityContext:
  {{- toYaml .podSecurityContext | nindent 4 }}
{{- end }}
image: {{- toYaml .image | nindent 2 }}
{{- with .lifecycle }}
lifecycle:
  {{- if .preStop }}
  preStop:
    {{- toYaml .preStop | nindent 6 }}
  {{- end }}
  {{- if .postStart }}
  postStart:
    {{- toYaml .postStart | nindent 6 }}
  {{- end }}
{{- end }}
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
  {{- if .volumes }}
  {{- range .volumes }}
  - name: {{ .name }}
    readOnly: {{ .readOnly }}
    mountPath: {{ .mountPath }}
  {{- end }}
  {{- end }}
env:
  {{- include "common.datadogEnvironmentVariables" (dict "datadog" .datadog) | nindent 2 }}
  {{- with .containerEnv }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- if or .config .externalSecret .secretName }}
envFrom:
  {{- /* Config common to all pods */ -}}
  {{- if .commonConfig }}
  - configMapRef:
      name: {{ .commonRefName }}
  {{- end }}
  {{- /* Config scoped to a specific pod */ -}}
  {{- if and .config .name }}
  - configMapRef:
      name: {{ printf "%s-%s" .commonRefName .name }}
  {{- end }}
  {{- /* External secret common to all pods */ -}}
  {{- if .commonExternalSecret }}
  - secretRef:
      name: {{ .commonRefName }}
  {{- end }}
  {{- /* External secret scoped to a specific container */ -}}
  {{- if and .externalSecret .name }}
  - secretRef:
      name: {{ printf "%s-%s" .commonRefName .name }}
  {{- end }}
{{- end }}
{{- end -}}
