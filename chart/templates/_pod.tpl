{{- define "fluentd-kube-elastic.podSelectorLabels" -}}
{{ include "fluentd-kube-elastic.selectorLabels" . }}
{{- end }}

{{- define "fluentd-kube-elastic.podAnnotations" -}}
checksum/confd: {{ include (print $.Template.BasePath "/confd-cm.yaml") . | sha256sum }}
checksum/es: {{ include (print $.Template.BasePath "/elasticsearch-secret.yaml") . | sha256sum }}
{{- if .Values.conf.loki.enabled }}
checksum/loki: {{ include (print $.Template.BasePath "/loki-secret.yaml") . | sha256sum }}
{{- end }}
checksum/files: {{ include (print $.Template.BasePath "/files-cm.yaml") . | sha256sum }}
checksum/fluentd: {{ include (print $.Template.BasePath "/fluentd-cm.yaml") . | sha256sum }}
{{- end }}

{{- define "fluentd-kube-elastic.podSpec" -}}
{{- with .Values.image.pullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 8 }}
{{- end }}
serviceAccountName: {{ include "fluentd-kube-elastic.serviceAccountName" . }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 8 }}
{{- with .Values.terminationGracePeriodSeconds }}
terminationGracePeriodSeconds: {{ . }}
{{- end }}
containers:
  - name: fluentd
    securityContext:
      {{- toYaml .Values.securityContext | nindent 12 }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag  }}"
    imagePullPolicy: {{ .Values.image.pullPolicy | default "IfNotPresent" }}
    {{- with .Values.env }}
    env:
      {{- range $k,$v := . }}
      - name: {{$k}}
        value: {{ tpl $v $ | quote }}
      {{- end}}
    {{- end }}
    envFrom:
    {{- with .Values.envFrom }}
      {{- toYaml .Values.envFrom | nindent 6 }}
    {{- end }}
    {{- if .Values.conf.elasticsearch.auth.enabled }}
      - secretRef: 
          name: {{ (.Values.conf.elasticsearch.auth.passwordSecret) | default (include "fluentd-kube-elastic.elasticsearch-secret" .) }}
          optional: false
    {{- end }}
    {{- if .Values.conf.loki.enabled }}
    {{- if or .Values.conf.loki.username .Values.conf.loki.password }}
      - secretRef: 
          name: {{ (.Values.conf.loki.passwordSecret) | default (include "fluentd-kube-elastic.loki-secret" .) }}
          optional: false
    {{- end }}
    {{- end }}
    ports:
      - name: metrics
        containerPort: 24231
        protocol: TCP
      {{- range $port := .Values.service.ports }}
      - name: {{ $port.name }}
        containerPort: {{ $port.containerPort }}
        protocol: {{ $port.protocol }}
      {{- end }}
    {{- with .Values.lifecycle }}
    lifecycle:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.startupProbe }}
    startupProbe:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.livenessProbe }}
    livenessProbe:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.readinessProbe }}
    readinessProbe:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    volumeMounts:
      - name: fluentd-cm
        mountPath: "/fluentd/etc"
      - name: conf-cm
        mountPath: "/fluentd/etc/config.d"
      - name: files-cm
        mountPath: "/fluentd/etc/files"
      - name: varlog
        mountPath: /var/log
      - name: varlibdockercontainers
        mountPath: /var/lib/docker/containers
      {{- if .Values.conf.elasticsearch.auth.tlsSecret }}
      - name: certs
        mountPath: "/fluentd/etc/certs"
      {{- end }}
    resources:
      {{- toYaml .Values.resources | nindent 12 }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 8 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 8 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 8 }}
{{- end }}
volumes:
  - name: fluentd-cm
    configMap:
      name: {{ include "fluentd-kube-elastic.fluentd-cm" . }}
  - name: conf-cm
    configMap:
      name: {{ include "fluentd-kube-elastic.conf-cm" . }}
  - name: files-cm
    configMap:
      name: {{ include "fluentd-kube-elastic.files-cm" . }}
  {{- if .Values.conf.elasticsearch.auth.tlsSecret }}
  - name: certs
    secret:
      secretName: {{ .Values.conf.elasticsearch.auth.tlsSecret }}
      optional: false
  {{- end }}
  - name: varlog
    hostPath:
      path: /var/log
  - name: varlibdockercontainers
    hostPath:
      path: /var/lib/docker/containers
{{- end }}
