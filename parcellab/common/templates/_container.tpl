{{/* vim: set filetype=mustache: */}}
{{/*
  Helper function to merge containerEnv from multiple sources:
  {{ include "common.mergeContainerEnv" (dict "global" .Values.containerEnv "local" .pod.containerEnv) }}
*/}}
{{- define "common.mergeContainerEnv" -}}
{{- $envMap := dict -}}
{{- $globalEnv := .global | default dict -}}
{{- $localEnv := .local | default dict -}}

{{- /* Convert global containerEnv to map for deduplication */ -}}
{{- if $globalEnv -}}
{{- if kindIs "slice" $globalEnv -}}
{{- range $globalEnv -}}
{{- $envMap = set $envMap .name . -}}
{{- end -}}
{{- else if kindIs "map" $globalEnv -}}
{{- range $key, $value := $globalEnv -}}
{{- $envMap = set $envMap $key (dict "name" $key "value" ($value | toString)) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- /* Convert local containerEnv to map and override global values */ -}}
{{- if $localEnv -}}
{{- if kindIs "slice" $localEnv -}}
{{- range $localEnv -}}
{{- $envMap = set $envMap .name . -}}
{{- end -}}
{{- else if kindIs "map" $localEnv -}}
{{- range $key, $value := $localEnv -}}
{{- $envMap = set $envMap $key (dict "name" $key "value" ($value | toString)) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- /* Convert back to list and output */ -}}
{{- if $envMap -}}
{{- $merged := list -}}
{{- range $name, $envVar := $envMap -}}
{{- $merged = append $merged $envVar -}}
{{- end -}}
{{- toYaml $merged | trimSuffix "\n" -}}
{{- end -}}
{{- end -}}

{{/*
  Helper function to handle containerEnv in both object and array formats:
  {{ include "common.containerEnvVariables" .containerEnv }}
*/}}
{{- define "common.containerEnvVariables" -}}
{{- if kindIs "slice" . -}}
{{- /* Array format - use as-is */ -}}
{{- toYaml . | trimSuffix "\n" -}}
{{- else if kindIs "map" . -}}
{{- /* Object format - convert to array */ -}}
{{- $items := list -}}
{{- range $key, $value := . -}}
{{- $items = append $items (dict "name" $key "value" ($value | toString)) -}}
{{- end -}}
{{- toYaml $items | trimSuffix "\n" -}}
{{- end -}}
{{- end -}}

{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.container" (
    dict
      "name": "Name for the container"
      "image": "Image for the container"
      "command": "Command for the container"
      "args": "Command arguments for the container"
      "livenessProbe": "Liveness probe for the container"
      "readinessProbe": "Readiness probe for the container"
      "lifecycle": "Lifecycle hooks for the container"
      "ports": "Dict of port specifications (name, containerPort, protocol)"
      "resources": "Additional resources for the container"
      "config": "Configmap for the container"
      "commonConfig" "Configmap passed from the parent service to be present in the container as well"
      "externalSecret": "ExternalSecret for the container"
      "commonExternalSecret" "Secret passed from the parent service to be present in the container as well"
      "securityContext": "As the name tells"
      "volumes" "list of volumes for the container, dict with name, readonly and mountPath"
      "containerEnv" "Environment variables (supports both object and array formats)"
      "datadog" "dict for datadog settings"
      "commonRefName" "Name of the parent service to be included as prefix in the resource names for transparency"
  ) }}
*/}}
{{- define "common.container" -}}
- name: {{ .name }}
  {{- with .command }}
  command:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .args }}
  args:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  image: {{ .image }}
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
    {{- include "common.datadogEnvironmentVariables" (dict "datadog" .datadog) | nindent 4 }}
    {{- if .containerEnv }}
    {{- if kindIs "string" .containerEnv }}
    {{- .containerEnv | nindent 4 }}
    {{- else }}
    {{- include "common.containerEnvVariables" .containerEnv | nindent 4 }}
    {{- end }}
    {{- end }}
  {{- if or .commonConfig .config .commonExternalSecret .externalSecret }}
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
