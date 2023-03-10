{{/* vim: set filetype=mustache: */}}
{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.container" (
    dict
      "name": "Name for the container"
      "image": "Image for the container"
      "livenessProbe": "Liveness probe for the container"
      "readinessProbe": "Readiness probe for the container"
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
{{- $commonRefName := .commonRefName -}}
{{- $name := .name -}}
{{- $image := .image -}}
{{- $containerEnv := .containerEnv -}}
{{- $podVolumes := .volumes -}}
{{- $podSecurityContext := .podSecurityContext -}}
{{- $datadog := .datadog -}}
{{- $commonExternalSecret := .commonExternalSecret -}}
{{- $commonConfig := .commonConfig -}}
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
    {{- include "common.datadogEnvironmentVariables" (dict "datadog" $datadog) | nindent 4 }}
    {{- with $containerEnv }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- if or .config .externalSecret .secretName }}
  envFrom:
    {{- /* Config common to all pods */ -}}
    {{- if $commonConfig }}
    - configMapRef:
        name: {{ $commonRefName }}
    {{- end }}
    {{- /* Config scoped to a specific pod */ -}}
    {{- if and .config $name }}
    - configMapRef:
        name: {{ printf "%s-%s" $commonRefName $name }}
    {{- end }}
    {{- /* External secret common to all pods */ -}}
    {{- if $commonExternalSecret }}
    - secretRef:
        name: {{ $commonRefName }}
    {{- end }}
    {{- /* External secret scoped to a specific container */ -}}
    {{- if and .externalSecret $name }}
    - secretRef:
        name: {{ printf "%s-%s" $commonRefName $name }}
    {{- end }}
  {{- end }}
  {{- end }}
