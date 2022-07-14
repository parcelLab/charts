{{/*
  Anti affinity rules to avoid pods from same app release to be in the same node:
  {{ include "common.nodeExclusivity" (
    dict
      "Release" "the release scope"
  ) }}
*/}}
{{- define "common.nodeExclusivity" -}}
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels:
        {{- include "common.selectors" . | nindent 8 }}
    topologyKey: "kubernetes.io/hostname"
{{- end -}}
