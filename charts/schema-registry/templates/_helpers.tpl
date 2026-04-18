{{/* vim: set filetype=mustache: */}}

{{/*
Nazwa chartu (skrócona do 63 znaków).
*/}}
{{- define "schema-registry.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Pełna nazwa (release + chart lub fullnameOverride).
*/}}
{{- define "schema-registry.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Nazwa i wersja chartu jako label.
*/}}
{{- define "schema-registry.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Wspólne labele dla wszystkich zasobów.
*/}}
{{- define "schema-registry.labels" -}}
helm.sh/chart: {{ include "schema-registry.chart" . }}
{{ include "schema-registry.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Labele selektora (używane też w Service selector).
*/}}
{{- define "schema-registry.selectorLabels" -}}
app.kubernetes.io/name: {{ include "schema-registry.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Adresy brokerów Kafka — z values lub z in-cluster headless service.
*/}}
{{- define "schema-registry.kafka.bootstrapServers" -}}
{{- if .Values.kafka.bootstrapServers -}}
{{- .Values.kafka.bootstrapServers -}}
{{- else -}}
{{- printf "PLAINTEXT://%s-kafka-headless:9092" .Release.Name -}}
{{- end -}}
{{- end -}}

{{/*
GroupId dla Schema Registry.
*/}}
{{- define "schema-registry.groupId" -}}
{{- if .Values.overrideGroupId -}}
{{- .Values.overrideGroupId -}}
{{- else -}}
{{- .Release.Name -}}
{{- end -}}
{{- end -}}

{{/*
Nazwa obrazu Docker z opcjonalnym tagiem (fallback do appVersion).
*/}}
{{- define "schema-registry.image" -}}
{{- $tag := .Values.imageTag | default .Chart.AppVersion -}}
{{- printf "%s:%s" .Values.image $tag -}}
{{- end -}}

{{/*
Nazwa ServiceAccount.
*/}}
{{- define "schema-registry.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "schema-registry.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
