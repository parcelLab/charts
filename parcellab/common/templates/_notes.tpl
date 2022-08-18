{{/* vim: set filetype=mustache: */}}

{{/*
  Define NOTES that will be shown after the helm run:
  {{ include "common.notes" (
    dict
      "Release" "The chart release variables"
      "Values" "The chart values"
  ) }}
*/}}
{{- define "common.notes" -}}
{{- if and .Values.podDisruptionBudget .Values.podDisruptionBudget.enabled }}
Pod Disruption Budget is enabled: {{ toYaml .Values.podDisruptionBudget.spec | nindent 2 }}
{{- else -}}
Pod Disruption Budget is disabled. There are no rules to avoid pods from being restarted.
{{- end }}

{{ if and .Values.vpa .Values.vpa.enabled }}
Vertical Pod Autoscaling is enabled in {{ .Values.vpa.mode }} mode.
{{- if .Values.vpa.ignoreContainers }}
  The following containers will be ignored from the autoscaling configuration:
{{- range .Values.vpa.ignoreContainers }}
    {{ . }}
{{- end }}
{{- end }}
{{- else -}}
Vertical Pod Autoscaling is disabled. Resource requests and limits should be specified per pod.
{{- end }}

{{ if and .Values.autoscaling .Values.autoscaling.enabled }}
Horizontal Pod Autoscaling is enabled with {{ .Values.autoscaling.minReplicas }}-{{ .Values.autoscaling.maxReplicas }} replicas.
{{- else -}}
Horizontal Pod Autoscaling is disabled. Manually set to {{ .Values.replicaCount }} replicas per pod.
{{- end }}

1. Get the application URL by running these commands:
{{- if and .Values.ingress .Values.ingress.enabled }}
{{- range $host := .Values.ingress.hosts }}
  {{- range .paths }}
  http{{ if $.Values.ingress.tls }}s{{ end }}://{{ $host.host }}{{ .path }}
  {{- end }}
{{- end }}
{{- else if and .Values.service (contains "NodePort" .Values.service.type) }}
  export NODE_PORT=$(kubectl get --namespace {{ .Release.Namespace }} -o jsonpath="{.spec.ports[0].nodePort}" services {{ include "common.fullname" . }})
  export NODE_IP=$(kubectl get nodes --namespace {{ .Release.Namespace }} -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT
{{- else if and .Values.service (contains "LoadBalancer" .Values.service.type) }}
     NOTE: It may take a few minutes for the LoadBalancer IP to be available.
           You can watch the status of by running 'kubectl get --namespace {{ .Release.Namespace }} svc -w {{ include "common.fullname" . }}'
  export SERVICE_IP=$(kubectl get svc --namespace {{ .Release.Namespace }} {{ include "common.fullname" . }} --template "{{"{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}"}}")
  echo http://$SERVICE_IP:{{ .Values.service.port }}
{{- else if and .Values.service (contains "ClusterIP" .Values.service.type) }}
  export POD_NAME=$(kubectl get pods --namespace {{ .Release.Namespace }} -l "app.kubernetes.io/name={{ include "common.name" . }},app.kubernetes.io/instance={{ .Release.Name }}" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace {{ .Release.Namespace }} $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace {{ .Release.Namespace }} port-forward $POD_NAME 8080:$CONTAINER_PORT
{{- end }}
{{- end }}
