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
{{- $service := default dict .service -}}
{{- $componentValues := (merge (deepCopy .) (dict "component" $service.name)) -}}
{{- $name := include "common.componentname" $componentValues -}}
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  annotations:
    scaledobject.keda.sh/transfer-hpa-ownership: 'true'
    autoscaling.keda.sh/paused-replicas: "0"
    autoscaling.keda.sh/paused: "{{ $service.keda.paused }}"
  labels:
    argocd.argoproj.io/instance: keda
  name: {{ $name }}-keda-scale
  namespace: {{ .Release.Namespace }}

spec:
  advanced:
    restoreToOriginalReplicaCount: {{ $service.keda.restoreToOriginalReplicaCount }}
  cooldownPeriod: {{ $service.keda.cooldownPeriod }}
  maxReplicaCount: {{ $service.keda.maxReplicaCount }}
  minReplicaCount: {{ $service.keda.minReplicaCount }}
  pollingInterval: {{ $service.keda.pollingInterval }}
  scaleTargetRef:
    name: {{ $service.keda.scaleTargetName }}
  triggers:
    - metadata:
        awsRegion: "{{ $service.keda.awsRegion }}"
        queueLength: "{{ $service.keda.queueLength }}"
        queueURL: {{ $service.keda.queueURL }}
        identityOwner: pod
      type: aws-sqs-queue
      authenticationRef:
        name: cluster-trigger-authentication
        kind: ClusterTriggerAuthentication
{{- end -}}
