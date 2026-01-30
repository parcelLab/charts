{{/* vim: set filetype=mustache: */}}
{{/*
  Render Envoy Gateway SecurityPolicy resources defined under
  .Values.envoy.security.policies. Each policy renders as a complete resource
  (OIDC, JWT, authorization) while inheriting defaults from envoy.security.*.
*/}}
{{- define "common.securitypolicies" -}}
{{- $values := .Values -}}
{{- $envoy := default (dict "enabled" false) $values.envoy -}}
{{- if $envoy.enabled }}
{{- $security := default dict $envoy.security -}}
{{- $policies := default (list) $security.policies -}}
{{- if $policies }}
{{- $scope := dict "Values" $values "Release" .Release -}}
{{- $serviceName := default (include "common.fullname" $scope) $values.name -}}
{{- $policyNamespace := .Release.Namespace -}}
{{- $securityLabelKey := printf "%s/security-required" (include "common.parcellabtagsdomain" .) -}}
{{- $globalIssuer := $security.issuer -}}
{{- $globalRedirectURL := $security.redirectURL -}}
{{- $globalCookieDomain := $security.cookieDomain -}}
{{- $globalLogoutPath := $security.logoutPath -}}
{{- $globalClientID := $security.clientID -}}
{{- $globalClientSecretName := $security.clientSecretName -}}
{{- $globalScopes := $security.scopes -}}
{{- $globalClaimHeaders := $security.claimToHeaders -}}
{{- $globalJwtProviderName := $security.jwtProviderName -}}
{{- $globalJwksURI := $security.jwksURI -}}

{{ range $policyIndex, $policy := $policies }}
{{- $policyName := required (printf "envoy.security.policies[%d].name is required" $policyIndex) $policy.name -}}
{{- $issuer := required (printf "SecurityPolicy %q requires envoy.security.issuer or policies[].issuer" $policyName) (coalesce $policy.issuer $globalIssuer) -}}
{{- $redirectURL := required (printf "SecurityPolicy %q requires redirectURL (set envoy.security.redirectURL or policies[].redirectURL)" $policyName) (coalesce $policy.redirectURL $globalRedirectURL) -}}
{{- $cookieDomain := required (printf "SecurityPolicy %q requires cookieDomain (set envoy.security.cookieDomain or policies[].cookieDomain)" $policyName) (coalesce $policy.cookieDomain $globalCookieDomain) -}}
{{- $logoutPath := coalesce $policy.logoutPath $globalLogoutPath "/logout" -}}
{{- $clientID := coalesce $policy.clientID $globalClientID $serviceName -}}
{{- $defaultSecretName := printf "%s-oidc-secret" $serviceName -}}
{{- $clientSecretName := coalesce $policy.clientSecretName $globalClientSecretName $defaultSecretName -}}
{{- $scopes := coalesce $policy.scopes $globalScopes -}}
{{- $claimToHeaders := coalesce $policy.claimToHeaders $globalClaimHeaders -}}
{{- $jwtProviderName := coalesce $policy.jwtProviderName $globalJwtProviderName "keycloak" -}}
{{- $jwksURI := coalesce $policy.jwksURI $globalJwksURI (printf "%s/protocol/openid-connect/certs" $issuer) -}}
{{- $targetRef := $policy.targetRef -}}
{{- $targetRefs := $policy.targetRefs -}}
{{- $rawSelectors := list -}}
{{- if $policy.targetSelectors }}
  {{- if kindIs "slice" $policy.targetSelectors }}
    {{- $rawSelectors = $policy.targetSelectors -}}
  {{- else }}
    {{- $rawSelectors = list $policy.targetSelectors -}}
  {{- end }}
{{- else if $policy.targetSelector }}
  {{- $rawSelectors = list $policy.targetSelector -}}
{{- end }}
{{- if and (not $targetRef) (not $targetRefs) (eq (len $rawSelectors) 0) }}
  {{- $rawSelectors = list (dict "matchLabels" (dict $securityLabelKey "true")) -}}
{{- end }}
{{- $targetSelectors := list -}}
{{- range $rawSelectors }}
  {{- $group := default "gateway.networking.k8s.io" .group -}}
  {{- $kind := default "HTTPRoute" .kind -}}
  {{- $matchLabels := default (dict) .matchLabels -}}
  {{- $targetSelectors = append $targetSelectors (dict "group" $group "kind" $kind "matchLabels" $matchLabels) -}}
{{- end }}
{{- $defaultAction := default "Deny" $policy.defaultAction -}}
---
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: SecurityPolicy
metadata:
  name: {{ $policyName }}
  namespace: {{ $policyNamespace | quote }}
  annotations:
    oidc.autoregistrar.parcellab.dev/sync-enabled: 'true'
spec:
  {{- if $targetRef }}
  targetRef:
    {{- toYaml $targetRef | nindent 4 }}
  {{- else if $targetRefs }}
  targetRefs:
    {{- toYaml $targetRefs | nindent 4 }}
  {{- else }}
  targetSelectors:
    {{- toYaml $targetSelectors | nindent 4 }}
  {{- end }}
  oidc:
    provider:
      issuer: {{ $issuer | quote }}
    clientID: {{ $clientID | quote }}
    clientSecret:
      name: {{ $clientSecretName | quote }}
    redirectURL: {{ $redirectURL | quote }}
    logoutPath: {{ $logoutPath | quote }}
    {{- with $scopes }}
    scopes:
      {{ toYaml . | nindent 6 }}
    {{- end }}
    cookieDomain: {{ $cookieDomain | quote }}
    forwardAccessToken: true
    passThroughAuthHeader: true
  jwt:
    optional: false
    providers:
      - name: {{ $jwtProviderName | quote }}
        issuer: {{ $issuer | quote }}
        remoteJWKS:
          cacheDuration: 300s
          uri: {{ $jwksURI | quote }}
        {{- with $claimToHeaders }}
        claimToHeaders:
          {{ toYaml . | nindent 8 }}
        {{- end }}

  authorization:
    defaultAction: {{ $defaultAction }}
    {{- with $policy.authorizationRules }}
    rules:
      {{ toYaml . | nindent 6 }}
    {{- end }}
{{ end }}
{{- end -}}
{{- end -}}
{{- end -}}
