{{/* Labels padrão de todos os recursos. */}}
{{- define "lgtm.labels" -}}
app.kubernetes.io/part-of: plataforma-observabilidade
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/* Segurança padrão dos contêineres: não-root, sem escalar privilégio, sem capabilities. */}}
{{- define "lgtm.seguranca" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities:
  drop: ["ALL"]
{{- end }}

{{/*
StatefulSet monolítico genérico (um binário, um volume).
Parâmetros: nome, imagem, args, portas (lista de {nome, porta}), montagemDados, recursos, root, checksum.
*/}}
{{- define "lgtm.monolito" -}}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ .nome }}
  labels:
    {{- include "lgtm.labels" .root | nindent 4 }}
    app.kubernetes.io/name: {{ .nome }}
spec:
  serviceName: {{ .nome }}
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ .nome }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ .nome }}
      annotations:
        checksum/config: {{ .checksum }} # muda a config → reinicia o pod
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        fsGroup: 10001
        seccompProfile: { type: RuntimeDefault }
      containers:
        - name: {{ .nome }}
          image: {{ .imagem }}
          args: {{ toJson .args }}
          ports:
            {{- range .portas }}
            - name: {{ .nome }}
              containerPort: {{ .porta }}
            {{- end }}
          readinessProbe:
            httpGet: { path: /ready, port: {{ (index .portas 0).nome }} }
            initialDelaySeconds: 10
            periodSeconds: 10
          resources:
            {{- toYaml .recursos | nindent 12 }}
          securityContext:
            {{- include "lgtm.seguranca" . | nindent 12 }}
          volumeMounts:
            - { name: config, mountPath: /etc/{{ .nome }} }
            - { name: dados, mountPath: {{ .montagemDados }} }
            - { name: tmp, mountPath: /tmp }
      volumes:
        - name: config
          configMap: { name: {{ .nome }}-config }
        - name: tmp
          emptyDir: {}
  volumeClaimTemplates:
    - metadata:
        name: dados
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: {{ .root.Values.armazenamento }}
{{- end }}
