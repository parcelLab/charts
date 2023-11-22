{{/* vim: set filetype=mustache: */}}
{{/*
  Common horizontal pod autoscaler definition:
  {{ include "keda.hpa" (
    dict
      "Values" "the values scope"
      "Release" "the release scope"
  ) }}
*/}}
{{- define "keda.hpa" -}}
{{- $keda := default dict . -}}
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  annotations:
    scaledobject.keda.sh/transfer-hpa-ownership: 'true'
    autoscaling.keda.sh/paused-replicas: "0"
    autoscaling.keda.sh/paused: "{{ .keda.paused }}"

  labels:
    argocd.argoproj.io/instance: keda
  name: {{ .Release.Namespace }}-{{ .Values }}-keda-scale
  namespace: {{ .Release.Namespace }}
spec:
  advanced:
    restoreToOriginalReplicaCount: {{ .keda.restoreToOriginalReplicaCount }}
  cooldownPeriod: {{ .keda.cooldownPeriod }}
  maxReplicaCount: {{ .keda.maxReplicaCount }}
  minReplicaCount: {{ .keda.minReplicaCount }}
  pollingInterval: {{ .keda.pollingInterval }}
  scaleTargetRef:
    name: {{ .keda.scaleTargetName }}
  triggers:
    - metadata:
        awsRegion: {{ .keda.awsRegion }}
        queueLength: {{ .keda.queueLength }}
        queueURL: {{ .keda.queueURL }}
        identityOwner: pod
      type: aws-sqs-queue
      authenticationRef:
        name: cluster-trigger-authentication
        kind: ClusterTriggerAuthentication
{{- end -}}