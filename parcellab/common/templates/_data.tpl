{{/* vim: set filetype=mustache: */}}
{{/*
  Keys and quoted values generated from a given dict:
  {{ include "common.dictdata" (
    dict
      "data" "the config data dict"
  ) }}
*/}}
{{- define "common.dictdata" -}}
{{- range $path, $config := .data }}
{{ $path }}: {{ $config | quote }}
{{- end -}}
{{- end -}}

{{/*
  Keys and b64 encoded values generated from a given dict:
  {{ include "common.dictdataencoded" (
    dict
      "data" "the secret data dict"
  ) }}
*/}}
{{- define "common.dictdataencoded" -}}
{{- range $path, $config := .data }}
{{ $path }}: {{ $config | b64enc }}
{{- end -}}
{{- end -}}

{{/*
  File name keys and file content values generated from a given file glob:
  {{ include "common.filedata" (
    dict
      "Files" "the Files scope"
      "fileGlob" "glob pattern to load files from"
  ) }}
*/}}
{{- define "common.filedata" -}}
{{- $root := . -}}
{{- range $path, $bytes := .Files.Glob .fileGlob }}
{{ base $path }}: |-
{{ $root.Files.Get $path | indent 2}}
{{- end -}}
{{- end -}}
