#
# COPYRIGHT Ericsson 2021
#
#
#
# The copyright to the computer program(s) herein is the property of
#
# Ericsson Inc. The programs may be used and/or copied only with written
#
# permission from Ericsson Inc. or in accordance with the terms and
#
# conditions stipulated in the agreement/contract under which the
#
# program(s) have been supplied.
#
# Chart name
{{- define "eric-edca-integration-helm.chart" -}}
 {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-edca-integration-helm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart version as used by the chart label.
*/}}
{{- define "eric-edca-integration-helm.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create Ericsson product app.kubernetes.io info
*/}}
{{- define "eric-edca-integration-helm.kubernetes-io-info" -}}
app.kubernetes.io/name: {{ .Chart.Name | quote }}
app.kubernetes.io/version: {{ .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

{{/*
Create annotation for the service
*/}}
{{- define "eric-edca-integration-helm.helm-annotations" -}}
ericsson.com/product-name: "EDCA"
ericsson.com/product-number: "CXD 174 1531"
ericsson.com/product-revision: "1.0.0"
{{- end -}}

{{/*
Create the name for the tls secret.
*/}}
{{- define "eric-edca-integration-helm.ingressTLSSecret" -}}
{{- if .Values.ingress.tls.existingSecret -}}
  {{- .Values.ingress.tls.existingSecret -}}
{{- else -}}
  {{- template "eric-edca-integration-helm.name" . -}}-ingress-external-tls-secret
{{- end -}}
{{- end -}}

{{/*
Object Storage MN is enabled
*/}}
{{- define "eric-edca-integration-helm.osmn" -}}
  {{- if and (index .Values "eric-data-object-storage-mn") -}}
    {{- if eq (index .Values "eric-data-object-storage-mn" "enabled" | quote) "\"false\"" -}}
      false
    {{- else -}}
      true
    {{- end -}}
  {{- else -}}
      false
  {{- end -}}
{{- end -}}

{{/*
Create kafa-client image registry url
*/}}
{{- define "eric-edca-integration-helm.kafka-client.registryUrl" -}}
    {{- $registryUrl := "armdocker.rnd.ericsson.se" -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if index .Values "imageCredentials" "kafka-client" "registry" -}}
        {{- if index .Values "imageCredentials" "kafka-client" "registry" "url" -}}
        {{- $registryUrl = (index .Values "imageCredentials" "kafka-client" "registry" "url") -}}
        {{- end -}}
    {{- end -}}
    {{- print $registryUrl -}}
{{- end -}}

{{/*
Create image pull secret, service level parameter takes precedence
*/}}
{{- define "eric-edca-integration-helm.pullSecret" -}}
{{- $pullSecret := "" -}}
{{- if .Values.global -}}
    {{- if .Values.global.pullSecret -}}
        {{- $pullSecret = .Values.global.pullSecret -}}
    {{- end -}}
{{- end -}}
{{- if .Values.imageCredentials -}}
    {{- if .Values.imageCredentials.pullSecret -}}
        {{- $pullSecret = .Values.imageCredentials.pullSecret -}}
    {{- end -}}
{{- end -}}
{{- print $pullSecret -}}
{{- end -}}

{{/*
Create ingress hostname
*/}}
{{- define "eric-edca-integration-helm.ingressHostname" -}}
{{- $ingressHostname := "" -}}
{{- if .Values.global -}}
    {{- if .Values.global.hosts -}}
        {{- if .Values.global.hosts.pf -}}
            {{- $ingressHostname = .Values.global.hosts.pf -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- if .Values.ingress -}}
    {{- if .Values.ingress.hostname -}}
        {{- $ingressHostname = .Values.ingress.hostname -}}
    {{- end -}}
{{- end -}}
{{- print $ingressHostname -}}
{{- end -}}

{{/*
Create object store accesskey
*/}}
{{- define "eric-edca-integration-helm.objectstoreAccesskey" -}}
  {{- $secret := (lookup "v1" "Secret" ".Release.Namespace" "eric-edca-object-store-secret") -}}
  {{- if $secret }}
    {{ $secret.data.accesskey }}
  {{- else -}}
    {{- (randAlphaNum 20) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Create object store secretkey
*/}}
{{- define "eric-edca-integration-helm.objectstoreSecretkey" -}}
  {{- $secret := (lookup "v1" "Secret" ".Release.Namespace" "eric-edca-object-store-secret") -}}
  {{- if $secret }}
    {{ $secret.data.secretkey }}
  {{- else -}}
    {{- (randAlphaNum 20) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Connection to dataCoordinator kafka root
*/}}
{{- define "eric-edca-integration-helm.kafkaClient.connect" -}}
{{- printf "%s:%s" .Values.kafkaClient.dataCoordinator.clientServiceName  .Values.kafkaClient.dataCoordinator.clientPort -}}
{{- end -}}
