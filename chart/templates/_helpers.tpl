{{/*
Expand the name of the chart.
*/}}
{{- define "fluentd-kube-elastic.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "fluentd-kube-elastic.fullname" -}}
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
{{- define "fluentd-kube-elastic.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "fluentd-kube-elastic.labels" -}}
helm.sh/chart: {{ include "fluentd-kube-elastic.chart" . }}
{{ include "fluentd-kube-elastic.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "fluentd-kube-elastic.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fluentd-kube-elastic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "fluentd-kube-elastic.serviceAccountName" -}}
{{- default (include "fluentd-kube-elastic.fullname" .) .Values.rbac.serviceAccount.name }}
{{- end }}

{{- define "fluentd-kube-elastic.fluentd-cm" -}}
{{- include "fluentd-kube-elastic.fullname" . }}-conf
{{- end }}

{{- define "fluentd-kube-elastic.conf-cm" -}}
{{- include "fluentd-kube-elastic.fullname" . }}-conf-files
{{- end }}

{{- define "fluentd-kube-elastic.files-cm" -}}
{{- include "fluentd-kube-elastic.fullname" . }}-files
{{- end }}

{{- define "fluentd-kube-elastic.elasticsearch-secret" -}}
{{- include "fluentd-kube-elastic.fullname" . }}-elasticsearch
{{- end }}

{{- define "fluentd-kube-elastic.loki-secret" -}}
{{- include "fluentd-kube-elastic.fullname" . }}-loki
{{- end }}

{{- define "toExcludePaths" -}}
{{- range $index, $value := . -}}
{{- if $index}}, {{- end }}"/var/log/containers/{{$value}}"
{{- end -}}
{{- end -}}
