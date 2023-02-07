{{/* vim: set filetype=mustache: */}}

{{/*
  Create chart/subchart name and version as used by the chart/subchart label:
  {{ include "common.chart" (
    dict
      "Chart" "The Chart scope"
      "Release" "The Release scope"
      "Values" "The Values scope"
  ) }}
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
  Expand the name of the chart/subchart:
  {{ include "common.name" (
    dict
      "Chart" "The Chart scope"
      "Values" "The Values scope"
  ) }}
*/}}
{{- define "common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
  Format fully qualified app name from the chart and release name.
  We truncate at 63 chars because some Kubernetes name fields are limited to this
  (by the DNS naming spec).
  If release name contains chart name it will be used as a full name:
  {{ include "common.formatname" (
    dict
      "chartName" "The chart name to be formatted"
      "releaseName" "The release  name to be formatted"
  ) }}
*/}}
{{- define "common.formatname" -}}
{{- if contains .chartName .releaseName -}}
{{- .releaseName | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .releaseName .chartName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
  Create a default fully qualified app name (for the subchart that uses it).
  {{ include "common.fullname" (
    dict
      "Release" "The Release scope"
      "Values" "The Values scope",
  ) }}
*/}}
{{- define "common.fullname" -}}
{{- if .Values.name -}}
{{- .Values.name -}}
{{- else if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
  Create a component name out of the global fullname if applicable.
  This name is used to differentiate the same application with different entry points.
  {{ include "common.componentname" (
    dict
      "Release" "The Release scope"
      "Values" "The Values scope",
      "component" "the component of the app /optional (defaults to empty)"
  ) }}
*/}}
{{- define "common.componentname" -}}
{{- if .component -}}
{{- printf "%s-%s" (include "common.fullname" .) .component -}}
{{- else -}}
{{- include "common.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
  {{ include "common.serviceAccountName" (
    dict
      "Values" "The Values scope"
  ) }}
*/}}
{{- define "common.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the internal Kubernetes service FQDN
  {{ include "common.fqdn" (
    dict
      "Values" "The Values scope"
      "Release" "The Release scope"
      "name" "The name of the resource" /optional (defaults to empty)
  ) }}
*/}}
{{- define "common.fqdn" -}}
{{- $fullname := default (include "common.fullname" .) .name -}}
{{- printf "%s.%s.svc.cluster.local" $fullname .Release.Namespace -}}
{{- end -}}

{{/*
Create the application version
  {{ include "common.version" (
    dict
      "Values" "The Values scope"
  ) }}
*/}}
{{- define "common.version" -}}
{{ default .Chart.AppVersion .Values.image.tag }}
{{- end -}}

{{/*
Create the application environment
  {{ include "common.env" (
    dict
      "Values" "The Values scope"
  ) }}
*/}}
{{- define "common.env" -}}
{{ default "prod" .Values.env }}
{{- end -}}

{{/*
Create the application domain namespace for labels and annotation variables
  {{ include "common.parcellabtagsdomain" (
    dict
      "Values" "The Values scope"
  ) }}
*/}}
{{- define "common.parcellabtagsdomain" -}}
parcellab.dev
{{- end -}}

{{/*
Create the image repository
  {{ include "common.imagerepository" (
    dict
      "Values" "The Values scope"
  ) }}
*/}}
{{- define "common.imagerepository" -}}
{{- if .Values.image.repository -}}
{{- .Values.image.repository -}}
{{- else if and .Values.name .Values.orgRepository -}}
{{- printf "%s/%s" .Values.orgRepository .Values.name -}}
{{- else if .Values.name -}}
{{- .Values.name -}}
{{- else -}}
{{- .Chart.Name -}}
{{- end -}}
{{- end -}}

{{/*
Create the full docker image url
  {{ include "common.imageurl" (
    dict
      "Values" "The Values scope"
  ) }}
*/}}
{{- define "common.imageurl" -}}
{{- printf "%s:%s" (include "common.imagerepository" .) (include "common.version" .) -}}
{{- end -}}
