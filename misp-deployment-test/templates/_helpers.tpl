{{/*
Expand the name of the chart.
*/}}
{{- define "misp-test.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "misp-test.fullname" -}}
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
{{- define "misp-test.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "misp-test.labels" -}}
helm.sh/chart: {{ include "misp-test.chart" . }}
{{ include "misp-test.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "misp-test.selectorLabels" -}}
app.kubernetes.io/name: {{ include "misp-test.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "misp-test.serviceAccountName" -}}
{{- if .Values.misp.serviceAccount.create }}
{{- default (include "misp-test.fullname" .) .Values.misp.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.misp.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate MISP configuration environment variables
*/}}
{{- define "misp-test.mispEnvVars" -}}
- name: ADMIN_EMAIL
  value: {{ .Values.misp.config.admin.email | quote }}
- name: ADMIN_PASSWORD
  value: {{ .Values.misp.config.admin.password | quote }}
- name: ORGNAME
  value: {{ .Values.misp.config.admin.orgName | quote }}
- name: BASE_URL
  value: {{ .Values.misp.config.baseUrl | quote }}
- name: SALT_KEY
  value: {{ .Values.misp.config.security.saltKey | quote }}
- name: DISABLE_SSL_REDIRECT
  value: {{ .Values.misp.config.security.disableSSLRedirect | quote }}
- name: NUM_WORKERS_DEFAULT
  value: {{ .Values.misp.config.workers.default | quote }}
- name: NUM_WORKERS_PRIO
  value: {{ .Values.misp.config.workers.prio | quote }}
- name: NUM_WORKERS_EMAIL
  value: {{ .Values.misp.config.workers.email | quote }}
{{- if .Values.redis.enabled }}
- name: REDIS_FQDN
  value: {{ .Release.Name }}-redis-master
- name: REDIS_PORT
  value: "6379"
{{- if .Values.redis.auth.enabled }}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-redis
      key: redis-password
{{- end }}
{{- end }}
{{- if .Values.mariadb.enabled }}
- name: MYSQL_HOST
  value: {{ .Release.Name }}-mariadb
- name: MYSQL_DATABASE
  value: {{ .Values.mariadb.auth.database | quote }}
- name: MYSQL_USER
  value: {{ .Values.mariadb.auth.username | quote }}
- name: MYSQL_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-mariadb
      key: mariadb-password
{{- end }}
{{- end }}

{{/*
Get the MariaDB secret name
*/}}
{{- define "misp-test.mariadbSecretName" -}}
{{- if .Values.mariadb.auth.existingSecret -}}
    {{- printf "%s" .Values.mariadb.auth.existingSecret -}}
{{- else -}}
    {{- printf "%s-mariadb" (include "misp-test.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get the Redis secret name
*/}}
{{- define "misp-test.redisSecretName" -}}
{{- if .Values.redis.auth.existingSecret -}}
    {{- printf "%s" .Values.redis.auth.existingSecret -}}
{{- else -}}
    {{- printf "%s-redis" (include "misp-test.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if we should use an existing secret for MISP
*/}}
{{- define "misp-test.useExistingSecret" -}}
{{- if .Values.existingSecret -}}
    {{- true -}}
{{- else -}}
    {{- false -}}
{{- end -}}
{{- end -}}

{{/*
Get the MISP secret name.
*/}}
{{- define "misp-test.secretName" -}}
{{- if .Values.existingSecret }}
    {{- printf "%s" .Values.existingSecret -}}
{{- else -}}
    {{- printf "%s" (include "misp-test.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return MISP admin password
*/}}
{{- define "misp-test.adminPassword" -}}
{{- if .Values.misp.config.admin.password }}
    {{- .Values.misp.config.admin.password -}}
{{- else -}}
    {{- randAlphaNum 16 -}}
{{- end -}}
{{- end -}}

{{/*
Validate required values
*/}}
{{- define "misp-test.validateValues" -}}
{{- if not .Values.misp.config.admin.email }}
    {{- fail "MISP admin email is required" -}}
{{- end }}
{{- if not .Values.misp.config.baseUrl }}
    {{- fail "MISP base URL is required" -}}
{{- end }}
{{- end }}