{{- define "sgroups.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sgroups.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "sgroups.name" . -}}
{{- end -}}
{{- end -}}

{{- define "sgroups.namespace" -}}
{{- .Release.Namespace -}}
{{- end -}}

{{- define "sgroups.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sgroups.labels" -}}
helm.sh/chart: {{ include "sgroups.chart" . }}
app.kubernetes.io/name: {{ include "sgroups.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: sgroups
{{- end -}}

{{- define "sgroups.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sgroups.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "sgroups.backendName" -}}
{{- printf "%s-backend" (include "sgroups.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sgroups.apiserverName" -}}
{{- printf "%s-k8s-apiserver" (include "sgroups.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sgroups.postgresName" -}}
{{- printf "%s-postgres" (include "sgroups.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sgroups.backendConfigName" -}}
{{- printf "%s-backend-config" (include "sgroups.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sgroups.apiserverConfigName" -}}
{{- printf "%s-apiserver-config" (include "sgroups.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sgroups.postgresSecretName" -}}
{{- include "sgroups.postgresName" . -}}
{{- end -}}

{{- define "sgroups.apiserverServiceAccountName" -}}
{{- include "sgroups.apiserverName" . -}}
{{- end -}}

{{- define "sgroups.selfSignedIssuerName" -}}
{{- printf "%s-selfsigned" (include "sgroups.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sgroups.caCertName" -}}
{{- printf "%s-ca" (include "sgroups.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sgroups.caSecretName" -}}
{{- printf "%s-ca-key-pair" (include "sgroups.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sgroups.caIssuerName" -}}
{{- printf "%s-ca-issuer" (include "sgroups.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sgroups.apiserverCertName" -}}
{{- printf "%s-apiserver-cert" (include "sgroups.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sgroups.apiserverTlsSecretName" -}}
{{- printf "%s-apiserver-tls" (include "sgroups.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sgroups.backendImage" -}}
{{- printf "%s:%s" .Values.image.backend.repository .Values.image.backend.tag -}}
{{- end -}}

{{- define "sgroups.migrationImage" -}}
{{- printf "%s:%s" .Values.image.migration.repository .Values.image.migration.tag -}}
{{- end -}}

{{- define "sgroups.apiserverImage" -}}
{{- printf "%s:%s" .Values.image.apiserver.repository .Values.image.apiserver.tag -}}
{{- end -}}

{{- define "sgroups.postgresImage" -}}
{{- printf "%s:%s" .Values.image.postgres.repository .Values.image.postgres.tag -}}
{{- end -}}

{{- define "sgroups.migrationWaitImage" -}}
{{- printf "%s:%s" .Values.migration.waitForPostgres.image.repository .Values.migration.waitForPostgres.image.tag -}}
{{- end -}}

{{- define "sgroups.postgresHost" -}}
{{- printf "%s.%s.svc" (include "sgroups.postgresName" .) (include "sgroups.namespace" .) -}}
{{- end -}}

{{- define "sgroups.backendGrpcAddress" -}}
{{- printf "%s.%s.svc:%v" (include "sgroups.backendName" .) (include "sgroups.namespace" .) .Values.backend.service.port -}}
{{- end -}}

{{- define "sgroups.postgresBaseUrl" -}}
{{- $user := urlquery .Values.postgres.auth.username -}}
{{- $password := urlquery .Values.postgres.auth.password -}}
{{- $database := urlquery .Values.postgres.auth.database -}}
{{- printf "postgres://%s:%s@%s:%v/%s" $user $password (include "sgroups.postgresHost" .) .Values.postgres.service.port $database -}}
{{- end -}}

{{- define "sgroups.backendPostgresUrl" -}}
{{- printf "%s?sslmode=%s&pool_max_conns=%v" (include "sgroups.postgresBaseUrl" .) .Values.backend.config.storage.postgres.sslMode .Values.backend.config.storage.postgres.poolMaxConns -}}
{{- end -}}

{{- define "sgroups.migrationPostgresUrl" -}}
{{- printf "%s?sslmode=disable" (include "sgroups.postgresBaseUrl" .) -}}
{{- end -}}
