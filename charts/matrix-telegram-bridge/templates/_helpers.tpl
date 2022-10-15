{{/*
Expand the name of the chart.
*/}}
{{- define "matrix-telegram-bridge.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "matrix-telegram-bridge.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "matrix-telegram-bridge.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "matrix-telegram-bridge.labels" -}}
helm.sh/chart: {{ include "matrix-telegram-bridge.chart" . }}
{{ include "matrix-telegram-bridge.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "matrix-telegram-bridge.selectorLabels" -}}
app.kubernetes.io/name: {{ include "matrix-telegram-bridge.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "matrix-telegram-bridge.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "matrix-telegram-bridge.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the secret containing environment variables
*/}}
{{- define "matrix-telegram-bridge.secretName" -}}
{{- if empty .Values.manualSecretName }}
{{- (include "matrix-telegram-bridge.fullname" .) }}-secret
{{- else }}
{{- .Values.manualSecretName }}
{{- end }}
{{- end }}

{{- define "matrix-telegram-bridge.deployment.env" -}}
- name: PG_USERNAME
  value: {{ .Values.postgresql.username }}
- name: PG_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.postgresql.password.secretName }}
      key: {{ .Values.postgresql.password.secretKey }}
- name: MAUTRIX_TELEGRAM_APPSERVICE_DATABASE
  value: postgres://$(PG_USERNAME):$(PG_PASSWORD)@$(PG_HOST)/$(PG_DATABASE)
{{- end }}

{{- define "matrix-telegram-bridge.deployment.volumeMounts" -}}
- mountPath: /data
  name: data
{{- end -}}

{{- define "matrix-telegram-bridge.deployment.volumeMountsInit" -}}
- name: init-scripts
  mountPath: "/opt/init-scripts"
  readOnly: true
- name: config-overrides
  mountPath: "/opt/config-overrides"
  readOnly: true
{{ include "matrix-telegram-bridge.deployment.volumeMounts" . }}
{{- end -}}

{{- define "matrix-telegram-bridge.matrix.homeserver-address" -}}
{{- if .Values.matrix.homeserver.address }}
{{- .Values.matrix.homeserver.address }}
{{- else -}}
https://{{- .Values.matrix.homeserver.domain }}
{{- end }}
{{- end -}}

{{- define "matrix-telegram-bridge.matrix.appservice-address" -}}
{{- if .Values.matrix.appservice.inCluster -}}
http://{{- include "matrix-telegram-bridge.fullname" . }}.{{- .Release.Namespace -}}.svc.cluster.local:{{- .Values.service.port -}}
{{- else -}}
https://{{- .Values.matrix.appservice.address }}
{{- end }}
{{- end -}}

