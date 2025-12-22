{{/* vim: set filetype=mustache: */}}
{{/*
  Common SecurityPolicy definition:
  {{ include "common.securitypolicy" (
    dict
      "Values" "the values scope"
      "Release" .Release
  ) }}
*/}}

{{- define "common.securitypolicy" -}}
{{- $securityPolicy := .Values.securityPolicy | default dict -}}
{{- if $securityPolicy.enabled }}
{{- $name := include "common.fullname" . }}
---
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: SecurityPolicy
metadata:
  name: {{ $securityPolicy.name | default (printf "%s-security" $name) }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with $securityPolicy.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  targetRef:
    group: {{ $securityPolicy.targetRef.group | default "gateway.networking.k8s.io" }}
    kind: {{ $securityPolicy.targetRef.kind | default "HTTPRoute" }}
    name: {{ $securityPolicy.targetRef.name | default $name }}
    {{- with $securityPolicy.targetRef.namespace }}
    namespace: {{ . }}
    {{- end }}
  {{- if $securityPolicy.oidc }}
  oidc:
    provider:
      issuer: {{ required "securityPolicy.oidc.provider.issuer is required" $securityPolicy.oidc.provider.issuer | quote }}
      {{- with $securityPolicy.oidc.provider.authorizationEndpoint }}
      authorizationEndpoint: {{ . | quote }}
      {{- end }}
      {{- with $securityPolicy.oidc.provider.tokenEndpoint }}
      tokenEndpoint: {{ . | quote }}
      {{- end }}
    clientID: {{ required "securityPolicy.oidc.clientID is required" $securityPolicy.oidc.clientID | quote }}
    clientSecret:
      {{- if $securityPolicy.oidc.clientSecret }}
      name: {{ $securityPolicy.oidc.clientSecret.name | quote }}
      {{- with $securityPolicy.oidc.clientSecret.namespace }}
      namespace: {{ . | quote }}
      {{- end }}
      {{- else }}
      name: "keycloak-oidc-secret"
      {{- end }}
    redirectURL: {{ required "securityPolicy.oidc.redirectURL is required" $securityPolicy.oidc.redirectURL | quote }}
    {{- with $securityPolicy.oidc.logoutPath }}
    logoutPath: {{ . | quote }}
    {{- end }}
    {{- if $securityPolicy.oidc.scopes }}
    scopes:
      {{- toYaml $securityPolicy.oidc.scopes | nindent 6 }}
    {{- else }}
    scopes:
      - openid
      - profile
      - email
    {{- end }}
    {{- with $securityPolicy.oidc.cookieDomain }}
    cookieDomain: {{ . | quote }}
    {{- end }}
    {{- with $securityPolicy.oidc.cookieNames }}
    cookieNames:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- if hasKey $securityPolicy.oidc "forwardAccessToken" }}
    forwardAccessToken: {{ $securityPolicy.oidc.forwardAccessToken }}
    {{- end }}
    {{- if hasKey $securityPolicy.oidc "passThroughAuthHeader" }}
    passThroughAuthHeader: {{ $securityPolicy.oidc.passThroughAuthHeader }}
    {{- end }}
    {{- with $securityPolicy.oidc.refreshToken }}
    refreshToken: {{ . }}
    {{- end }}
  {{- end }}
  {{- if $securityPolicy.jwt }}
  jwt:
    {{- if hasKey $securityPolicy.jwt "optional" }}
    optional: {{ $securityPolicy.jwt.optional }}
    {{- end }}
    providers:
      {{- range $securityPolicy.jwt.providers }}
      - name: {{ .name | quote }}
        issuer: {{ .issuer | quote }}
        {{- with .audiences }}
        audiences:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- if .remoteJWKS }}
        remoteJWKS:
          uri: {{ .remoteJWKS.uri | quote }}
          {{- with .remoteJWKS.cacheDuration }}
          cacheDuration: {{ . }}
          {{- end }}
        {{- end }}
        {{- if .claimToHeaders }}
        claimToHeaders:
          {{- range .claimToHeaders }}
          - header: {{ .header | quote }}
            claim: {{ .claim | quote }}
          {{- end }}
        {{- end }}
        {{- with .extractFrom }}
        extractFrom:
          {{- toYaml . | nindent 10 }}
        {{- end }}
      {{- end }}
  {{- end }}
  {{- if $securityPolicy.basicAuth }}
  basicAuth:
    users:
      name: {{ $securityPolicy.basicAuth.users.name | quote }}
      {{- with $securityPolicy.basicAuth.users.namespace }}
      namespace: {{ . | quote }}
      {{- end }}
  {{- end }}
  {{- if $securityPolicy.authorization }}
  authorization:
    defaultAction: {{ $securityPolicy.authorization.defaultAction | default "Deny" }}
    {{- if $securityPolicy.authorization.rules }}
    rules:
      {{- range $securityPolicy.authorization.rules }}
      - name: {{ .name | quote }}
        action: {{ .action | default "Allow" }}
        {{- if .principal }}
        principal:
          {{- if .principal.clientCIDRs }}
          clientCIDRs:
            {{- toYaml .principal.clientCIDRs | nindent 12 }}
          {{- end }}
          {{- if .principal.jwt }}
          jwt:
            provider: {{ .principal.jwt.provider | quote }}
            {{- if .principal.jwt.scopes }}
            scopes:
              {{- toYaml .principal.jwt.scopes | nindent 14 }}
            {{- end }}
            {{- if .principal.jwt.claims }}
            claims:
              {{- range .principal.jwt.claims }}
              - name: {{ .name | quote }}
                {{- with .valueType }}
                valueType: {{ . }}
                {{- end }}
                {{- if .values }}
                values:
                  {{- toYaml .values | nindent 18 }}
                {{- end }}
              {{- end }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if $securityPolicy.cors }}
  cors:
    allowOrigins:
      {{- toYaml $securityPolicy.cors.allowOrigins | nindent 6 }}
    {{- with $securityPolicy.cors.allowMethods }}
    allowMethods:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with $securityPolicy.cors.allowHeaders }}
    allowHeaders:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with $securityPolicy.cors.exposeHeaders }}
    exposeHeaders:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- if hasKey $securityPolicy.cors "allowCredentials" }}
    allowCredentials: {{ $securityPolicy.cors.allowCredentials }}
    {{- end }}
    {{- with $securityPolicy.cors.maxAge }}
    maxAge: {{ . }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}
