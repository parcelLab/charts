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
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
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
{{- $name := default (include "common.fullname" .) .name -}}
{{- printf "%s.%s.svc.cluster.local" $name .Release.Namespace -}}
{{- end -}}

{{/*
Create the full docker image url
  {{ include "common.imageurl" (
    dict
      "Values" "The Values scope"
  ) }}
*/}}
{{- define "common.imageurl" -}}
{{- if .Values.env }}
{{- if and (eq .Chart.AppVersion "main") ((eq .Values.env "prod")) }}
{{ required (printf "The %s docker tag is not allowed in %s environments" .Chart.AppVersion .Values.env) nil }}
{{- end }}
{{- end }}
{{- printf "ghcr.io/parcellab/%s:%s" .Chart.Name .Chart.AppVersion -}}
{{- end -}}
