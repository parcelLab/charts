{{/* vim: set filetype=mustache: */}}
{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.pod" (
    dict
      "pod" "The specific pod configuration"
      "type" "The type of pod to define /optional (defaults to 'service')"
  ) }}
*/}}
{{- define "common.pod" -}}
{{- $fullname := include "common.fullname" . -}}
{{- $componentValues := (merge (deepCopy .) (dict "component" .pod.name)) -}}
{{- $name := include "common.componentname" $componentValues -}}
{{- $containerName := default $name .pod.containerName -}}
{{- $containerEnv := default .Values.containerEnv .pod.containerEnv -}}
{{- $podVolumes := default .Values.volumes .pod.volumes -}}
{{- $commonExternalSecret := .Values.externalSecret -}}
{{- $commonConfig := .Values.config -}}
{{- $extraContainers := .pod.extraContainers -}}
{{- $initContainers := .pod.initContainers -}}
{{- $datadog := .Values.datadog -}}
{{- $type := default "service" .type -}}
metadata:
  annotations:
    {{- if and $datadog $datadog.enabled }}
    "cluster-autoscaler.kubernetes.io/safe-to-evict-local-volumes": "apmsocketpath"
    {{- end }}
  {{- with .Values.podAnnotations }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .pod.annotations }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
    {{- include "common.pod.annotations" . | nindent 4 }}
  labels:
    {{- include "common.labels" $componentValues | nindent 4 }}
    {{- if and $datadog $datadog.enabled }}
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
  {{- with .Values.hostAliases }}
  hostAliases:
    {{- toYaml .Values.hostAliases | nindent 4 }}
  {{- end }}
  terminationGracePeriodSeconds: {{ default 30 .Values.terminationGracePeriodSeconds }}
  volumes:
    {{- if $podVolumes }}
    {{- range $podVolumes }}
    - name: {{ .name }}
      {{- toYaml .volumeTemplate | nindent 6 }}
    {{- end }}
    {{- end }}
    {{- if and $datadog $datadog.enabled }}
    - name: apmsocketpath
      hostPath:
        path: /var/run/datadog/
    {{- end }}
  {{- if $initContainers }}
  initContainers:
  {{- range $initContainers }}
    {{- include "common.container" (merge (deepCopy .) (dict "volumes" $podVolumes "containerEnv" $containerEnv "datadog" $datadog "commonExternalSecret" $commonExternalSecret "commonConfig" $commonConfig "commonRefName" $fullname)) | nindent 4 }}
  {{- end }}
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
      {{- if eq $type "service" }}
      {{- /* Retrieve liveness and readiness probes from the global if not defined */ -}}
      {{- with (default .Values.lifecycle .pod.lifecycle) }}
      lifecycle:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with (default .Values.livenessProbe .pod.livenessProbe) }}
      livenessProbe:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with (default .Values.readinessProbe .pod.readinessProbe) }}
      readinessProbe:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      ports:
        - name: {{ default .Values.service.name .pod.portName }}
          containerPort: {{ default .Values.service.port .pod.portNumber }}
          protocol: {{ default .Values.service.protocol .pod.portProtocol }}
        {{- if .Values.service.extraPorts }}
        {{- range .Values.service.extraPorts }}
        - name: {{ .name }}
          containerPort: {{ .port }}
          protocol: {{ default "TCP" .protocol }}
        {{- end }}
        {{- end }}
      {{- else }}
      {{- /* Force liveness and readiness probes to be defined if the deployment is not a service */ -}}
      {{- with .pod.livenessProbe }}
      livenessProbe:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .pod.readinessProbe }}
      readinessProbe:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- end }}
      resources:
        {{- toYaml (default .Values.resources .pod.resources) | nindent 8 }}
      volumeMounts:
        {{- if and $datadog $datadog.enabled }}
        - name: apmsocketpath
          mountPath: /var/run/datadog
        {{- end }}
        {{- if $podVolumes }}
        {{- range $podVolumes }}
        - name: {{ .name }}
          readOnly: {{ .readOnly }}
          mountPath: {{ .mountPath }}
        {{- end }}
        {{- end }}
      env:
        {{- include "common.datadogEnvironmentVariables" (dict "datadog" $datadog) | nindent 8 }}
        {{- with $containerEnv }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- if or .Values.config .pod.configName .Values.externalSecret .pod.secretName }}
      envFrom:
        {{- /* Config common to all pods */ -}}
        {{- if $commonConfig }}
        - configMapRef:
            name: {{ $fullname }}
        {{- end }}
        {{- if and .pod.config .pod.name }}
        {{- /* Config scoped to a specific pod */ -}}
        - configMapRef:
            name: {{ $name }}
        {{- end }}
        {{- /* External secret common to all pods */ -}}
        {{- if $commonExternalSecret }}
        - secretRef:
            name: {{ $fullname }}
        {{- end }}
        {{- /* External secret scoped to a specific pod */ -}}
        {{- if and .pod.externalSecret .pod.name }}
        - secretRef:
            name: {{ $name }}
        {{- end }}
      {{- end }}
  {{- if $extraContainers }}
  {{- range $extraContainers }}
    {{- include "common.container" (merge (deepCopy .) (dict "volumes" $podVolumes "containerEnv" $containerEnv "datadog" $datadog "commonExternalSecret" $commonExternalSecret "commonConfig" $commonConfig "commonRefName" $fullname)) | nindent 4 }}
  {{- end }}
  {{- end }}
  {{- if or (eq $type "cronjob") (eq $type "job") }}
  restartPolicy: {{ default "OnFailure" .pod.restartPolicy }}
  {{- end }}
  {{- with default .Values.nodeSelector .pod.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with default .pod.hostAliases }}
  hostAliases:
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
